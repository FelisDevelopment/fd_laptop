local framework = require 'bridge.framework'

MySQL.ready(function()
    MySQL.update([[
        CREATE TABLE IF NOT EXISTS `fd_laptop_calendar_events` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(255) NULL,
            `title` VARCHAR(255) NOT NULL,
            `description` TEXT NULL,
            `date` DATE NOT NULL,
            `time` VARCHAR(5) NULL,
            `image_url` TEXT NULL,
            `is_shared` TINYINT(1) NOT NULL DEFAULT 0,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_date` (`date`),
            INDEX `idx_identifier` (`identifier`)
        )
    ]], {})

    MySQL.update([[
        CREATE TABLE IF NOT EXISTS `fd_laptop_calendar_reminders` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `event_id` INT NOT NULL,
            `identifier` VARCHAR(255) NOT NULL,
            UNIQUE KEY `unique_reminder` (`event_id`, `identifier`)
        )
    ]], {})
end)

---@param source number
---@param data { month: number, year: number }
---@return table
lib.callback.register('fd_laptop:server:calendarGetEvents', function(source, data)
    local identifier = framework.getIdentifier(source)
    if not identifier then
        return { error = 'Unable to identify player' }
    end

    local month = data and data.month
    local year = data and data.year

    if not month or not year then
        return { error = 'Month and year are required' }
    end

    local startDate = string.format('%04d-%02d-01', year, month)
    local endDate = string.format('%04d-%02d-31', year, month)

    local rows = MySQL.query.await([[
        SELECT e.`id`, e.`title`, e.`description`, e.`date`, e.`time`, e.`image_url`, e.`is_shared`, e.`identifier`,
               CASE WHEN r.`id` IS NOT NULL THEN 1 ELSE 0 END AS `has_reminder`
        FROM `fd_laptop_calendar_events` e
        LEFT JOIN `fd_laptop_calendar_reminders` r ON r.`event_id` = e.`id` AND r.`identifier` = ?
        WHERE e.`date` >= ? AND e.`date` <= ?
          AND (e.`is_shared` = 1 OR e.`identifier` = ?)
        ORDER BY e.`date` ASC, e.`time` ASC
    ]], { identifier, startDate, endDate, identifier })

    local events = {}
    for _, row in ipairs(rows or {}) do
        events[#events + 1] = {
            id = row.id,
            title = row.title,
            description = row.description,
            date = row.date,
            time = row.time,
            imageUrl = row.image_url,
            isShared = row.is_shared,
            isOwner = row.identifier == identifier,
            hasReminder = row.has_reminder
        }
    end

    return events
end)

---@param source number
---@param data { title: string, description?: string, date: string, time?: string, imageUrl?: string }
---@return table
lib.callback.register('fd_laptop:server:calendarCreateEvent', function(source, data)
    local identifier = framework.getIdentifier(source)
    if not identifier then
        return { error = 'Unable to identify player' }
    end

    local title = data and data.title
    local date = data and data.date

    if not title or title == '' then
        return { error = 'Title is required' }
    end

    if not date or date == '' then
        return { error = 'Date is required' }
    end

    local id = MySQL.insert.await([[
        INSERT INTO `fd_laptop_calendar_events` (`identifier`, `title`, `description`, `date`, `time`, `image_url`, `is_shared`)
        VALUES (?, ?, ?, ?, ?, ?, 0)
    ]], {
        identifier,
        title,
        data.description or nil,
        date,
        data.time or nil,
        data.imageUrl or nil
    })

    return {
        id = id,
        title = title,
        description = data.description,
        date = date,
        time = data.time,
        imageUrl = data.imageUrl,
        isShared = false,
        isOwner = true,
        hasReminder = false
    }
end)

---@param source number
---@param data { id: number }
---@return table
lib.callback.register('fd_laptop:server:calendarDeleteEvent', function(source, data)
    local identifier = framework.getIdentifier(source)
    if not identifier then
        return { error = 'Unable to identify player' }
    end

    local id = data and data.id
    if not id then
        return { error = 'Event id is required' }
    end

    local affected = MySQL.update.await([[
        DELETE FROM `fd_laptop_calendar_events`
        WHERE `id` = ? AND `identifier` = ? AND `is_shared` = 0
    ]], { id, identifier })

    if affected == 0 then
        return { error = 'Event not found or cannot be deleted' }
    end

    -- Clean up any reminders for this event
    MySQL.update([[
        DELETE FROM `fd_laptop_calendar_reminders` WHERE `event_id` = ?
    ]], { id })

    return { success = true }
end)

---@param source number
---@param data { eventId: number }
---@return table
lib.callback.register('fd_laptop:server:calendarToggleReminder', function(source, data)
    local identifier = framework.getIdentifier(source)
    if not identifier then
        return { error = 'Unable to identify player' }
    end

    local eventId = data and data.eventId
    if not eventId then
        return { error = 'Event id is required' }
    end

    -- Check if reminder exists
    local existing = MySQL.scalar.await([[
        SELECT `id` FROM `fd_laptop_calendar_reminders`
        WHERE `event_id` = ? AND `identifier` = ?
    ]], { eventId, identifier })

    if existing then
        MySQL.update.await([[
            DELETE FROM `fd_laptop_calendar_reminders`
            WHERE `event_id` = ? AND `identifier` = ?
        ]], { eventId, identifier })
        return { hasReminder = false }
    else
        MySQL.insert.await([[
            INSERT INTO `fd_laptop_calendar_reminders` (`event_id`, `identifier`)
            VALUES (?, ?)
        ]], { eventId, identifier })
        return { hasReminder = true }
    end
end)

--- Get today's events that have reminders for this player
---@param source number
---@return table
lib.callback.register('fd_laptop:server:calendarCheckReminders', function(source)
    local identifier = framework.getIdentifier(source)
    if not identifier then
        return {}
    end

    local today = os.date('%Y-%m-%d')

    local rows = MySQL.query.await([[
        SELECT e.`title`, e.`time`
        FROM `fd_laptop_calendar_events` e
        INNER JOIN `fd_laptop_calendar_reminders` r ON r.`event_id` = e.`id` AND r.`identifier` = ?
        WHERE e.`date` = ?
          AND (e.`is_shared` = 1 OR e.`identifier` = ?)
        ORDER BY e.`time` ASC
    ]], { identifier, today, identifier })

    return rows or {}
end)

--- Server export: create a shared/server-wide calendar event
---@param data { title: string, description?: string, date: string, time?: string, imageUrl?: string }
---@return number|nil id
exports('createCalendarEvent', function(data)
    if not data or not data.title or not data.date then
        return nil
    end

    local id = MySQL.insert.await([[
        INSERT INTO `fd_laptop_calendar_events` (`identifier`, `title`, `description`, `date`, `time`, `image_url`, `is_shared`)
        VALUES (NULL, ?, ?, ?, ?, ?, 1)
    ]], {
        data.title,
        data.description or nil,
        data.date,
        data.time or nil,
        data.imageUrl or nil
    })

    return id
end)

--- Server export: delete a shared/server-wide calendar event
---@param id number
---@return boolean
exports('deleteCalendarEvent', function(id)
    if not id then return false end

    -- Clean up reminders
    MySQL.update([[
        DELETE FROM `fd_laptop_calendar_reminders` WHERE `event_id` = ?
    ]], { id })

    local affected = MySQL.update.await([[
        DELETE FROM `fd_laptop_calendar_events`
        WHERE `id` = ? AND `is_shared` = 1
    ]], { id })

    return affected > 0
end)

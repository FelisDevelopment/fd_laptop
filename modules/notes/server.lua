local framework = require 'bridge.framework'

MySQL.ready(function()
    MySQL.update([[
        CREATE TABLE IF NOT EXISTS `fd_laptop_notes` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(255) NOT NULL,
            `title` VARCHAR(255) NOT NULL DEFAULT '',
            `content` LONGTEXT NULL,
            `color` VARCHAR(20) NOT NULL DEFAULT '#FFE56D',
            `pinned` TINYINT(1) NOT NULL DEFAULT 0,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX `idx_identifier` (`identifier`)
        )
    ]], {})
end)

---@param source number
---@return table
lib.callback.register('fd_laptop:server:notesGetAll', function(source)
    local identifier = framework.getIdentifier(source)
    if not identifier then
        return { error = 'Unable to identify player' }
    end

    local rows = MySQL.query.await([[
        SELECT `id`, `title`, `content`, `color`, `pinned`, `created_at`, `updated_at`
        FROM `fd_laptop_notes`
        WHERE `identifier` = ?
        ORDER BY `pinned` DESC, `updated_at` DESC
    ]], { identifier })

    local notes = {}
    for _, row in ipairs(rows or {}) do
        notes[#notes + 1] = {
            id = row.id,
            title = row.title,
            content = row.content,
            color = row.color,
            pinned = row.pinned,
            created_at = row.created_at,
            updated_at = row.updated_at
        }
    end

    return notes
end)

---@param source number
---@param data { title: string, content?: string, color?: string }
---@return table
lib.callback.register('fd_laptop:server:notesCreate', function(source, data)
    local identifier = framework.getIdentifier(source)
    if not identifier then
        return { error = 'Unable to identify player' }
    end

    local title = data and data.title or ''
    local content = data and data.content or ''
    local color = data and data.color or '#FFE56D'

    local id = MySQL.insert.await([[
        INSERT INTO `fd_laptop_notes` (`identifier`, `title`, `content`, `color`, `pinned`)
        VALUES (?, ?, ?, ?, 0)
    ]], { identifier, title, content, color })

    local row = MySQL.single.await([[
        SELECT `id`, `title`, `content`, `color`, `pinned`, `created_at`, `updated_at`
        FROM `fd_laptop_notes`
        WHERE `id` = ?
    ]], { id })

    if not row then
        return { error = 'Failed to create note' }
    end

    return {
        id = row.id,
        title = row.title,
        content = row.content,
        color = row.color,
        pinned = row.pinned,
        created_at = row.created_at,
        updated_at = row.updated_at
    }
end)

---@param source number
---@param data { id: number, title?: string, content?: string, color?: string }
---@return table
lib.callback.register('fd_laptop:server:notesUpdate', function(source, data)
    local identifier = framework.getIdentifier(source)
    if not identifier then
        return { error = 'Unable to identify player' }
    end

    local id = data and data.id
    if not id then
        return { error = 'Note id is required' }
    end

    local existing = MySQL.single.await([[
        SELECT `id` FROM `fd_laptop_notes`
        WHERE `id` = ? AND `identifier` = ?
    ]], { id, identifier })

    if not existing then
        return { error = 'Note not found' }
    end

    local fields = {}
    local values = {}

    if data.title ~= nil then
        fields[#fields + 1] = '`title` = ?'
        values[#values + 1] = data.title
    end

    if data.content ~= nil then
        fields[#fields + 1] = '`content` = ?'
        values[#values + 1] = data.content
    end

    if data.color ~= nil then
        fields[#fields + 1] = '`color` = ?'
        values[#values + 1] = data.color
    end

    if #fields == 0 then
        return { error = 'No fields to update' }
    end

    values[#values + 1] = id
    values[#values + 1] = identifier

    MySQL.update.await(
        'UPDATE `fd_laptop_notes` SET ' .. table.concat(fields, ', ') .. ' WHERE `id` = ? AND `identifier` = ?',
        values
    )

    local row = MySQL.single.await([[
        SELECT `id`, `title`, `content`, `color`, `pinned`, `created_at`, `updated_at`
        FROM `fd_laptop_notes`
        WHERE `id` = ? AND `identifier` = ?
    ]], { id, identifier })

    if not row then
        return { error = 'Failed to retrieve updated note' }
    end

    return {
        id = row.id,
        title = row.title,
        content = row.content,
        color = row.color,
        pinned = row.pinned,
        created_at = row.created_at,
        updated_at = row.updated_at
    }
end)

---@param source number
---@param data { id: number, pinned: number }
---@return table
lib.callback.register('fd_laptop:server:notesTogglePin', function(source, data)
    local identifier = framework.getIdentifier(source)
    if not identifier then
        return { error = 'Unable to identify player' }
    end

    local id = data and data.id
    if not id then
        return { error = 'Note id is required' }
    end

    local pinned = data.pinned == 1 and 1 or 0

    local affected = MySQL.update.await([[
        UPDATE `fd_laptop_notes` SET `pinned` = ?
        WHERE `id` = ? AND `identifier` = ?
    ]], { pinned, id, identifier })

    if affected == 0 then
        return { error = 'Note not found' }
    end

    return { success = true, pinned = pinned == 1 }
end)

---@param source number
---@param data { id: number }
---@return table
lib.callback.register('fd_laptop:server:notesDelete', function(source, data)
    local identifier = framework.getIdentifier(source)
    if not identifier then
        return { error = 'Unable to identify player' }
    end

    local id = data and data.id
    if not id then
        return { error = 'Note id is required' }
    end

    local affected = MySQL.update.await([[
        DELETE FROM `fd_laptop_notes`
        WHERE `id` = ? AND `identifier` = ?
    ]], { id, identifier })

    if affected == 0 then
        return { error = 'Note not found or cannot be deleted' }
    end

    return { success = true }
end)

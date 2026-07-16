local framework = require 'bridge.framework'
local emailConfig = require 'config.server.email'

local notifyRecipient

MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `fd_laptop_email_accounts` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(255) NOT NULL,
            `address` VARCHAR(255) NOT NULL UNIQUE,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_identifier` (`identifier`),
            INDEX `idx_address` (`address`)
        )
    ]], {})

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `fd_laptop_emails` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `owner_address` VARCHAR(255) NOT NULL,
            `from_address` VARCHAR(255) NOT NULL,
            `to_address` VARCHAR(255) NOT NULL,
            `subject` VARCHAR(500) NOT NULL DEFAULT '',
            `body` LONGTEXT NULL,
            `folder` ENUM('inbox', 'sent', 'trash') NOT NULL DEFAULT 'inbox',
            `is_read` TINYINT(1) NOT NULL DEFAULT 0,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_owner_folder` (`owner_address`, `folder`),
            INDEX `idx_created` (`created_at`)
        )
    ]], {})
end)

---@type table<string, number>
local rateLimits = {}

---@param source number
---@return table
lib.callback.register('fd_laptop:server:emailGetConfig', function(source)
    return {
        domains = emailConfig.domains,
        maxAccounts = emailConfig.maxAccounts,
    }
end)

---@param source number
---@return table
lib.callback.register('fd_laptop:server:emailGetAccounts', function(source)
    local identifier = framework.getIdentifier(source)
    if not identifier then
        return { error = 'Unable to identify player' }
    end

    local rows = MySQL.query.await([[
        SELECT `id`, `address`, `created_at`
        FROM `fd_laptop_email_accounts`
        WHERE `identifier` = ?
        ORDER BY `created_at` ASC
    ]], { identifier })

    local accounts = {}
    for _, row in ipairs(rows or {}) do
        accounts[#accounts + 1] = {
            id = row.id,
            address = row.address,
            created_at = row.created_at,
        }
    end

    return accounts
end)

---@param source number
---@param data { username: string, domain: string }
---@return table
lib.callback.register('fd_laptop:server:emailCreate', function(source, data)
    local identifier = framework.getIdentifier(source)
    if not identifier then
        return { error = 'Unable to identify player' }
    end

    local username = data and data.username
    local domain = data and data.domain

    if not username or type(username) ~= 'string' then
        return { error = 'invalid_username' }
    end

    if not domain or type(domain) ~= 'string' then
        return { error = 'invalid_domain' }
    end

    username = username:lower():gsub('%s+', '')

    if #username < emailConfig.usernameMinLength or #username > emailConfig.usernameMaxLength then
        return { error = 'invalid_username' }
    end

    if not username:match('^[a-z0-9._%-]+$') then
        return { error = 'invalid_username' }
    end

    local validDomain = false
    for _, d in ipairs(emailConfig.domains) do
        if d == domain then
            validDomain = true
            break
        end
    end

    if not validDomain then
        return { error = 'invalid_domain' }
    end

    local count = MySQL.scalar.await([[
        SELECT COUNT(*) FROM `fd_laptop_email_accounts`
        WHERE `identifier` = ?
    ]], { identifier })

    if (count or 0) >= emailConfig.maxAccounts then
        return { error = 'max_accounts' }
    end

    local address = username .. '@' .. domain

    local existing = MySQL.scalar.await([[
        SELECT COUNT(*) FROM `fd_laptop_email_accounts`
        WHERE `address` = ?
    ]], { address })

    if (existing or 0) > 0 then
        return { error = 'address_taken' }
    end

    local id = MySQL.insert.await([[
        INSERT INTO `fd_laptop_email_accounts` (`identifier`, `address`)
        VALUES (?, ?)
    ]], { identifier, address })

    if not id then
        return { error = 'Failed to create account' }
    end

    return {
        id = id,
        address = address,
    }
end)

---@param source number
---@param data { address: string, folder: string, page: number, search?: string, readFilter?: string }
---@return table
lib.callback.register('fd_laptop:server:emailGetEmails', function(source, data)
    local identifier = framework.getIdentifier(source)
    if not identifier then
        return { error = 'Unable to identify player' }
    end

    local address = data and data.address
    local folder = data and data.folder or 'inbox'
    local page = data and data.page or 1
    local search = data and data.search or ''
    local readFilter = data and data.readFilter or 'all'

    if not address then
        return { error = 'Address is required' }
    end

    local owns = MySQL.scalar.await([[
        SELECT COUNT(*) FROM `fd_laptop_email_accounts`
        WHERE `address` = ? AND `identifier` = ?
    ]], { address, identifier })

    if (owns or 0) == 0 then
        return { error = 'Access denied' }
    end

    local perPage = 25
    local offset = (page - 1) * perPage

    local where = '`owner_address` = ? AND `folder` = ?'
    local params = { address, folder }

    if readFilter == 'unread' then
        where = where .. ' AND `is_read` = 0'
    elseif readFilter == 'read' then
        where = where .. ' AND `is_read` = 1'
    end

    if search ~= '' then
        local escaped = search:gsub('%%', '\\%%'):gsub('_', '\\_')
        local pattern = '%' .. escaped .. '%'
        where = where .. ' AND (`from_address` LIKE ? OR `to_address` LIKE ? OR `subject` LIKE ?)'
        params[#params + 1] = pattern
        params[#params + 1] = pattern
        params[#params + 1] = pattern
    end

    params[#params + 1] = perPage + 1
    params[#params + 1] = offset

    local rows = MySQL.query.await(
        'SELECT `id`, `owner_address`, `from_address`, `to_address`, `subject`, `body`, `folder`, `is_read`, `created_at`'
        .. ' FROM `fd_laptop_emails`'
        .. ' WHERE ' .. where
        .. ' ORDER BY `created_at` DESC'
        .. ' LIMIT ? OFFSET ?',
        params
    )

    local emails = {}
    local hasMore = false

    for i, row in ipairs(rows or {}) do
        if i > perPage then
            hasMore = true
            break
        end

        emails[#emails + 1] = {
            id = row.id,
            owner_address = row.owner_address,
            from_address = row.from_address,
            to_address = row.to_address,
            subject = row.subject,
            body = row.body,
            folder = row.folder,
            is_read = row.is_read,
            created_at = row.created_at,
        }
    end

    local totalUnread = MySQL.scalar.await([[
        SELECT COUNT(*) FROM `fd_laptop_emails`
        WHERE `owner_address` = ? AND `folder` = 'inbox' AND `is_read` = 0
    ]], { address })

    return {
        emails = emails,
        hasMore = hasMore,
        totalUnread = totalUnread or 0,
    }
end)

---@param source number
---@param data { fromAddress: string, toAddress: string, subject: string, body: string }
---@return table
lib.callback.register('fd_laptop:server:emailSend', function(source, data)
    local identifier = framework.getIdentifier(source)
    if not identifier then
        return { error = 'Unable to identify player' }
    end

    local fromAddress = data and data.fromAddress
    local toAddress = data and data.toAddress
    local subject = data and data.subject or ''
    local body = data and data.body or ''

    if not fromAddress or not toAddress then
        return { error = 'From and To addresses are required' }
    end

    local owns = MySQL.scalar.await([[
        SELECT COUNT(*) FROM `fd_laptop_email_accounts`
        WHERE `address` = ? AND `identifier` = ?
    ]], { fromAddress, identifier })

    if (owns or 0) == 0 then
        return { error = 'Access denied' }
    end

    local now = os.time()
    if rateLimits[identifier] and (now - rateLimits[identifier]) < emailConfig.rateLimitSeconds then
        return { error = 'rate_limited' }
    end

    rateLimits[identifier] = now

    local recipientExists = MySQL.scalar.await([[
        SELECT COUNT(*) FROM `fd_laptop_email_accounts`
        WHERE `address` = ?
    ]], { toAddress })

    if (recipientExists or 0) == 0 then
        return { error = 'recipient_not_found' }
    end

    MySQL.insert.await([[
        INSERT INTO `fd_laptop_emails` (`owner_address`, `from_address`, `to_address`, `subject`, `body`, `folder`, `is_read`)
        VALUES (?, ?, ?, ?, ?, 'sent', 1)
    ]], { fromAddress, fromAddress, toAddress, subject, body })

    MySQL.insert.await([[
        INSERT INTO `fd_laptop_emails` (`owner_address`, `from_address`, `to_address`, `subject`, `body`, `folder`, `is_read`)
        VALUES (?, ?, ?, ?, ?, 'inbox', 0)
    ]], { toAddress, fromAddress, toAddress, subject, body })

    notifyRecipient(toAddress, fromAddress, subject)

    return { success = true }
end)

---@param toAddress string
---@param fromAddress string
---@param subject string
function notifyRecipient(toAddress, fromAddress, subject)
    local recipientIdentifier = MySQL.scalar.await([[
        SELECT `identifier` FROM `fd_laptop_email_accounts`
        WHERE `address` = ?
    ]], { toAddress })

    if not recipientIdentifier then return end

    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local pid = tonumber(playerId)
        if pid then
            local pIdentifier = framework.getIdentifier(pid)
            if pIdentifier == recipientIdentifier then
                TriggerClientEvent('fd_laptop:client:newEmail', pid, {
                    address = toAddress,
                    from_address = fromAddress,
                    subject = subject,
                })
                break
            end
        end
    end
end

---@param fromAddress string
---@param toAddress string
---@param subject string
---@param body? string
---@return boolean success
---@return string? error
local function sendEmail(fromAddress, toAddress, subject, body)
    if type(fromAddress) ~= 'string' or fromAddress == '' then
        return false, 'fromAddress is required'
    end

    if type(toAddress) ~= 'string' or toAddress == '' then
        return false, 'toAddress is required'
    end

    if type(subject) ~= 'string' then
        return false, 'subject is required'
    end

    body = body or ''

    local recipientExists = MySQL.scalar.await([[
        SELECT COUNT(*) FROM `fd_laptop_email_accounts`
        WHERE `address` = ?
    ]], { toAddress })

    if (recipientExists or 0) == 0 then
        return false, 'Recipient does not exist'
    end

    MySQL.insert.await([[
        INSERT INTO `fd_laptop_emails` (`owner_address`, `from_address`, `to_address`, `subject`, `body`, `folder`, `is_read`)
        VALUES (?, ?, ?, ?, ?, 'inbox', 0)
    ]], { toAddress, fromAddress, toAddress, subject, body })

    notifyRecipient(toAddress, fromAddress, subject)

    return true
end
exports('sendEmail', sendEmail)

---@param source number
---@param data { id: number }
---@return table
lib.callback.register('fd_laptop:server:emailMarkRead', function(source, data)
    local identifier = framework.getIdentifier(source)
    if not identifier then
        return { error = 'Unable to identify player' }
    end

    local id = data and data.id
    if not id then
        return { error = 'Email id is required' }
    end

    local email = MySQL.single.await([[
        SELECT e.`id`, e.`owner_address`
        FROM `fd_laptop_emails` e
        INNER JOIN `fd_laptop_email_accounts` a ON a.`address` = e.`owner_address`
        WHERE e.`id` = ? AND a.`identifier` = ?
    ]], { id, identifier })

    if not email then
        return { error = 'Email not found' }
    end

    MySQL.update.await([[
        UPDATE `fd_laptop_emails` SET `is_read` = 1
        WHERE `id` = ?
    ]], { id })

    return { success = true }
end)

---@param source number
---@param data { id: number }
---@return table
lib.callback.register('fd_laptop:server:emailDelete', function(source, data)
    local identifier = framework.getIdentifier(source)
    if not identifier then
        return { error = 'Unable to identify player' }
    end

    local id = data and data.id
    if not id then
        return { error = 'Email id is required' }
    end

    local email = MySQL.single.await([[
        SELECT e.`id`, e.`folder`
        FROM `fd_laptop_emails` e
        INNER JOIN `fd_laptop_email_accounts` a ON a.`address` = e.`owner_address`
        WHERE e.`id` = ? AND a.`identifier` = ?
    ]], { id, identifier })

    if not email then
        return { error = 'Email not found' }
    end

    if email.folder == 'trash' then
        MySQL.update.await([[
            DELETE FROM `fd_laptop_emails` WHERE `id` = ?
        ]], { id })
    else
        MySQL.update.await([[
            UPDATE `fd_laptop_emails` SET `folder` = 'trash'
            WHERE `id` = ?
        ]], { id })
    end

    return { success = true }
end)

lib.callback.register('fd_laptop:server:emailDeleteAll', function(source, data)
    local identifier = framework.getIdentifier(source)
    if not identifier then
        return { error = 'Unable to identify player' }
    end

    local address = data and data.address
    local folder = data and data.folder

    if not address or not folder then
        return { error = 'Address and folder are required' }
    end

    if folder ~= 'inbox' and folder ~= 'sent' and folder ~= 'trash' then
        return { error = 'Invalid folder' }
    end

    local owns = MySQL.scalar.await([[
        SELECT COUNT(*) FROM `fd_laptop_email_accounts`
        WHERE `address` = ? AND `identifier` = ?
    ]], { address, identifier })

    if (owns or 0) == 0 then
        return { error = 'Access denied' }
    end

    if folder == 'trash' then
        MySQL.update.await([[
            DELETE FROM `fd_laptop_emails`
            WHERE `owner_address` = ? AND `folder` = 'trash'
        ]], { address })
    else
        MySQL.update.await([[
            UPDATE `fd_laptop_emails` SET `folder` = 'trash'
            WHERE `owner_address` = ? AND `folder` = ?
        ]], { address, folder })
    end

    return { success = true }
end)

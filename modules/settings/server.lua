local framework = require 'bridge.framework'

---@type string[]
local fakeNames = require 'data.fakeNames'

---@type string[]
local fakeAvatars = require 'data.fakeAvatars'

---@type BackgroundSource[]
local backgrounds = require 'config.backgrounds'

---@type table<string, boolean>
local isProcessing = {}

---@return string
local function generateUsername()
    for _ = 1, 50 do
        local username = ('%s%s'):format(fakeNames[math.random(1, #fakeNames)], math.random(1000, 9999))
        local result = MySQL.scalar.await('SELECT username FROM `fd_laptop` WHERE username = ?', { username })

        if not result then
            return username
        end
    end

    return 'User' .. math.random(100000, 999999)
end

--- @return string
local function generateProfilePicture()
    return fakeAvatars[math.random(1, #fakeAvatars)]
end

---@param identifier string
---@return UserSettings | nil
local function loadUserSettings(identifier)
    if not identifier then return end

    local profile = MySQL.single.await([[
        SELECT
            *
        FROM
            `fd_laptop`
        WHERE
            identifier = ?
    ]], { identifier })

    if not profile then
        local username = generateUsername()
        local profile_picture = generateProfilePicture()
        local background = backgrounds[math.random(1, #backgrounds)].src

        MySQL.insert.await([[
            INSERT INTO
                `fd_laptop` (identifier, background, dark_mode, username, profile_picture)
            VALUES (
                ?,
                ?,
                ?,
                ?,
                ?
            )
        ]], {
            identifier,
            background,
            1,
            username,
            profile_picture
        })

        return {
            background = background,
            dark_mode = true,
            username = username,
            profile_picture = profile_picture,
            installedApps = {}
        }
    end

    return {
        background = profile.background,
        dark_mode = profile.dark_mode,
        username = profile.username,
        profile_picture = profile.profile_picture,
        installedApps = profile.installedApps
    }
end
exports('getUserSettings', loadUserSettings)

---@return boolean | string[]
local function getInstalledApps(source)
    local identifier = framework.getIdentifier(source)

    if not identifier then
        return false
    end

    local installedApps = MySQL.scalar.await([[
        SELECT
            installedApps
        FROM
            `fd_laptop`
        WHERE
            identifier = ?
    ]], { identifier })

    if not installedApps then
        return false
    end

    return installedApps
end


---@return boolean | table
local function getDesktopApps(source)
    local identifier = framework.getIdentifier(source)

    if not identifier then
        return false
    end

    local desktopApps = MySQL.scalar.await([[
        SELECT
            desktopApps
        FROM
            `fd_laptop`
        WHERE
            identifier = ?
    ]], { identifier })

    if not desktopApps then
        return false
    end

    return desktopApps
end

---@return boolean, string | nil
local function saveDesktopApps(source, payload)
    local identifier = framework.getIdentifier(source)

    if not identifier then
        return false, locale('something_went_wrong')
    end

    if type(payload) ~= 'table' then
        return false, 'Invalid payload'
    end

    local encoded = json.encode(payload)
    if #encoded > 10000 then
        return false, 'Payload too large'
    end

    MySQL.update([[
        UPDATE
            `fd_laptop`
        SET
            desktopApps = ?
        WHERE
            identifier = ?
    ]], {
        json.encode(payload),
        identifier
    }, function() end)

    return true, nil
end


---@return boolean, string | nil
local function saveUserProfile(source, username, profilePicture)
    local identifier = framework.getIdentifier(source)

    if not identifier then
        return false, locale('something_went_wrong')
    end

    if type(username) ~= 'string' or #username > 50 or #username < 1 then
        return false, 'Invalid username'
    end

    if type(profilePicture) ~= 'string' or #profilePicture > 500 then
        return false, 'Invalid profile picture'
    end

    local currentProfile = MySQL.single.await([[
        SELECT
            username,
            profile_picture,
            (SELECT COUNT(username) FROM `fd_laptop` WHERE username = ?) AS usernameExists
        FROM
            `fd_laptop`
        WHERE
            identifier = ?
    ]], { username, identifier })

    if currentProfile.username ~= username and currentProfile.usernameExists > 0 then
        return false, 'Such username already exists'
    end

    username = username or currentProfile.username
    profilePicture = profilePicture or currentProfile.profile_picture

    MySQL.update([[
        UPDATE
            `fd_laptop`
        SET
            username = ?,
            profile_picture = ?
        WHERE
            identifier = ?
    ]], {
        username,
        profilePicture,
        identifier
    }, function() end)

    return true, nil
end

---@return boolean, string | nil
local function saveBackground(source, background)
    local identifier = framework.getIdentifier(source)

    if not identifier then
        return false, locale('something_went_wrong')
    end

    MySQL.update([[
        UPDATE
            `fd_laptop`
        SET
            background = ?
        WHERE
            identifier = ?
    ]], {
        background,
        identifier
    }, function() end)

    return true, nil
end

RegisterNetEvent('fd_laptop:server:playerLoaded', function()
    local src = source
    local identifier = framework.getIdentifier(src)

    if not identifier then
        return
    end

    if isProcessing[identifier] then return end
    isProcessing[identifier] = true

    local settings = loadUserSettings(identifier)

    ---@diagnostic disable-next-line: param-type-mismatch
    TriggerClientEvent('fd_laptop:client:settingsReady', src, settings)

    local installedApps = getInstalledApps(src)
    if installedApps then
        ---@diagnostic disable-next-line: param-type-mismatch
        TriggerClientEvent('fd_laptop:client:userInstalledApps', src, json.decode(installedApps))
    end

    local desktopApps = getDesktopApps(src)
    if desktopApps then
        ---@diagnostic disable-next-line: param-type-mismatch
        TriggerClientEvent('fd_laptop:client:userDesktopApps', src, json.decode(desktopApps))
    else
        TriggerClientEvent('fd_laptop:client:userDesktopApps', src, {})
    end

    isProcessing[identifier] = nil
end)

local function loadJob()
    local src = source
    local job = framework.getJob(src)

    if not job then return end

    ---@diagnostic disable-next-line: param-type-mismatch
    TriggerClientEvent('fd_laptop:client:loadJob', src, job)
end
RegisterNetEvent('fd_laptop:server:playerLoaded', loadJob)
RegisterNetEvent('fd_laptop:server:jobUpdated', loadJob)

lib.callback.register('fd_laptop:server:updateBackground', saveBackground)
lib.callback.register('fd_laptop:server:updateProfile', saveUserProfile)
lib.callback.register('fd_laptop:server:saveDesktopApps', saveDesktopApps)

---@type UserSettings | nil
local userSettings

---@type boolean
local isProcessing

---@param username string
---@param profilePicture string
local function sendProfileUpdate(username, profilePicture)
    SendNUIMessage({
        action = 'updateProfile',
        data = {
            username = username,
            profilePicture = profilePicture
        }
    })
end

---@param settings UserSettings
local function sendSettings(settings)
    SendNUIMessage({
        action = 'updateSettings',
        data = settings
    })
end

---@param nickname string
---@param profilePicture string
---@return boolean, string | nil
local function updateProfile(nickname, profilePicture)
    if isProcessing then return false, locale('in_a_hurry') end
    isProcessing = true

    local success, error = lib.callback.await('fd_laptop:server:updateProfile', false, nickname, profilePicture)

    if success then
        userSettings.username = nickname
        userSettings.profile_picture = profilePicture

        sendProfileUpdate(nickname, profilePicture)
    end

    isProcessing = false
    return success, error
end

---@param background string
---@return boolean, string | nil
local function saveBackground(background)
    if isProcessing then return false, locale('in_a_hurry') end
    isProcessing = true

    local success, error = lib.callback.await('fd_laptop:server:updateBackground', false, background)

    if success then
        userSettings.background = background
    end

    isProcessing = false
    return success, error
end

---@param appearance boolean
---@return boolean, string | nil
local function saveAppearance(appearance)
    if isProcessing then return false, locale('in_a_hurry') end
    isProcessing = true

    local success, error = lib.callback.await('fd_laptop:server:updateAppearance', false, appearance)

    if success then
        userSettings.dark_mode = appearance
    end

    isProcessing = false
    return success, error
end

local function loadJob(job)
    if not job then return end

    SendNUIMessage({
        action = 'loadJob',
        data = job
    })
end
RegisterNetEvent('fd_laptop:client:loadJob', loadJob)

---@return UserSettings | nil
exports('getUserSettings', function()
    return userSettings
end)

RegisterNetEvent('fd_laptop:client:settingsReady', function(settings)
    userSettings = settings

    sendSettings(settings)
end)

RegisterNUICallback('updateUserSettings', function(data, cb)
    local success, error = updateProfile(data.nickname, data.profile_picture)

    cb({
        success = success,
        error = error
    })

    if not userSettings then return end

    sendSettings(userSettings)
end)

RegisterNUICallback('saveBackground', function(data, cb)
    local success, error = saveBackground(data.background)

    cb({
        success = success,
        error = error
    })

    if not userSettings then return end

    sendSettings(userSettings)
end)

RegisterNUICallback('saveAppearance', function(data, cb)
    local success, error = saveAppearance(data.isDarkMode)

    cb({
        success = success,
        error = error
    })

    if not userSettings then return end

    sendSettings(userSettings)
end)

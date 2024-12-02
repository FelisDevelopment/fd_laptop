---@type table<string, LaptopApp>
local apps = {}

---@type string[]
local installedApps = {}

---@param payload table<string, LaptopApp>
local function initApps(payload)
    local applications = {}

    apps = payload

    for _, app in pairs(payload) do
        applications[#applications + 1] = app
    end

    SendNUIMessage({
        action = 'initApps',
        data = applications
    })
end

---@param app LaptopApp
local function addNewApp(app)
    apps[app.id] = app

    if lib.table.contains(installedApps, app.id) then
        apps[app.id].isInstalled = true
    end

    SendNUIMessage({
        action = 'newApp',
        data = app
    })
end

---@param id string
local function removeApp(id)
    if not apps[id] then
        return
    end

    apps[id] = nil

    SendNUIMessage({
        action = 'removeApp',
        data = id
    })
end

---@param id string
local function markAsInstalled(id)
    if not apps[id] then
        return
    end

    apps[id].isInstalled = true

    SendNUIMessage({
        action = 'appInstalled',
        data = id
    })
end

---@param id string
---@return boolean, string | nil
local function installApp(id)
    if not apps[id] then
        return false, locale('app_not_found')
    end

    if apps[id].isInstalled then
        return false, locale('app_already_installed')
    end

    local app = apps[id]

    SetTimeout(app.appstore.installTime or 1000, function()
        markAsInstalled(id)
        lib.callback('fd_laptop:server:markAsInstalled', false, function() end, id)
    end)

    return true, nil
end

---@param id string
---@return boolean, string | nil
local function uninstallApp(id)
    if not apps[id] then
        return false, locale('app_not_found')
    end

    if not apps[id].isInstalled then
        return false, locale('app_not_installed')
    end

    apps[id].isInstalled = false

    lib.callback('fd_laptop:server:markAsUninstalled', false, function() end, id)

    return true, nil
end

---@param payload string[]
local function userInstalledApps(payload)
    installedApps = payload

    for _, id in pairs(payload) do
        markAsInstalled(id)
    end
end

---@param payload string[]
local function userDesktopApps(payload)
    SendNUIMessage({
        action = 'desktopApps',
        data = payload
    })
end

---@param id string
local function appOpened(id)
    if not apps[id] then
        return
    end

    if not apps[id].onUseServer and not apps[id].onUse then
        return
    end

    if apps[id].onUse then
        apps[id].onUse()
    end

    TriggerServerEvent('fd_laptop:server:appOpened', id)
end

---@param id string
local function appClosed(id)
    if not apps[id] then
        return
    end

    if not apps[id].onCloseServer and not apps[id].onClose then
        return
    end

    if apps[id].onClose then
        apps[id].onClose()
    end

    TriggerServerEvent('fd_laptop:server:appClosed', id)
end

---@param id string
---@param message any
local function sendAppMessage(id, message)
    SendNUIMessage({
        action = 'sendAppMessage',
        data = {
            id = id,
            message = message
        }
    })
end
exports('sendAppMessage', sendAppMessage)

---@param id string
local function requestAppClosing(id)
    SendNUIMessage({
        action = 'requestAppClosing',
        data = id
    })
end
exports('closeApp', requestAppClosing)

---@param payload table
local function saveDesktopApps(payload)
    lib.callback('fd_laptop:server:saveDesktopApps', false, function() end, payload)
end

RegisterNetEvent('fd_laptop:client:appsReady', initApps)
RegisterNetEvent('fd_laptop:client:newApp', addNewApp)
RegisterNetEvent('fd_laptop:client:removeApp', removeApp)
RegisterNetEvent('fd_laptop:client:userInstalledApps', userInstalledApps)
RegisterNetEvent('fd_laptop:client:userDesktopApps', userDesktopApps)

RegisterNUICallback('installApp', function(data, cb)
    local success, error = installApp(data.id)

    cb({
        success = success,
        error = error
    })
end)

RegisterNUICallback('uninstallApp', function(data, cb)
    local success, error = uninstallApp(data.id)

    cb({
        success = success,
        error = error
    })
end)

RegisterNUICallback('appOpened', function(data, cb)
    appOpened(data.id)

    cb(1)
end)

RegisterNUICallback('appClosed', function(data, cb)
    appClosed(data.id)

    cb(1)
end)

RegisterNUICallback('saveDesktopApps', function(data, cb)
    saveDesktopApps(data.desktopApps)

    cb(1)
end)

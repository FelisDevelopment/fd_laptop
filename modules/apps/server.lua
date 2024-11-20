local framework = require 'bridge.framework'

---@type table<string, LaptopApp>
local laptopApps = require 'config.server.apps'

local function getApps()
    return laptopApps
end

RegisterNetEvent("fd_laptop:server:clientReady", function()
    local src = source
    local apps = getApps()

    ---@diagnostic disable-next-line: param-type-mismatch
    TriggerClientEvent("fd_laptop:client:appsReady", src, apps)
end)

---@param app LaptopApp
---@return boolean, string?
local function addCustomApp(app)
    if not app then
        return false, locale('app_required')
    end

    if not app.id then
        return false, locale('app_id_is_required')
    end

    if not app.name then
        return false, locale('app_name_is_required')
    end

    if not app.icon then
        return false, locale('app_icon_is_required')
    end

    if not app.ui then
        return false, locale('app_ui_is_required')
    end

    if laptopApps[app.id] then
        lib.print.info(("App %s already exists, it will be overwritten"):format(app.id))
    end

    if app.deviceId then
        app.appstore = nil
        app.isDefaultApp = false
    end

    app.resourceName = GetInvokingResource() or GetCurrentResourceName()

    laptopApps[app.id] = app

    TriggerClientEvent('fd_laptop:client:newApp', -1, app)

    return true, nil
end
exports("addCustomApp", addCustomApp)

---@param id string
---@return boolean, string?
local function removeCustomApp(id)
    if not id then
        return false, locale('app_id_is_required')
    end

    if not laptopApps[id] then
        return false, locale('app_does_not_exist')
    end

    laptopApps[id] = nil

    TriggerClientEvent('fd_laptop:client:removeApp', -1, id)

    return true, nil
end
exports("removeCustomApp", removeCustomApp)

local function markAsInstalled(source, id)
    if not laptopApps[id] then
        return false, locale('app_does_not_exist')
    end

    local identifier = framework.getIdentifier(source)

    if not identifier then
        return false, locale('something_went_wrong')
    end

    MySQL.update([[
        UPDATE
            `fd_laptop`
        SET
            installedApps = JSON_ARRAY_APPEND(installedApps, '$', ?)
        WHERE
            identifier = ?
    ]], {
        id,
        identifier
    }, function() end)

    return true, nil
end
lib.callback.register("fd_laptop:server:markAsInstalled", markAsInstalled)

local function markAsUninstalled(source, id)
    if not laptopApps[id] then
        return false, locale('app_does_not_exist')
    end

    local identifier = framework.getIdentifier(source)

    if not identifier then
        return false, locale('something_went_wrong')
    end

    MySQL.update([[
        UPDATE
            `fd_laptop`
        SET
            installedApps = JSON_REMOVE(installedApps, JSON_UNQUOTE(JSON_SEARCH(installedApps, 'one', ?)))
        WHERE
            identifier = ?
    ]], {
        id,
        identifier
    }, function() end)

    return true, nil
end
lib.callback.register("fd_laptop:server:markAsUninstalled", markAsUninstalled)

local function appOpened(id)
    local src = source

    if not laptopApps[id] then
        return false, locale('app_does_not_exist')
    end

    if not laptopApps[id].onUseServer then
        return
    end

    laptopApps[id].onUseServer(src, id)
end
RegisterNetEvent('fd_laptop:server:appOpened', appOpened)


local function appClosed(id)
    local src = source

    if not laptopApps[id] then
        return false, locale('app_does_not_exist')
    end

    if not laptopApps[id].onCloseServer then
        return
    end

    laptopApps[id].onCloseServer(src, id)
end
RegisterNetEvent('fd_laptop:server:appClosed', appClosed)

AddEventHandler("onResourceStop", function(resourceName)
    for _, app in pairs(laptopApps) do
        if app.resourceName == resourceName then
            removeCustomApp(app.id)
        end
    end
end)

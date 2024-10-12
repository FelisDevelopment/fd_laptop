Ox = require '@ox_core.lib.init'
local playerLoaded

AddEventHandler('ox:playerLoaded', function()
    playerLoaded = true
    TriggerServerEvent('fd_laptop:server:playerLoaded')
end)

AddEventHandler('ox:playerLogout', function()
    playerLoaded = false
    TriggerServerEvent('fd_laptop:server:playerUnloaded')
end)

RegisterNetEvent('fd_laptop:client:appsReady', function()
    if not playerLoaded then return end

    TriggerServerEvent('fd_laptop:server:playerLoaded')
end)

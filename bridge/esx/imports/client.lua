ESX = exports.es_extended:getSharedObject()

RegisterNetEvent('esx:playerLoaded', function()
    ESX.PlayerLoaded = true
    TriggerServerEvent('fd_laptop:server:playerLoaded')
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    ESX.PlayerLoaded = false
    TriggerServerEvent('fd_laptop:server:playerUnloaded')
end)

RegisterNetEvent('fd_laptop:client:appsReady', function()
    if not ESX.PlayerLoaded then return end

    TriggerServerEvent('fd_laptop:server:playerLoaded')
end)

NDCore = exports.ND_Core

RegisterNetEvent('ND:characterLoaded', function()
    LocalPlayer.state.isLoggedIn = true
    TriggerServerEvent('fd_laptop:server:playerLoaded')
end)

RegisterNetEvent('ND:characterUnloaded', function()
    LocalPlayer.state.isLoggedIn = false
    TriggerServerEvent('fd_laptop:server:playerUnloaded')
end)

RegisterNetEvent('fd_laptop:client:appsReady', function()
    if not LocalPlayer.state.isLoggedIn then return end

    TriggerServerEvent('fd_laptop:server:playerLoaded')
end)
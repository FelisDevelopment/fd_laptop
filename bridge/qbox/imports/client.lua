RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('fd_laptop:server:playerLoaded')
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    TriggerServerEvent('fd_laptop:server:playerUnloaded')
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    TriggerServerEvent('fd_laptop:server:jobUpdated')
end)

RegisterNetEvent('fd_laptop:client:appsReady', function()
    if not LocalPlayer.state.isLoggedIn then return end

    TriggerServerEvent('fd_laptop:server:playerLoaded')
end)

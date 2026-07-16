RegisterNUICallback('emailGetConfig', function(data, cb)
    local result = lib.callback.await('fd_laptop:server:emailGetConfig', false, data)

    cb(result)
end)

RegisterNUICallback('emailGetAccounts', function(data, cb)
    local result = lib.callback.await('fd_laptop:server:emailGetAccounts', false, data)

    cb(result)
end)

RegisterNUICallback('emailCreate', function(data, cb)
    local result = lib.callback.await('fd_laptop:server:emailCreate', false, data)

    cb(result)
end)

RegisterNUICallback('emailGetEmails', function(data, cb)
    local result = lib.callback.await('fd_laptop:server:emailGetEmails', false, data)

    cb(result)
end)

RegisterNUICallback('emailSend', function(data, cb)
    local result = lib.callback.await('fd_laptop:server:emailSend', false, data)

    cb(result)
end)

RegisterNUICallback('emailMarkRead', function(data, cb)
    local result = lib.callback.await('fd_laptop:server:emailMarkRead', false, data)

    cb(result)
end)

RegisterNUICallback('emailDelete', function(data, cb)
    local result = lib.callback.await('fd_laptop:server:emailDelete', false, data)

    cb(result)
end)

RegisterNUICallback('emailDeleteAll', function(data, cb)
    local result = lib.callback.await('fd_laptop:server:emailDeleteAll', false, data)

    cb(result)
end)

RegisterNetEvent('fd_laptop:client:newEmail', function(data)
    SendNUIMessage({
        action = 'emailNewNotification',
        data = data
    })

    exports['fd_laptop']:sendNotification({
        summary = data.from_address,
        detail = data.subject or locale('email_new_email')
    })
end)

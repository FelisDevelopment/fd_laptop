RegisterNUICallback('calendarGetEvents', function(data, cb)
    local result = lib.callback.await('fd_laptop:server:calendarGetEvents', false, data)

    cb(result)
end)

RegisterNUICallback('calendarCreateEvent', function(data, cb)
    local result = lib.callback.await('fd_laptop:server:calendarCreateEvent', false, data)

    cb(result)
end)

RegisterNUICallback('calendarDeleteEvent', function(data, cb)
    local result = lib.callback.await('fd_laptop:server:calendarDeleteEvent', false, data)

    cb(result)
end)

RegisterNUICallback('calendarToggleReminder', function(data, cb)
    local result = lib.callback.await('fd_laptop:server:calendarToggleReminder', false, data)

    cb(result)
end)

--- Send calendar reminders when the laptop is opened
RegisterNetEvent('fd_laptop:client:useLaptop', function()
    SetTimeout(2000, function()
        local result = lib.callback.await('fd_laptop:server:calendarCheckReminders', false)

        if not result or #result == 0 then return end

        for _, event in ipairs(result) do
            local detail = event.title
            if event.time then
                detail = event.time .. ' - ' .. detail
            end

            exports[GetCurrentResourceName()]:sendNotification({
                summary = locale('calendar_reminder'),
                detail = detail
            })

            Wait(500)
        end
    end)
end)

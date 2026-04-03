RegisterNUICallback('notesGetAll', function(data, cb)
    local result = lib.callback.await('fd_laptop:server:notesGetAll', false, data)

    cb(result)
end)

RegisterNUICallback('notesCreate', function(data, cb)
    local result = lib.callback.await('fd_laptop:server:notesCreate', false, data)

    cb(result)
end)

RegisterNUICallback('notesUpdate', function(data, cb)
    local result = lib.callback.await('fd_laptop:server:notesUpdate', false, data)

    cb(result)
end)

RegisterNUICallback('notesTogglePin', function(data, cb)
    local result = lib.callback.await('fd_laptop:server:notesTogglePin', false, data)

    cb(result)
end)

RegisterNUICallback('notesDelete', function(data, cb)
    local result = lib.callback.await('fd_laptop:server:notesDelete', false, data)

    cb(result)
end)

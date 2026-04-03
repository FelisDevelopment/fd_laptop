RegisterNUICallback('spellmeGetState', function(_, cb)
    local result = lib.callback.await('fd_laptop:server:spellmeGetState', false)

    cb(result)
end)

RegisterNUICallback('spellmeGuess', function(data, cb)
    local result = lib.callback.await('fd_laptop:server:spellmeGuess', false, data)

    cb(result)
end)

RegisterNUICallback('spellmeLeaderboard', function(data, cb)
    local result = lib.callback.await('fd_laptop:server:spellmeLeaderboard', false, data)

    cb(result)
end)

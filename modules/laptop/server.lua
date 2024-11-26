local config = require 'config.server.item'
local repository = 'FelisDevelopment/fd_laptop'
local needsUpdate = false

-- Credits goes to overextended for this, I'm too lazy to rewrite it for no reason at all
-- https://github.com/overextended/ox_lib/blob/master/resource/version/server.lua
local function checkLaptopVersion(repository)
    local resource = GetInvokingResource() or GetCurrentResourceName()

    local currentVersion = GetResourceMetadata(resource, 'version', 0)

    if currentVersion then
        currentVersion = currentVersion:match('%d+%.%d+%.%d+')
    end

    if not currentVersion then
        return print(("^1Unable to determine current resource version for '%s' ^0"):format(
            resource))
    end

    SetTimeout(1000, function()
        PerformHttpRequest(('https://api.github.com/repos/%s/releases/latest'):format(repository),
            function(status, response)
                if status ~= 200 then return end

                response = json.decode(response)
                if response.prerelease then return end

                local latestVersion = response.tag_name:match('%d+%.%d+%.%d+')
                if not latestVersion or latestVersion == currentVersion then return end

                local cv = { string.strsplit('.', currentVersion) }
                local lv = { string.strsplit('.', latestVersion) }

                for i = 1, #cv do
                    local current, minimum = tonumber(cv[i]), tonumber(lv[i])

                    if current ~= minimum then
                        if current < minimum then
                            needsUpdate = true

                            return print(('^3An update is available for %s (current version: %s)\r\n%s^0'):format(
                                resource, currentVersion, response.html_url))
                        else
                            break
                        end
                    end
                end
            end, 'GET')
    end)
end

AddEventHandler('fd_laptop:server:useLaptop', function(source, laptopId, devices)
    if not laptopId then return end

    TriggerClientEvent('fd_laptop:client:useLaptop', source, config.item, laptopId, devices)
end)

RegisterNetEvent('fd_laptop:server:clientReady', function()
    local src = source

    if not needsUpdate then return end

    ---@diagnostic disable-next-line: param-type-mismatch
    TriggerClientEvent('fd_laptop:client:versionUpdate', src)
end)

RegisterNetEvent('fd_laptop:server:playerUnloaded', function()
    ---@diagnostic disable-next-line: param-type-mismatch
    TriggerClientEvent('fd_laptop:client:playerUnloaded', source)
end)

lib.callback.register('fd_laptop:laptopItem', function(source)
    return config.item
end)

checkLaptopVersion(repository)

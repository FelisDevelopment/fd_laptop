local config = require 'config.item'
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

AddEventHandler('fd_laptop:server:useLaptop', function(source, laptopId, devices, hasPassword)
    if not laptopId then return end

    TriggerClientEvent('fd_laptop:client:useLaptop', source, config.item, laptopId, devices, hasPassword)
    lib.print.debug('Player', source, 'is using laptop', laptopId)

    local state = Player(source).state
    lib.print.debug('Setting isUsingLaptop state for player', source)
    state:set('isUsingLaptop', true, true)
end)

RegisterNetEvent("fd_laptop:server:laptopClosed", function()
    local src = source
    local state = Player(src).state

    if not state.isUsingLaptop then return end

    lib.print.debug('Clearing isUsingLaptop state for player', src)
    state:set('isUsingLaptop', false, true)
end)

RegisterNetEvent('fd_laptop:server:clientReady', function()
    local src = source

    if not needsUpdate then return end

    ---@diagnostic disable-next-line: param-type-mismatch
    TriggerClientEvent('fd_laptop:client:versionUpdate', src)
end)

AddEventHandler('fd_laptop:server:playerUnloaded', function(src)
    ---@diagnostic disable-next-line: param-type-mismatch
    TriggerClientEvent('fd_laptop:client:playerUnloaded', src)
end)

lib.callback.register('fd_laptop:laptopItem', function(source)
    return config.item
end)

local function findLaptopSlot(src)
    if not config.item then return nil end

    local ox_inventory = exports.ox_inventory
    local items = ox_inventory:GetInventoryItems(src)
    if not items then return nil end

    for _, item in pairs(items) do
        if item.name == config.item and item.metadata?.id then
            return item.slot, item
        end
    end

    return nil
end

lib.callback.register('fd_laptop:server:saveLaptopPassword', function(source, data)
    local password = data and data.password
    if password ~= nil and type(password) ~= 'string' then
        return { success = false, error = 'Invalid password' }
    end

    local state = Player(source).state
    if not state.isUsingLaptop then
        return { success = false, error = 'Laptop not open' }
    end

    local slot, item = findLaptopSlot(source)
    if not slot or not item then
        return { success = false, error = 'Laptop not found' }
    end

    local trimmed = password and password:match('^%s*(.-)%s*$') or ''
    local metadata = item.metadata or {}

    if trimmed == '' then
        metadata.password = nil
    else
        if #trimmed < 4 then
            return { success = false, error = 'Password must be at least 4 characters' }
        end
        metadata.password = trimmed
    end

    exports.ox_inventory:SetMetadata(source, slot, metadata)
    return { success = true }
end)

lib.callback.register('fd_laptop:server:validateLaptopPassword', function(source, data)
    local password = data and data.password
    if type(password) ~= 'string' then
        return { success = false, error = 'Invalid password' }
    end

    local _, item = findLaptopSlot(source)
    if not item or not item.metadata?.password then
        return { success = true }
    end

    local trimmed = password:match('^%s*(.-)%s*$') or ''
    if trimmed == item.metadata.password then
        return { success = true }
    end

    return { success = false, error = 'Wrong password' }
end)

checkLaptopVersion(repository)

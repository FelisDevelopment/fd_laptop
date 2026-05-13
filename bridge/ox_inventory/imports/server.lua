local itemConfig = require 'config.item'
local config = require 'config.laptop'
if not itemConfig.item then return end

local utils = require 'utils.server'
local ox_inventory = exports.ox_inventory

---@type table<string, true>
local registeredStashes = {}

ox_inventory:registerHook('createItem', function(payload)
    local metadata = payload.metadata or {}

    -- Set metadata to include the recipe name
    if not metadata or not metadata.id then
        metadata = { id = utils.uuid() }
    end

    return metadata
end, {
    print = config.debug,
    itemFilter = {
        [itemConfig.item] = true
    }
})

local swapHookId = ox_inventory:registerHook('swapItems', function(payload)
    local toInventory = payload.toInventory
    local fromInventory = payload.fromInventory

    local isToLaptop = type(toInventory) == 'string' and string.find(toInventory, '^fd_laptop_')

    if isToLaptop then
        local fromSlot = payload.fromSlot
        if fromSlot then
            local metadata = fromSlot.metadata
            if metadata and metadata.deviceId and metadata.deviceLabel then
                if metadata.noDuplicate then
                    local count = ox_inventory:Search(toInventory, 'count', fromSlot.name, {
                        deviceId = metadata.deviceId
                    })

                    if count > 0 then
                        return false
                    end
                end
            end
        end
    end
end, {
    print = config.debug
})

AddEventHandler(swapHookId, function(success, payload)
    if not success then return end

    local toInventory = payload.toInventory
    local fromInventory = payload.fromInventory

    local isToLaptop = type(toInventory) == 'string' and string.find(toInventory, '^fd_laptop_')
    local isFromLaptop = type(fromInventory) == 'string' and string.find(fromInventory, '^fd_laptop_')

    if isToLaptop or isFromLaptop then
        local laptopId = isToLaptop and string.gsub(toInventory, 'fd_laptop_', '') or string.gsub(fromInventory, 'fd_laptop_', '')
        
        local items = ox_inventory:GetInventoryItems(('fd_laptop_%s'):format(laptopId)) or {}
        local devices = {}
        local devicesCount = 0

        for _, item in pairs(items) do
            local metadata = item.metadata
            if metadata and metadata.deviceId then
                devicesCount += 1
                devices[devicesCount] = {
                    slot = item.slot,
                    metadata = metadata
                }
            end
        end

        TriggerClientEvent('fd_laptop:client:updateDevices', -1, laptopId, devices)
    end
end)

local function registerStash(id)
    if not registeredStashes[id] then
        ox_inventory:RegisterStash(('fd_laptop_%s'):format(id), locale('laptop_stash_label'),
            itemConfig.slots,
            itemConfig.weight)
        registeredStashes[id] = true
    end
end

RegisterNetEvent('fd_laptop:server:openLaptopStorage', function(slot)
    local src = source

    local item = ox_inventory:GetSlot(src, slot)
    if not item then return end
    if not item.metadata?.id then return end

    if not registeredStashes[item.metadata.id] then
        registerStash(item.metadata.id)
    end

    ox_inventory:forceOpenInventory(src, 'stash', {
        id = ('fd_laptop_%s'):format(item.metadata.id)
    })
end)

exports('useLaptop', function(event, _, inventory, slot, _)
    if event == 'usingItem' then
        CreateThread(function()
            local item = ox_inventory:GetSlot(inventory.id, slot)
            if not item then return false end
            if not item.metadata?.id then
                item.metadata = { id = utils.uuid() }
                ox_inventory:SetMetadata(inventory.id, slot, item.metadata)
                Wait(100)
             end

            if not registeredStashes[item.metadata.id] then
                registerStash(item.metadata.id)
            end

            local items = exports.ox_inventory:GetInventoryItems(('fd_laptop_%s'):format(item.metadata.id)) or {}

            local devices = {}

            for _, item in pairs(items) do
                if item.metadata?.deviceId then
                    devices[#devices + 1] = {
                        slot = item.slot,
                        metadata = item.metadata
                    }
                end
            end

            local hasPassword = item.metadata?.password ~= nil and item.metadata.password ~= ''
            TriggerEvent('fd_laptop:server:useLaptop', inventory.id, item.metadata?.id, devices, hasPassword)
        end)

        return false
    end
end)

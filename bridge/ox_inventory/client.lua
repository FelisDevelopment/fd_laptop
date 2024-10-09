local inventory = {}

function inventory.hasItem(itemName, metadata)
    local count = exports.ox_inventory:Search('count', itemName, metadata)

    return count > 0
end

return inventory

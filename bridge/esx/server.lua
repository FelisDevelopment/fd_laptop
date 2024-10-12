local framework = {}

---@param src number
---@return string|nil
function framework.getIdentifier(src)
    local player = ESX.GetPlayerFromId(src)

    if not player then
        return nil
    end

    return player.identifier
end

return framework

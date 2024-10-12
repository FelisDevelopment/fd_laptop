local framework = {}

---@param src number
---@return string|nil
function framework.getIdentifier(src)
    local player =  NDCore:getPlayer(src)

    if not player then
        return nil
    end

    return player.getData('identifier')
end

return framework

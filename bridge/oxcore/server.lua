local framework = {}

---@param src number
---@return string|nil
function framework.getIdentifier(src)
    local player = Ox.GetPlayer(src)

    if not player then
        return nil
    end

    return player.stateId
end

return framework

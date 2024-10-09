local framework = {}

---@param src number
---@return string|nil
function framework.getIdentifier(src)
    local player = exports.qbx_core:GetPlayer(src)

    if not player then
        return nil
    end

    return player.PlayerData.citizenid
end

return framework

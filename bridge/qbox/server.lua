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

---@param src number
---@return string|nil
function framework.getJob(src)
    local player = exports.qbx_core:GetPlayer(src)

    if not player then
        return nil
    end

    return player.PlayerData.job.name
end

return framework

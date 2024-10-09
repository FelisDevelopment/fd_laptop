math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 9)))
local random = math.random
local utils = {}

function utils.uuid()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    local ans = string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)

    return ans
end

return utils

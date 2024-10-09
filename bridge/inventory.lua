local inventories = require 'bridge.options.inventories'
local side = IsDuplicityVersion() and 'server' or 'client'

local inventory

for i = 1, #inventories do
    local resource, dirName = table.unpack(inventories[i])

    if GetResourceState(resource):find('start') then
        local path = ('bridge.%s.%s'):format(dirName, side)
        local resourceFilePath = ('%s.lua'):format(path:gsub('%.', '/'))

        if LoadResourceFile(GetCurrentResourceName(), resourceFilePath) and not inventory then
            inventory = require(path)

            break
        end
    end
end

return inventory

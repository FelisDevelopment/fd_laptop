local frameworks = require 'bridge.options.frameworks'
local side = IsDuplicityVersion() and 'server' or 'client'

local framework

for i = 1, #frameworks do
    local resource, dirName = table.unpack(frameworks[i])

    if GetResourceState(resource):find('start') then
        local path = ('bridge.%s.%s'):format(dirName, side)
        local resourceFilePath = ('%s.lua'):format(path:gsub('%.', '/'))

        if LoadResourceFile(GetCurrentResourceName(), resourceFilePath) and not framework then
            framework = require(path)

            break
        end
    end
end

return framework

local frameworks = require 'bridge.options.frameworks'
local inventories = require 'bridge.options.inventories'
local side = IsDuplicityVersion() and 'server' or 'client'

local resources = inventories

-- Making sure to add frameworks last, so we can break after qbx_core, since it provides qbcore
for i = 1, #frameworks do
    resources[#resources + 1] = frameworks[i]
end

for i = 1, #resources do
    local resource, dirName = table.unpack(resources[i])

    if GetResourceState(resource):find('start') then
        local path = ('bridge.%s.imports.%s'):format(dirName, side)
        local resourceFilePath = ('%s.lua'):format(path:gsub('%.', '/'))

        if LoadResourceFile(GetCurrentResourceName(), resourceFilePath) then
            require(path)
        end

        if resource == 'qbx_core' then
            break
        end
    end
end

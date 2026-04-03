local availableBackgrounds = require 'config.backgrounds'
local laptopSettings = require 'config.laptop'
local inventory = require 'bridge.inventory'
local itemConfig = require 'config.item'

local objects = {}

local needsUpdate = false
local laptopItem, currentlyOpen, devices = nil, nil, {}
local timeInterval


---@return table<string, string>
local function getUILocales()
    local ui = {}

    for key, value in pairs(lib.getLocales()) do
        if key:sub(1, 3) == 'ui.' then
            ui[key:sub(4)] = value
        end
    end

    return ui
end

---Handle server time loop
---@return nil
local function serverTimeLoop()
    if timeInterval then ClearInterval(timeInterval) end
    timeInterval = SetInterval(function()
        SendNUIMessage({
            action = 'updateClock',
            data = {
                hour = GetClockHours(),
                minute = GetClockMinutes(),
            }
        })
    end, 1000)
end

---Handle laptop initialization
---@return nil
local function initLaptop()
    local locales = getUILocales()

    if laptopSettings.useServerTime then
        serverTimeLoop()
    end

    SendNUIMessage({
        action = 'initLaptop',
        data = {
            locales = locales,
            useServerTime = laptopSettings.useServerTime,
            clock24h = laptopSettings.clock24h,
            dateFormat = laptopSettings.dateFormat,
            dateLocale = laptopSettings.dateLocale,
            needsUpdate = needsUpdate
        }
    })

    TriggerServerEvent("fd_laptop:server:clientReady")
end

---Reset states on laptop close
local function reset()
    currentlyOpen = nil
    devices = {}
    laptopItem = nil
end

---Open laptop
---@param item string
---@param laptopId string
---@param installedDevices table<LaptopDevice>
---@param hasPassword? boolean
local function open(item, laptopId, installedDevices, hasPassword)
    laptopItem = item
    currentlyOpen = laptopId
    devices = installedDevices

    lib.playAnim(cache.ped, itemConfig.attachment.animation.dict, itemConfig.attachment.animation.name, 8.0, -8.0, -1, itemConfig.attachment.animation.flag, 0, false, 0, false)

    SendNUIMessage({
        action = 'openLaptop',
        data = {
            laptopId = laptopId,
            devices = devices,
            hasPassword = hasPassword or false
        }
    })

    SetNuiFocus(true, true)
    SetCursorLocation(0.5, 0.5)
end

---Close laptop
---@param dontSend? boolean
local function close(dontSend)
    TriggerServerEvent('fd_laptop:server:laptopClosed')

    ClearPedTasks(cache.ped)
    ClearPedSecondaryTask(cache.ped)
    Wait(250)
    reset()

    SetNuiFocus(false, false)

    if dontSend then return end

    SendNUIMessage({
        action = 'closeLaptop'
    })
end
exports('close', close)

local function startItemCheck()
    if not laptopItem then return end

    CreateThread(function()
        while currentlyOpen do
            local hasItem = inventory.hasItem(laptopItem, {
                id = currentlyOpen
            })

            if not hasItem then
                return close()
            end

            Wait(2000)
        end
    end)
end

local function getDevices()
    if not currentlyOpen then
        return nil
    end

    return currentlyOpen, devices
end
exports('getDevices', getDevices)

RegisterNUICallback('init', function(_, cb)
    initLaptop()

    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    close(true)
    cb('ok')
end)

RegisterNUICallback('availableBackgrounds', function(_, cb)
    cb(availableBackgrounds)
end)

RegisterNUICallback('saveLaptopPassword', function(data, cb)
    local result = lib.callback.await('fd_laptop:server:saveLaptopPassword', false, data)
    cb(result)
end)

RegisterNUICallback('validateLaptopPassword', function(data, cb)
    local result = lib.callback.await('fd_laptop:server:validateLaptopPassword', false, data)
    cb(result)
end)

AddEventHandler("OnResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        ClearInterval(timeInterval)
        timeInterval = nil
    end
end)

RegisterNetEvent("fd_laptop:client:versionUpdate", function()
    needsUpdate = true
end)

RegisterNetEvent("fd_laptop:client:useLaptop", function(item, laptopId, installedDevices, hasPassword)
    if not laptopId then return end

    open(item, laptopId, installedDevices, hasPassword)
    startItemCheck()
end)

RegisterNetEvent("fd_laptop:client:playerUnloaded", function()
    close()
end)

---@param entity number
---@param model number | string
---@param bone number
---@param position vector3
---@param rotation vector3
local function handleObject(entity, model, bone, position, rotation)
    if laptopSettings.debug then
        return
    end

    local ped = GetPlayerPed(entity)
    lib.requestModel(model)

    local object = CreateObject(model, 0.0, 0.0, 0.0, false, false, false)
    SetEntityCollision(object, false, false)
    AttachEntityToEntity(
        object,
        ped,
        GetPedBoneIndex(ped, bone),
        position.x,
        position.y,
        position.z,
        rotation.x,
        rotation.y,
        rotation.z,
        true,
        true,
        false,
        true,
        1,
        true
    )

    objects[ped] = object

    SetModelAsNoLongerNeeded(model)
end

---@param entity number
---@param state boolean | nil
local function handleRemotePlayerChanges(entity, state)
    if objects[entity] then
        if DoesEntityExist(objects[entity]) then
            DeleteObject(objects[entity])
        end

        objects[entity] = nil
    end

    local _, exists = pcall(function()
        lib.waitFor(function()
            local ped = GetPlayerPed(entity)

            if ped ~= 0 then
                return true
            end
        end, nil, 5 * 1000)

        return true
    end)

    if not exists then return end
    if not state then return end

    lib.print.debug('Attach laptop to remote player', entity)
    handleObject(
        entity,
        itemConfig.attachment.model,
        itemConfig.attachment.bone,
        itemConfig.attachment.coords.position,
        itemConfig.attachment.coords.rotation
    )
end

local function localCleanup()
    if objects[cache.ped] and DoesEntityExist(objects[cache.ped]) then
        DeleteObject(objects[cache.ped])
    end

    ClearPedTasks(cache.ped)
end

local function localPropSpawn()
    lib.print.debug('Attach laptop to local player')
    
    handleObject(
        cache.playerId,
        itemConfig.attachment.model,
        itemConfig.attachment.bone,
        itemConfig.attachment.coords.position,
        itemConfig.attachment.coords.rotation
    )
end

---@param name string
---@param value boolean | nil
local function handleStateBagChanges(name, _, value)
    local entity = GetPlayerFromStateBagName(name)
    lib.print.debug('State bag change detected for', name, 'entity:', entity, 'value:', value)
    if not entity then return lib.print.debug('No entity found for state bag name:', name) end

    if entity ~= cache.playerId then
        handleRemotePlayerChanges(entity, value)
        lib.print.debug('Handled remote player state bag change')

        return
    end

    if not value then
        lib.print.debug('Handling local player laptop close')
        return localCleanup()
    end

    lib.print.debug('Handling local player laptop open')
    localPropSpawn()
end
AddStateBagChangeHandler('isUsingLaptop', null, handleStateBagChanges)
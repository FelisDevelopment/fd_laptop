local availableBackgrounds = require 'config.backgrounds'
local laptopSettings = require 'config.laptop'
local inventory = require 'bridge.inventory'

local needsUpdate = false
local laptopItem, currentlyOpen, devices = nil, nil, {}
local timeInterval
local laptop


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
local function open(item, laptopId, installedDevices)
    laptopItem = item
    currentlyOpen = laptopId
    devices = installedDevices

    lib.requestModel(`prop_laptop_facade`, 2000)
    laptop = CreateObject(`prop_laptop_facade`, 0, 0, 0, true, false, false)
    SetEntityCollision(laptop, false, false)

    lib.playAnim(cache.ped, 'missheistdockssetup1clipboard@base', 'base', 8.0, -8.0, -1, 49, 0, false, 0, false)
    AttachEntityToEntity(laptop, cache.ped, 42, 0.10, 0.15, 0.07, 10.0, 0.0, 0.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(`prop_laptop_facade`)

    SendNUIMessage({
        action = 'openLaptop',
        data = {
            laptopId = laptopId,
            devices = devices
        }
    })

    SetNuiFocus(true, true)
    SetCursorLocation(0.5, 0.5)
end

---Close laptop
---@param dontSend? boolean
local function close(dontSend)
    ClearPedTasks(cache.ped)
    ClearPedSecondaryTask(cache.ped)
    Wait(250)
    DetachEntity(laptop, true, false)
    DeleteEntity(laptop)
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

AddEventHandler("OnResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        ClearInterval(timeInterval)
        timeInterval = nil
    end
end)

RegisterNetEvent("fd_laptop:client:versionUpdate", function()
    needsUpdate = true
end)

RegisterNetEvent("fd_laptop:client:useLaptop", function(item, laptopId, installedDevices)
    if not laptopId then return end

    open(item, laptopId, installedDevices)
    startItemCheck()
end)

RegisterNetEvent("fd_laptop:client:playerUnloaded", function()
    close()
end)

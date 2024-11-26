local inventory = require 'bridge.inventory'

---@type boolean
local doNotDisturb = false

---@type number
local lastNotificationSound = 0

---@type string | nil
local item = lib.callback.await('fd_laptop:laptopItem', false)

---@param data Notification
local function sendNotification(data)
    if not data then return end
    if not data.summary then return end
    if not data.detail then return end

    if doNotDisturb then
        return
    end

    if not inventory.hasItem(item, nil) then
        return
    end

    if GetGameTimer() - lastNotificationSound >= 5000 then
        PlaySoundFrontend(-1, "Text_Arrive_Tone", "Phone_SoundSet_Default", true)
        lastNotificationSound = GetGameTimer() + 5000
    end

    SendNUIMessage({
        action = 'newNotification',
        data = {
            summary = data.summary,
            detail = data.detail
        }
    })
end
exports('sendNotification', sendNotification)

RegisterNUICallback('setDoNotDisturb', function(data, cb)
    doNotDisturb = data.doNotDisturb

    cb(1)
end)

RegisterNetEvent('fd_laptop:server:playerUnloaded', function()
    doNotDisturb = false
    lastNotificationSound = 0
end)

lib.locale()

local isServer = IsDuplicityVersion()
if not isServer then return end

-- Built UI check from https://github.com/overextended/ox_inventory/blob/main/init.lua
-- People don't listen.
local function addDeferral(err)
    err = err:gsub("%^%d", "")

    AddEventHandler('playerConnecting', function(_, _, deferrals)
        deferrals.defer()
        deferrals.done(err)
    end)
end

-- People like ignoring errors for some reason
local function spamError(err)
    CreateThread(function()
        while true do
            Wait(10000)
            CreateThread(function()
                error(err, 0)
            end)
        end
    end)

    addDeferral(err)
    error(err, 0)
end

if not LoadResourceFile(GetCurrentResourceName(), 'web/dist/index.html') then
    return spamError(
        'Theres no built UI, download a release build or build it your self.\n	^3https://github.com/FelisDevelopment/fd_laptop^0')
end

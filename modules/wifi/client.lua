---@type table<string, WifiConnection>
local networks = {}

---@type string | nil
local connectedTo = nil

---@type boolean
local vpnEnabled = false

---@param data WifiNetwork
---@return boolean, string | nil
local function addNetwork(data)
    if not data.ssid then
        return false, 'SSID is required'
    end

    if not data.label then
        return false, 'Label is required'
    end

    if networks[data.ssid] then
        return false, 'SSID is already in use'
    end

    networks[data.ssid] = {
        ssid = data.ssid,
        label = data.label,
        password = data.password,
        connected = false
    }

    SendNUIMessage({
        action = 'addNetwork',
        data = data
    })

    return true, nil
end
exports('addNetwork', addNetwork)

---@param ssid string
---@return boolean, string | nil
local function removeNetwork(ssid)
    if not networks[ssid] then
        return false, 'Network not found'
    end

    networks[ssid] = nil

    if connectedTo == ssid then
        connectedTo = nil
    end

    SendNUIMessage({
        action = 'removeNetwork',
        data = ssid
    })

    return true, nil
end
exports('removeNetwork', removeNetwork)

---@return boolean | nil
local function isConnected()
    return connectedTo ~= nil
end
exports('isConnected', isConnected)

---@return WifiNetwork | nil
local function getConnectedNetwork()
    return networks[connectedTo]
end
exports('getConnectedNetwork', getConnectedNetwork)

---@param ssid string
---@param password? string
---@param sendNuiMessage? boolean
---@return boolean, string | nil
local function connectTo(ssid, password, sendNuiMessage)
    if type(sendNuiMessage) ~= 'boolean' then
        sendNuiMessage = true
    end

    if not networks[ssid] then
        return false, 'Network not found'
    end

    if networks[ssid].connected and connectedTo == ssid then
        return false, 'Already connected'
    end

    local network = networks[ssid]

    if password and network.password then
        if password ~= network.password then
            return false, 'Invalid password'
        end
    end

    for _, v in pairs(networks) do
        v.connected = false
    end

    network.connected = true
    connectedTo = ssid

    if sendNuiMessage then
        SendNUIMessage({
            action = 'connect',
            data = ssid
        })
    end

    return true, nil
end
exports('connectTo', connectTo)

---@param sendNuiMessage? boolean
---@return boolean, string | nil
local function disconnect(sendNuiMessage)
    if type(sendNuiMessage) ~= 'boolean' then
        sendNuiMessage = true
    end

    if not isConnected() then
        return false, 'Not connected'
    end

    for _, v in pairs(networks) do
        v.connected = false
    end

    connectedTo = nil

    if sendNuiMessage then
        SendNUIMessage({
            action = 'disconnect',
            data = network
        })
    end

    return true, nil
end
exports('disconnect', disconnect)

---@return boolean, string | nil
local function toggleVpn(status)
    if not isConnected() and not vpnEnabled then
        return false, 'Not connected to any network'
    end

    vpnEnabled = status

    return true, nil
end

---@return boolean
local function vpnStatus()
    return vpnEnabled
end
exports('vpnStatus', vpnStatus)

RegisterNuiCallback('toggleVpn', function(data, cb)
    local success, error = toggleVpn(data.status)

    cb({
        success = success,
        error = error
    })
end)

RegisterNUICallback('disconnect', function(_, cb)
    local success, error = disconnect(false)

    cb({
        success = success,
        error = error
    })
end)

RegisterNUICallback('connectTo', function(data, cb)
    local success, error = connectTo(data.ssid, data.password, false)

    cb({
        success = success,
        error = error
    })
end)

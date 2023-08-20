local v = require("semver")
local pretty = require("cc.pretty")

local clientVersion = v'0.1.0'
local timeout = 5

print("Rosa's Energy Client v" .. tostring(clientVersion))

peripheral.find("modem", rednet.open)



function getVersion(id)
    rednet.send(id, "getVersion", "energy_storage")

    local _, message = rednet.receive("energy_storage", timeout)

    if message == nil then
        error("Timeout")
    end

    pretty.pretty_print(message)

    local serverVersion = v(message.response)

    return serverVersion
end

function getEnergy(id)
    rednet.send(id, "getEnergy", "energy_storage")

    local _, message = rednet.receive("energy_storage", timeout)
    return message.response
end

function getName(id)
    rednet.send(id, "getName", "energy_storage")

    local _, message = rednet.receive("energy_storage", timeout)

    return message.response
end

function getEnergyReport()
    local hosts = getCompatibleHosts()

    for _, host in pairs(hosts) do
        local energy = getEnergy(host)
        local name = getName(host)
        print(string.format("Computer #%i [%s] - %s", host, name, tostring(energy)))
    end
end

function getCompatibleHosts()
    local hosts = {rednet.lookup("energy_storage")}

    local compatibleHosts = {}

    for _, host in pairs(hosts) do
        local serverVersion = getVersion(host)
        print("checking version "..tostring(serverVersion))
        if clientVersion ^ serverVersion then
            table.insert(compatibleHosts, host)
        end
    end

    return compatibleHosts
end

getEnergyReport()
print("end of report")

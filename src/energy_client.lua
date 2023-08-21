local v = require("semver")
local pretty = require("cc.pretty")

local clientVersion = v'0.1.0'
local timeout = 5

print("Rosa's Energy Client v" .. tostring(clientVersion))

peripheral.find("modem", rednet.open)

local function getReport(id)
    rednet.send(id, { method = "getReport" }, "energy_storage")

    local _, message = rednet.receive("energy_storage", timeout)

    if message == nil then
        error("Timeout")
    end

    return message.response
end

local function getVersion(id)
    rednet.send(id, { method = "getVersion" }, "energy_storage")

    local _, message = rednet.receive("energy_storage", timeout)

    if message == nil then
        error("Timeout")
    end

    return message.response
end

local function getCompatibleHosts()
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

local function reportAll()
    local hosts = getCompatibleHosts()

    for _, host in pairs(hosts) do
        local report = getReport(host)
        local percent = report.stored / report.capacity * 100
        print(string.format("%s: %d%%", report.name, percent))
    end
end



reportAll()
print("end of report")

return {
    getReport = getReport,
    getVersion = getVersion,
    getCompatibleHosts = getCompatibleHosts
}

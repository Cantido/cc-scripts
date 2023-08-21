local v = require("semver")
local pretty = require("cc.pretty")

local clientVersion = v'0.1.0'
local timeout = 5

print("Rosa's Energy Client v" .. tostring(clientVersion))

peripheral.find("modem", rednet.open)

local function callMethod(dest, name, args)
    local request = {
        method = name,
        version = tostring(clientVersion)
    }

    if args ~= nil then
        request.args = args
    end

    rednet.send(dest, request, "energy_storage")

    local _, response = rednet.receive("energy_storage", timeout)

    if response == nil then
        return { error = "Timeout" }
    end

    return response
end

local function getReport(id)
    return callMethod(id, "getReport")
end

local function ping(id)
    return callMethod(id, "ping")
end

local function getCompatibleHosts()
    local hosts = {rednet.lookup("energy_storage")}

    local compatibleHosts = {}

    for _, host in pairs(hosts) do
        local response = ping(host)
        if response.error == nil then
            table.insert(compatibleHosts, host)
        end
    end

    return compatibleHosts
end

local function reportAll()
    local hosts = getCompatibleHosts()

    for _, host in pairs(hosts) do
        local report = getReport(host)
        local percent = report.body.stored / report.body.capacity * 100
        print(string.format("%s: %d%%", report.computerName, percent))
    end
end



reportAll()
print("end of report")

return {
    getReport = getReport,
    getVersion = getVersion,
    getCompatibleHosts = getCompatibleHosts,
}

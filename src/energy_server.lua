local v = require("semver")
local pretty = require("cc.pretty")

local serverVersion = v'0.1.0'

print("Rosa's Energy Server v"..tostring(serverVersion))

peripheral.find("modem", rednet.open)
local storage = peripheral.wrap("top") or error("This program requires energy storage")


rednet.host("energy_storage", os.getComputerLabel())

while rednet.isOpen() do
    local id, message = rednet.receive("energy_storage")
    
    pretty.pretty_print(message)
    
          
    if message == "getEnergy" then
        print("Responding to getEnergy")
        local energy = storage.getEnergy()        
        local response = {
            query = "getEnergy",
            response = energy
        }
        rednet.send(id, response, "energy_storage")
    elseif message == "getName" then
        print("responding to getName")
        local response = {
            query = "getName",
            response = os.getComputerLabel()
        }
        rednet.send(id, response, "energy_storage")
    elseif message == "getVersion" then
        print("responding to getVersion")
        local response = {
            query = "getVersion",
            response = tostring(serverVersion)
        }
        
        pretty.pretty_print(response)
        rednet.send(id, response, "energy_storage")
    end
end

error("RedNet connection closed")

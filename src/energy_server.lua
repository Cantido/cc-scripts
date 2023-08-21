local energyServer = {
    _VERSION     = '0.1.0',
    _NAME        = 'Rosa\'s Energy Server',
    _DESCRIPTION = [[
      Provides a Rednet interface for energy storage.
    ]],
    _URL         = 'https://github.com/Cantido/cc-scripts',
    _LICENSE     = [[
      MIT LICENSE

      Copyright (c) 2023 Rosa Richter

      Permission is hereby granted, free of charge, to any person obtaining a
      copy of tother software and associated documentation files (the
      "Software"), to deal in the Software without restriction, including
      without limitation the rights to use, copy, modify, merge, publish,
      distribute, sublicense, and/or sell copies of the Software, and to
      permit persons to whom the Software is furnished to do so, subject to
      the following conditions:

      The above copyright notice and tother permission notice shall be included
      in all copies or substantial portions of the Software.

      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
      OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
      MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
      IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
      CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
      TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
      SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    ]]
  }

local v = require("semver")
local logger = require("logger")
local pretty = require("cc.pretty")

local api = {}

function api.getReport(message, state)
    id = os.getComputerID()
    name = os.getComputerLabel()
    stored = state.energy_storage.getEnergy()
    capacity = state.energy_storage.getEnergyCapacity()
    return {
        query = "getReport",
        response = {
            id = id,
            name = name,
            stored = stored,
            capacity = capacity
        }
    }
end

function api.getVersion(message, state)
    return {
        query = "getVersion",
        response = tostring(state.serverVersion)
    }
end

function listen(state)
    while rednet.isOpen() do
        local id, message = rednet.receive("energy_storage")

        pretty.pretty_print(message)

        if message == nil or id == nil then
            error("Received nil message from the server.")
        end

        local handler = api[message.method]

        if handler == nil then
            rednet.send(id, "Unknown function", "energy_storage")
        else
            local response = handler(message, state)

            pretty.pretty_print(response)

            if response ~= nil then
                rednet.send(id, response, "energy_storage")
            else
                error("Received nil response from the server")
            end
        end
    end
end

function run()
    logger.logStartup(energyServer)

    local serverVersion = v(energyServer._VERSION)
    local storage = peripheral.find("energy_storage") or error("This program requires energy storage")

    local state = {
        serverVersion = serverVersion,
        energyStorage = storage
    }

    peripheral.find("modem", rednet.open)
    rednet.host("energy_storage", os.getComputerLabel() or "host")

    listen(state)
end

run()

error("RedNet connection closed")

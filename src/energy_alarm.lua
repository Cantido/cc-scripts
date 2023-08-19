local energyAlarm = {
  _NAME        = 'Rosa\'s Induction Matrix Energy Alarm',
  _VERSION     = '1.0.0',
  _DESCRIPTION = [[
    Monitors the stored energy and fill rate of a Mekanism Induction Matrix,
    and sends an alert message to the chat if it is low and draining.
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

local logger = require("logger")

logger.logStartup(energyAlarm)

local chatname = os.computerLabel()
local interval = 300 -- five minutes

local matrix = peripheral.find("inductionPort") or error("Induction Matrix not connected. Make sure the computer is adjacent to an induction port.")
local chatbox = peripheral.find("chatBox") or error("Chat Box not connected")

local capacity = matrix.getMaxEnergy()
local previousStored = matrix.getEnergy()

logger.log("Waiting 10 seconds to check energy fill rate...")
os.sleep(10)
logger.log("Done waiting. Entering main loop.")

while true do
    local stored = matrix.getEnergy()
    local storedFrac = stored / capacity
    local isFull = storedFrac > 0.99
    local isFilling = (stored - previousStored) > 0

    if isFilling or isFull then
        logger.log("Matrix is filling or full, supressing chat.")
    else
        if storedFrac < 0.10 then
            chatbox.sendMessage("Induction Matrix has less than ten percent energy remaining, and it's still draining! Fix it quickly!", chatname)
        elseif storedFrac < 0.50 then
            chatbox.sendMessage("Induction Matrix is at less than fifty percent capacity and draining, is the power grid overloaded?", chatname)
        end
    end

    sleep(interval)
end

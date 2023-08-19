local logger = {
  _VERSION     = '1.0.0',
  _NAME        = 'Rosa's Reactor Control Program',
  _DESCRIPTION = [[
    Adjusts a BiggerReactor reactor's control rods to maintain power in storage.
    When stored power is above 80%, the reactor is slowed down slightly,
    and when it is below 20%, the reactor is sped up.
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

logger.log("Rosa's Reactor Control Program is now active")

local reactor = peripheral.find("BiggerReactors_Reactor")

function getFillLevel(reactor)
    local battery = reactor.battery()
    local coolantTank = reactor.coolantTank()
    
    if battery ~= nil then
        local capacity = battery.capacity()
        return battery.stored() / capacity
    elseif coolantTank ~= nil then
        local capacity = coolantTank.capacity()
        return coolantTank.hotFluidAmount() / capacity
    else
        error("Battery and coolant tank were both nil.")
    end
end

function changeControlRods(diff)
    local level = reactor.getControlRod(0).level()
    local newLevel = level + diff
    reactor.setAllControlRodLevels(newLevel)
end
    
while reactor.connected() do
    if reactor.active() then
        local fractionStored = getFillLevel(reactor)

        if fractionStored > 0.80 then
            changeControlRods(0.1)            
        elseif fractionStored < 0.20 then
            changeControlRods(-0.1)
        end
        
        logger.log(string.format("Control rods currently at %f%%", reactor.getControlRod(0).level()))
    else
        logger.log("Reactor is turned off, skipping battery check")
    end
    
    os.sleep(10)
end


error("Reactor not connected")

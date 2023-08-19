local rcp = {
  _VERSION     = '1.0.0',
  _NAME        = 'Rosa\'s Reactor Control Program',
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

settings.define("rcp.threshold.high", {
    description = [[
        Fraction of the reactor's energy or coolant storage. If the reactor
        fills up above this amount, this program will attempt to slow down
        the reactor. Must be between 0 and 1, and must be higher than
        the `rcp.threshold.low` setting.
    ]],
    default = 0.80,
    type = number
})

settings.define("rcp.threshold.low", {
    description = [[
        Fraction of the reactor's energy or coolant storage. If the reactor
        drains below this amount, this program will attempt to speed up
        the reactor. Must be between 0 and 1, and must be lower than
        the `rcp.threshold.high` setting.
    ]],
    default = 0.20,
    type = number
})

settings.define("rcp.adjustmentAmount", {
    description = [[
        Amount to extend or retract the control rods when an adjustment
        is made. Increasing this value means that the reactor will react more
        quickly to adjustments, but power storage will fluctuate more rapidly
        and is less likely to maintain a steady value. Must be greater than 0.
    ]],
    default = 0.1,
    type = number
})

settings.define("rcp.checkInterval", {
    description = [[
        How often to check the reactor energy or coolant storage, in seconds.
        Must be greater than 0.
    ]],
    default = 10,
    type = number
})

local highThreshold = settings.get("rcp.threshold.high")
local lowThreshold = settings.get("rcp.threshold.low")
local adjustmentAmount = settings.get("rcp.adjustmentAmount")
local checkInterval = settings.get("rcp.checkInterval")

if lowThreshold <= 0 and lowThreshold >= 1 then
    error("`rcp.threshold.low` must be between 0 and 1.")
end

if highThreshold <= 0 and highThreshold >= 1 then
    error("`rcp.threshold.high` must be between 0 and 1.")
end

if lowThreshold > highThreshold then
    error("`rcp.threshold.low` must be lower than or equal to `rcp.threshold.high`.")
end

if adjustmentAmount <= 0 then
    error("`rcp.adjustmentAmount` must be greater than 0.")
end

if checkInterval <= 0 then
    error("`rcp.checkInterval` must be greater than 0.")
end

logger.logStartup(rcp)

local reactor = peripheral.find("BiggerReactors_Reactor") or error("This program requires a BiggerReactors reactor.")

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

        if fractionStored > highThreshold then
            changeControlRods(adjustmentAmount)
        elseif fractionStored < lowThreshold then
            changeControlRods(-adjustmentAmount)
        end

        logger.log(string.format("Control rods currently at %f%%", reactor.getControlRod(0).level()))
    else
        logger.log("Reactor is turned off, skipping battery check")
    end

    os.sleep(checkInterval)
end


error("Reactor not connected")

local refinedColonies = {
  _VERSION     = '1.0.0',
  _NAME        = 'Rosa\'s Refined Colonies Program',
  _DESCRIPTION = [[
    Bridges a MineColonies warehouse to a Refined Storage network.

    When an item is requested by MineColonies, this program will check the
    Refined Storage network for that item. If there is enough of it in storage
    to fulfill the request, the items are moved from Refined Storage into the
    MineColonies warehouse. If there is not enough of the requested item in
    Refined Storage, but the item is craftable via Refined Storage, then
    the missing items will be crafted and then moved.

   At the end of each in-game day, this program will print a report to chat
   describing the requests that were fulfilled.
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
local pretty = require("cc.pretty")
local ccstrings = require("cc.strings")

settings.define("refcol.interval", {
    description = [[
        The number of seconds to wait between fulfilling requests.
        If you set this too low, then the system may craft too many items
        requested by the colony if autocrafting is taking too long.
        Must be greater than 0.
    ]],
    default = 60,
    type = number
})

settings.define("refcol.report.radius", {
    description = [[
        The radius, in blocks, that this program should broadcast the daily
        request report. Set this to a range where players within the colony
        can see the report, but where players outside the colony won't get
        spammed. Must be greater than 0.
    ]],
    default = 200,
    type = number
})

local interval = settings.get("refcol.interval")
-- TODO: pull the name of the colony instead of hard-coding
local chatname = "Prarietown"
local chatrange = settings.get("refcol.report.radius")

if interval <= 0 then
    error("`refcol.interval` must be greater than 0.")
end

if chatrange <= 0 then
    error("`refcol.report.radius` must be greater than 0.")
end

local colony = peripheral.find("colonyIntegrator") or error("This program requires a MineColonies integration peripheral.")
local storage = peripheral.find("rsBridge") or error("This program requires a Refined Storage integration peripheral.")
local chatbox = peripheral.find("chatBox") or error("This program requires a Chat Box peripheral.")

local dailyItemReport = {
    itemCounts = {},
    fulfilledRequests = {}
}

-- setting this to today will mean that
-- the report won't happen til midnight tonight
local previousDailyReportDay = os.day()

function fulfillRequest(request)
    local mcItem = request.items[1]
    local rsItem = storage.getItem({name = mcItem.name})
    local isCraftable = storage.isItemCraftable({name = mcItem.name})
    local craftedAmount = 0
    local craftingSuccess

    local desiredAmount = request.count
    local storedAmount = 0
    local exportedAmount = 0

    if rsItem ~= nil then
        storedAmount = rsItem.amount
    end

    if isCraftable then
        local countToCraft = desiredAmount - storedAmount

        if countToCraft > 0 then
            craftingSuccess = storage.craftItem({name = mcItem.name, count = countToCraft})

            if craftingSuccess then
                while storage.isItemCrafting(mcItem.name) do
                    os.sleep(1)
                end

                storedAmount = storage.getItem({name = mcItem.name}).amount
                craftedAmount = countToCraft
            end
        end
    end

    if desiredAmount <= storedAmount then
        exportedAmount = storage.exportItem({name = mcItem.name, count = desiredAmount}, "top")
    end

    return {
        requestId = request.id,
        name = mcItem.name,
        isFulfilled = (desiredAmount == exportedAmount),
        displayName = mcItem.displayName,
        desiredAmount = desiredAmount,
        storedAmount = storedAmount,
        craftedAmount = craftedAmount,
        exportedAmount = exportedAmount
    }
end

function printReport(reports)
    local fulfilledNames = {}
    local unfulfilledNames = {}


    for _, row in pairs(reports) do
        local fulfilled = row.desiredAmount == row.exportedAmount

        local displayName = row.name
        displayName = ccstrings.ensure_width(displayName, 50)
        displayName = string.format("%ix %s", row.desiredAmount, displayName)

        if row.craftedAmount > 0 then
            displayName = string.format("%s (crafted %i)", displayName, row.craftedAmount)
        end

        if fulfilled then
            table.insert(fulfilledNames, displayName)
        else
            table.insert(unfulfilledNames, displayName)
        end
    end

    logger.log(string.format("Checking requests at %s...", os.date("!%c")))

    if #fulfilledNames > 0 then
        logger.log("- Fulfilled requests:")
        for _, name in pairs(fulfilledNames) do
          logger.log("  - " .. name)
        end
    else
        logger.log("- No fulfilled requests")
    end

    if #unfulfilledNames > 0 then
        logger.log("- Unfulfilled requests:")
        for _, name in pairs(unfulfilledNames) do
            logger.log("  - " .. name)
        end
    else
        logger.log("- No unfulfilled requests")
    end
end

function addToDailyReport(report)
    local currentCount = dailyItemReport.itemCounts[report.name] or 0

    dailyItemReport.itemCounts[report.name] = currentCount + report.exportedAmount
    dailyItemReport.fulfilledRequests[report.requestId] = true
end

function printDailyReport()
    local message = {}

    table.insert(message, "Time for the daily Refined Colonies crafting report!\n")

    local fulfilledCount = 0;

    for _, _ in pairs(dailyItemReport.fulfilledRequests) do
        fulfilledCount = fulfilledCount + 1
    end

    if fulfilledCount > 0 then
        table.insert(message, string.format("Today, I fulfilled %i requests and moved a total of:\n", fulfilledCount))
        for name, count in pairs(dailyItemReport.itemCounts) do
            table.insert(message, {
                text = string.format("- %ix %s\n", count, name),
                hoverEvent = {
                    action = "show_item",
                    contents = {
                        id = name,
                        count = count
                    }
                }
            })
        end
    else
        table.insert(message, "No requests were fulfilled today :(")
    end

    message = textutils.serializeJSON(message)
    chatbox.sendFormattedMessage(message, chatname, nil, nil, chatrange)
end

logger.logStartup(refinedColonies)

while true do
    local reports = {}
    for _, request in pairs(colony.getRequests()) do
        local report = fulfillRequest(request)
        if report.isFulfilled then
            addToDailyReport(report)
        end
        table.insert(reports, report)
    end

    printReport(reports)

    local today = os.day()
    if previousDailyReportDay < today then
        printDailyReport()
        previousDailyReportDay = today
        dailyItemReport = {
            itemCounts = {},
            fulfilledRequests = {}
        }
    end

    os.sleep(interval)
end

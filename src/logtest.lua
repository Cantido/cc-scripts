local logger = require("logger")

logger.log("Success!")

local dummyProgram = {
  _NAME = 'Dummy program',
  _VERSION = '1.0.0'
}

logger.logStartup(dummyProgram)

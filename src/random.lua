local random = {
  _VERSION     = '1.0.0',
  _NAME        = 'Rosa\'s Pseudorandom Number Generator',
  _DESCRIPTION = 'Generates pseudorandom numbers.',
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

local modulus = 0x7fffffff
local multiplier = 48721

local R = {}

R.state = os.epoch() % modulus

function R.nextRandom(max)
    R.state = R.state * multiplier % modulus

    if max == nil then
        return R.state
    else
        return R.state % max
    end
end

return R

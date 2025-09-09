local Class = cometreq("util.class") --- @type comet.util.Class

--- @class comet.modules.keyboard
local keyboard = Class("comet.modules.keyboard")

local list = {
    "none",
    "a",
    "b",
    "c",
    "d",
    "e",
    "f",
    "g",
    "h",
    "i",
    "j",
    "k",
    "l",
    "m",
    "n",
    "o",
    "p",
    "q",
    "r",
    "s",
    "t",
    "u",
    "v",
    "w",
    "x",
    "y",
    "z",
    "space",
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "!",
    "@",
    "#",
    "$",
    "%",
    "^",
    "&",
    "*",
    "(",
    ")",
    "-",
    "_",
    "+",
    "=",
    "`",
    "~",
    "{",
    "}",
    "|",
    "[",
    "]",
    "\\",
    ":",
    ";",
    "'",
    '"',
    "<",
    ">",
    "?",
    ",",
    ".",
    "/",
    "kp0",
    "kp1",
    "kp2",
    "kp3",
    "kp4",
    "kp5",
    "kp6",
    "kp7",
    "kp8",
    "kp9",
    "kp.",
    "kp/",
    "kp-",
    "kp*",
    "kp+",
    "kpenter",
    "up",
    "down",
    "right",
    "left",
    "home",
    "end",
    "pageup",
    "pagedown",
    "insert",
    "backspace",
    "tab",
    "clear",
    "return",
    "delete",
    "f1",
    "f2",
    "f3",
    "f4",
    "f5",
    "f6",
    "f7",
    "f8",
    "f9",
    "f10",
    "f11",
    "f12",
    "f13",
    "f14",
    "f15",
    "f16",
    "f17",
    "f18",
    "numlock",
    "capslock",
    "scrolllock",
    "rshift",
    "lshift",
    "rctrl",
    "lctrl",
    "ralt",
    "lalt",
    "rgui",
    "lgui",
    "mode",
    "www",
    "mail",
    "calculator",
    "computer",
    "appsearch",
    "apphome",
    "appback",
    "appforward",
    "apprefresh",
    "appbookmarks",
    "pause",
    "escape",
    "help",
    "printscreen",
    "sysreq",
    "menu",
    "application",
    "power",
    "currencyunit",
    "undo",
}

function keyboard:__init__()
    --- @type table<love.KeyConstant, boolean>
    self._justPressed = {} --- @protected

    --- @type table<love.KeyConstant, boolean>
    self._justReleased = {} --- @protected

    --- @type table<love.KeyConstant, boolean>
    self._pressed = {} --- @protected

    for i = 1, #list do
        self._justPressed[list[i]] = false
        self._justReleased[list[i]] = false
        self._pressed[list[i]] = false
    end
end

--- @return love.KeyConstant[]
function keyboard:getKeyList()
    return list
end

function keyboard:handleEvent(e)
    if e.type ~= "key" or e.isRepeat then
        return
    end
    if e.pressed then
        self._justPressed[e.key] = true
    else
        self._justReleased[e.key] = true
    end
    self._pressed[e.key] = e.pressed
end

function keyboard:update()
    self._justPressed = {}
    self._justReleased = {}
end

--- @param key love.KeyConstant
--- @return boolean
function keyboard:wasJustPressed(key)
    return self._justPressed[key]
end

--- @param key love.KeyConstant
--- @return boolean
function keyboard:wasJustReleased(key)
    return self._justReleased[key]
end

--- @param key love.KeyConstant
--- @return boolean
function keyboard:isPressed(key)
    return self._pressed[key]
end

--- @param key love.KeyConstant
--- @return boolean
function keyboard:isReleased(key)
    return not self._pressed[key]
end

return keyboard
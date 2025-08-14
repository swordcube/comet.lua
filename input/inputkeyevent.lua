---
--- @class comet.input.InputKeyEvent
--- 
--- Basic key input event
--- 
--- Not an actual class since this is so simple that it's just unnecessary
---
local InputKeyEvent = {
    type = nil, --- @type "key"
    key = nil, --- @type love.KeyConstant
    pressed = nil --- @type boolean
}

--- @param  key      love.KeyConstant
--- @param  pressed  boolean
--- @return comet.input.InputKeyEvent
function InputKeyEvent:new(key, pressed)
    return {type = "key", key = key, pressed = pressed}
end
return InputKeyEvent
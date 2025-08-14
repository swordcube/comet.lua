---
--- @class comet.input.InputMouseButtonEvent
--- 
--- Basic mouse button input event
--- 
--- Not an actual class since this is so simple that it's just unnecessary
---
local InputMouseButtonEvent = {
    type = nil, --- @type "mousebutton"
    button = nil, --- @type "left"|"center"|"right"
    x = nil, --- @type number
    y = nil, --- @type number
    pressed = nil --- @type boolean
}

--- @param  button   "left"|"center"|"right"
--- @param  x        number
--- @param  y        number
--- @param  pressed  boolean
--- @return comet.input.InputMouseButtonEvent
function InputMouseButtonEvent:new(button, x, y, pressed)
    return {type = "mousebutton", button = button, x = x, y = y, pressed = pressed}
end
return InputMouseButtonEvent
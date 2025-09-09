---
--- @class comet.input.InputMouseWheelEvent
--- 
--- Basic mouse button input event
--- 
--- Not an actual class since this is so simple that it's just unnecessary
---
local InputMouseWheelEvent = {
    type = nil, --- @type "mousemove"

    --- Amount of horizontal mouse movement.
    --- Negative means movement towards the left, positive means movement towards the right
    x = nil, --- @type number

    --- Amount of vertical mouse movement.
    --- Negative means upwards movement, positive means downwards movement
    y = nil, --- @type number
}

--- @return comet.input.InputMouseWheelEvent
function InputMouseWheelEvent:new(x, y)
    return {type = "mousewheel", x = x, y = y}
end
return InputMouseWheelEvent
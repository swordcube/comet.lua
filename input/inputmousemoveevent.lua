---
--- @class comet.input.InputMouseMoveEvent
--- 
--- Basic mouse button input event
--- 
--- Not an actual class since this is so simple that it's just unnecessary
---
local InputMouseMoveEvent = {
    type = nil, --- @type "mousemove"
    x = nil, --- @type number
    y = nil, --- @type number
    deltaX = nil, --- @type number
    deltaY = nil, --- @type number
}

--- @param button "left"|"center"|"right"
--- @return comet.input.InputMouseMoveEvent
function InputMouseMoveEvent:new(x, y, dx, dy)
    return {type = "mousemove", x, y, deltaX = dx, deltaY = dy}
end
return InputMouseMoveEvent
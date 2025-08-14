---
--- @class comet.input.InputEvent
--- 
--- Basic input event, meant to be "extended" by other input events
--- 
--- Not an actual class since this is so simple that it's just unnecessary
---
local InputEvent = {
    type = "unknown" --- @type "key"|"mouse"|"gamepad"
}
return InputEvent
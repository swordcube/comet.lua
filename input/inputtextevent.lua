---
--- @class comet.input.InputTextEvent
--- 
--- Basic key input event
--- 
--- Not an actual class since this is so simple that it's just unnecessary
---
local InputTextEvent = {
    type = nil, --- @type "text"
    text = nil, --- @type string
}

--- @param  text     love.KeyConstant
--- @return comet.input.InputTextEvent
function InputTextEvent:new(text)
    return {type = "text", text = text}
end
return InputTextEvent
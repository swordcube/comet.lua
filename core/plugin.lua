--- @class comet.core.Plugin : comet.util.Class
local Plugin = Class("Plugin", ...)

function Plugin:__init__()
end

function Plugin:update(dt) end

function Plugin:draw() end

function Plugin:input(e) end

return Plugin
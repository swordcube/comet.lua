local Plugin = cometreq("core.plugin") --- @type comet.core.Plugin

--- @class comet.core.TweenManager : comet.core.Plugin
local TweenManager = Plugin:subclass("TweenManager")
TweenManager.static.instance = nil

function TweenManager:__init__()
    --- using this as a group lol
    self.tweens = Object:new() --- @type comet.core.Object
    TweenManager.static.instance = self
end

function TweenManager:update(dt)
    if self.tweens._update then
        self.tweens:_update(dt)
    end
end

return TweenManager
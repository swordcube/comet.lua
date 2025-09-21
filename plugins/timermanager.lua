local Plugin = cometreq("core.plugin") --- @type comet.core.Plugin

--- @class comet.plugins.TimerManager : comet.core.Plugin
local TimerManager = Plugin:subclass("TimerManager", ...)
TimerManager.static.instance = nil

function TimerManager:__init__()
    --- using this as a group lol
    self.timers = Object:new() --- @type comet.core.Object

    if not TimerManager.instance then
        TimerManager.instance = self
    end
end

function TimerManager:clear()
    self.timers.children = {}
end

function TimerManager:update(dt)
    if self.timers._update then
        self.timers:_update(dt)
    end
end

return TimerManager
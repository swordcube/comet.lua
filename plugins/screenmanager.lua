local Plugin = cometreq("core.plugin") --- @type comet.core.Plugin

--- @class comet.plugins.ScreenManager : comet.core.Plugin
local ScreenManager = Plugin:subclass("ScreenManager")
ScreenManager.static.instance = nil

function ScreenManager:__init__()
    self.current = nil --- @type comet.core.Screen
    self.pending = nil --- @type comet.core.Screen
    ScreenManager.static.instance = self
end

--- @param newScreen comet.core.Screen | function
function ScreenManager.switchTo(newScreen)
    ScreenManager.static.instance.pending = newScreen
end
ScreenManager.static.switchTo = ScreenManager.switchTo

function ScreenManager:update(dt)
    if self.current then
        self.current:_update(dt)
    end
    if self.pending then
        self:_switchTo(self.pending)
    end
end

--- @protected
--- @param newScreen comet.core.Screen | function
function ScreenManager:_switchTo(newScreen)
    if self.current then
        self.current:exit()
        self.current = nil
    end
    local new = nil --- @type comet.core.Screen
    if type(newScreen) == "function" then
        new = newScreen()
    else
        new = newScreen
    end
    TimerManager.instance:clear()
    TweenManager.instance:clear()

    self.current = new
    self.current:enter()
    
    Log.verbose("Switched to screen: " .. new.class.name)
    self.pending = nil
end

return ScreenManager
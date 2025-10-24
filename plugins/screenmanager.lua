local Plugin = cometreq("core.plugin") --- @type comet.core.Plugin

--- @class comet.plugins.ScreenManager : comet.core.Plugin
local ScreenManager = Plugin:extend("ScreenManager", ...)
ScreenManager.instance = nil

function ScreenManager:__init__()
    self.current = nil --- @type comet.core.Screen
    self.pending = nil --- @type comet.core.Screen
    ScreenManager.instance = self
end

--- @param newScreen comet.core.Screen | function
function ScreenManager.switchTo(newScreen)
    local new = nil --- @type comet.core.Screen
    if type(newScreen) == "function" then
        new = newScreen()
        new._constructor = newScreen
    else
        new = newScreen
    end
    local current = ScreenManager.instance.current
    if current then
        current:startOutro(function()
            ScreenManager.instance.pending = new
        end)
    else
        ScreenManager.instance.pending = new
    end
end

function ScreenManager:update(dt)
    if self.current then
        self.current:_update(dt)
    end
    if self.pending then
        self:_switchScreen()
    end
end

--- @protected
--- @param newScreen comet.core.Screen | function
function ScreenManager:_switchScreen()
    if self.current then
        self.current:exit()
        self.current:destroy()
        self.current = nil
    end
    collectgarbage()
    comet.signals.preScreenSwitch:emit(self.pending)
    
    for i = 1, #comet.mixer.sounds.children do
        local sound = comet.mixer.sounds.children[i] --- @type comet.mixer.Sound
        if sound then
            sound:destroy()
        end
    end
    TimerManager.instance:clear()
    TweenManager.instance:clear()
    
    collectgarbage()
    
    local new = self.pending
    self.current = new
    Log.verbose("Switched to screen: " .. new.class.name)

    new:enter()
    new:startIntro()
    new:postEnter()
    
    collectgarbage()

    comet.signals.postScreenSwitch:emit()
    self.pending = nil

    collectgarbage()
end

return ScreenManager
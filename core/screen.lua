--- @class comet.core.Screen : comet.core.Object
local Screen = Object:subclass("Screen", ...)

function Screen:enter() end
function Screen:postEnter() end
function Screen:exit() end

--- Starts an outro transition for this screen.
--- 
--- Calling `onOutroComplete()` will end the outro transition
--- and immediately switch to the pending screen.
--- 
--- @param onOutroComplete function
function Screen:startOutro(onOutroComplete)
    if onOutroComplete then
        onOutroComplete()
    end
end

--- Starts an intro transition for this screen.
--- Called just before `postEnter()`.
function Screen:startIntro() end

--- @param newScreen comet.core.Screen
function Screen:switchTo(newScreen)
    ScreenManager.switchTo(newScreen)
end

--- You should only need this if you NEED the screen to instantly be switched
--- to the new screen, otherwise use `switchTo`, which will wait until
--- the current screen is finished updating to switch.
--- 
--- The current screen's outro will not be played when this is called.
--- 
--- @param newScreen comet.core.Screen|function
function Screen:forceSwitchTo(newScreen)
    local new = nil --- @type comet.core.Screen
    if type(newScreen) == "function" then
        new = newScreen()
    else
        new = newScreen
    end
    local sm = ScreenManager.instance --- @type comet.plugins.ScreenManager
    sm.pending = new -- make this the pending screen
    sm:_switchScreen() -- then force the switch
end

return Screen
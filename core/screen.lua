--- @class comet.core.Screen : comet.core.Object
local Screen = Object:subclass("Screen")

function Screen:enter() end
function Screen:exit() end

--- @param newScreen comet.core.Screen
function Screen:switchTo(newScreen)
    ScreenManager.switchTo(newScreen)
end

--- You should only need this if you NEED the screen to instantly be switched
--- to the new screen, otherwise use `switchTo`, which will wait until
--- the current screen is finished updating to switch.
--- @param newScreen comet.core.Screen
function Screen:forceSwitchTo(newScreen)
    ScreenManager.instance:_switchTo(newScreen)
end

return Screen
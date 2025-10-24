--- @class comet.core.Screen : comet.core.Object
local Screen, super = Object:extend("Screen", ...)

function Screen:__init__()
    super.__init__(self)

    --- Whether or not to keep updating this screen
    --- when a sub screen is opened.
    self.persistentUpdate = true

    --- Whether or not to keep drawing this screen
    --- when a sub screen is opened.
    self.persistentDraw = true

    --- @type comet.core.Screen?
    self._subScreen = nil --- @protected

    --- @type boolean
    self._isSubScreen = false --- @protected

    --- @type function?
    self._constructor = nil --- @protected
end

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

function Screen:openSubScreen(newScreen)
    if self._subScreen then
        self._subScreen:close()
    end
    local new = nil --- @type comet.core.Screen
    if type(newScreen) == "function" then
        new = newScreen()
    else
        new = newScreen
    end
    self._subScreen = new
    self._subScreen._isSubScreen = true
    self._subScreen.parent = self

    new:enter()
    new:startIntro()
    new:postEnter()
end

function Screen:getSubScreen()
    return self._subScreen
end

--- Closes this sub screen and removes it from it's parent screen
--- 
--- If this is not a sub screen, this will do nothing
function Screen:close()
    if not self._isSubScreen then
        return
    end
    if self.parent then
        self.parent._subScreen = nil
        self.parent = nil
    end
    self:exit()
    self:destroy()
end

function Screen:canUpdate()
    return self.persistentUpdate or not self._subScreen
end

function Screen:_update(dt)
    if self:canUpdate() then
        super._update(self, dt)
    end
    if self._subScreen and self._subScreen.exists then
        self._subScreen:_update(dt)
    end
end

function Screen:_input(e)
    if self.persistentUpdate or not self._subScreen then
        super._input(self, e)
    end
    if self._subScreen and self._subScreen.exists then
        self._subScreen:_input(e)
    end
end

function Screen:_draw()
    if self.persistentDraw or not self._subScreen then
        super._draw(self)
    end
    if self._subScreen and self._subScreen.exists and self._subScreen.visible then
        self._subScreen:_draw()
    end
end

return Screen
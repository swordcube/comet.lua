--- @class comet.core.SplashScreen : comet.core.Screen
local MouseOverlapTest = Screen:subclass("MouseOverlapTest", ...) --- @type comet.core.Screen

function MouseOverlapTest:enter()
    self.camera = Camera:new() --- @type comet.gfx.Camera
    self.camera.zoom:set(2, 2)
    self.camera:setBackgroundColor(Color.GRAY)
    self:addChild(self.camera)
    
    self.object = Rectangle:new(0, 0, 240, 240) --- @type comet.gfx.Rectangle
    self.object:screenCenter("xy")
    self.object:setColor(Color.CYAN)
    self.camera:addChild(self.object)
end

function MouseOverlapTest:update(dt)
    if comet.mouse:overlaps(self.object) then
        self.object:setColor(Color.RED)
    else
        self.object:setColor(Color.CYAN)
    end
end

return MouseOverlapTest
--- @class comet.gfx.Camera : comet.gfx.Object2D
--- A basic object for displaying static Cameras.
local Camera, super = Object2D:subclass("Camera")

local math = math -- Faster access with local variable

function Camera:__init__()
    super.__init__(self)

    -- Set position to center by default
    self.position:set(comet.getDesiredWidth() / 2, comet.getDesiredHeight() / 2)
    
    --- Size of this camera
    self.size = Vec2:new(comet.getDesiredWidth(), comet.getDesiredHeight()) --- @type comet.math.Vec2

    --- Zoom of this camera
    self.zoom = Vec2:new(1.0, 1.0) --- @type comet.math.Vec2

    --- Non-functional on Cameras, use `zoom` instead.
    self.scale = nil
end

--- Returns the unscaled width of this camera.
--- @return number
function Camera:getOriginalWidth()
    return self.size.x
end

--- Returns the unscaled height of this camera.
--- @return number
function Camera:getOriginalHeight()
    return self.size.y
end

--- Returns the current width of this camera.
--- @return number
function Camera:getWidth()
    return self.size.x * math.abs(self.zoom.x)
end

--- Returns the current height of this camera.
--- @return number
function Camera:getHeight()
    return self.size.y * math.abs(self.zoom.y)
end

--- Returns the transform of this camera
--- @return love.Transform
function Camera:getTransform()
    local transform = self._transform:reset()
    transform = self:getParentTransform(transform)

    -- position
    transform:translate(self.position.x - (self:getWidth() * 0.5), self.position.y - (self:getHeight() * 0.5))

    -- origin
    local ox, oy = self:getWidth() * self.origin.x, self:getHeight() * self.origin.y
    transform:translate(ox, oy)
    transform:rotate(math.rad(self.rotation))
    transform:translate(-ox, -oy)

    -- scale
    transform:scale(self.zoom.x, self.zoom.y)
    
    return transform
end

function Camera:destroy()
    super.destroy(self)
    self.size = nil
    self.zoom = nil
end

return Camera
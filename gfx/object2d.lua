--- @class comet.gfx.Object2D : comet.core.Object
local Object2D, super = Object:subclass("Object2D")

local lmath = love.math

function Object2D:__init__(x, y)
    super.__init__(self)

    --- Position of this image
    self.position = Vec2:new(x and x or 0.0, y and y or 0.0) --- @type comet.math.Vec2
    
    -- Rotation of this image (in degrees)
    self.rotation = 0.0
    
    --- Rotation origin of this image (from 0 to 1) (does not affect position)
    self.origin = Vec2:new(0.5, 0.5) --- @type comet.math.Vec2
    
    --- Scale multiplier of this image
    self.scale = Vec2:new(1, 1) --- @type comet.math.Vec2
    
    --- @type love.Transform
    self._transform = lmath.newTransform() --- @protected
end

--- @param  transform  love.Transform
function Object2D:getParentTransform(transform)
    if transform == nil then
        transform = lmath.newTransform()
    end
    if self.parent and self.parent:isInstanceOf(Object2D) then
        transform:apply(self.parent:getTransform())
    end
    return transform
end

--- Rotates this object by a given amount of degrees
--- @param by number
function Object2D:rotate(by)
    self.rotation = self.rotation + by
end

--- Returns the transform of this object
--- @return love.Transform
function Object2D:getTransform()
    local transform = self._transform:reset()
    transform = self:getParentTransform(transform)

    transform:translate(self.position.x, self.position.y)
    transform:rotate(math.rad(self.rotation))
    transform:scale(self.scale.x, self.scale.y)
    
    return transform
end

return Object2D
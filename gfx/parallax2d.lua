--- @class comet.gfx.Parallax2D : comet.gfx.Object2D
--- A basic object meant for displaying child objects at different scroll factors.
local Parallax2D, super = Object2D:subclass("Parallax2D", ...)

function Parallax2D:__init__(x, y)
    super.__init__(self, x, y)

    self.scrollFactor = Vec2:new(1, 1) --- @type comet.math.Vec2
end

--- Returns the transform of this object
--- @return love.Transform
function Parallax2D:getTransform()
    local transform = self._transform:reset()
    transform = self:getParentTransform(transform)

    transform:translate(self.position.x + self.offset.x, self.position.y + self.offset.y)
    local p = self.parent
    local camera = nil --- @type comet.gfx.Camera
    while p do
        if p and p:isInstanceOf(Camera) then
            --- @cast p comet.gfx.Camera
            camera = p
            break
        end
        p = p.parent
    end
    if camera then
        transform:translate(camera.scroll.x * (1 - self.scrollFactor.x), camera.scroll.y * (1 - self.scrollFactor.y))
    end
    transform:rotate(math.rad(self.rotation))
    transform:scale(self.scale.x, self.scale.y)
    
    return transform
end

return Parallax2D
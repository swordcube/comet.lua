--- @class comet.gfx.AnimationFrame : comet.util.Class
--- A basic class for storing an animation frame.
--- Meant to be used in `FrameCollection` objects.
local AnimationFrame = Class("AnimationFrame", ...)

---@param name string
---@param texture comet.gfx.Texture
---@param x number
---@param y number
---@param offsetX number
---@param offsetY number
---@param width number
---@param height number
---@param rotation number
function AnimationFrame:__init__(name, texture, x, y, offsetX, offsetY, width, height, rotation)
    self.name = name

    self.texture = texture --- @type comet.gfx.Texture
    self.texture:reference()

    self.position = Vec2:new(x, y) --- @type comet.math.Vec2
    self.offset = Vec2:new(offsetX, offsetY) --- @type comet.math.Vec2
    self.width = width --- @type number
    self.height = height --- @type number
    self.rotation = rotation --- @type number

    self.quad = love.graphics.newQuad(x, y, width, height, texture:getWidth(), texture:getHeight()) --- @type love.Quad
end

function AnimationFrame:updateQuad()
    self.quad:setViewport(self.position.x, self.position.y, self.width, self.height, self.texture:getWidth(), self.texture:getHeight())
end

function AnimationFrame:destroy()
    if self.quad then
        self.quad:release()
        self.quad = nil
    end
    if self.texture then
        self.texture:dereference()
        self.texture = nil
    end
end

return AnimationFrame
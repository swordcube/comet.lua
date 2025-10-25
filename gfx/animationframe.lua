--- @class comet.gfx.AnimationFrame : comet.util.Class
--- A basic class for storing an animation frame.
--- Meant to be used in `FrameCollection` objects.
local AnimationFrame = Class:extend("AnimationFrame", ...)

---@param name string
---@param texture comet.gfx.Texture
---@param x number
---@param y number
---@param offsetX number
---@param offsetY number
---@param clipWidth number
---@param clipHeight number
---@param frameWidth number
---@param frameHeight number
---@param rotation number
function AnimationFrame:__init__(name, texture, x, y, offsetX, offsetY, clipWidth, clipHeight, frameWidth, frameHeight, rotation)
    self.name = name

    self.texture = texture --- @type comet.gfx.Texture
    self.texture:reference()

    self.position = Vec2:new(x, y) --- @type comet.math.Vec2
    self.offset = Vec2:new(offsetX, offsetY) --- @type comet.math.Vec2

    self.clipWidth = clipWidth --- @type number
    self.clipHeight = clipHeight --- @type number

    self.frameWidth = tonumber(frameWidth or clipWidth) --- @type number
    self.frameHeight = tonumber(frameHeight or clipHeight) --- @type number

    self.rotation = rotation or 0.0 --- @type number

    self.quad = love.graphics.newQuad(x, y, clipWidth, clipHeight, texture:getWidth(), texture:getHeight()) --- @type love.Quad
end

function AnimationFrame:updateQuad()
    self.quad:setViewport(self.position.x, self.position.y, self.clipWidth, self.clipHeight, self.texture:getWidth(), self.texture:getHeight())
end

function AnimationFrame:getUV()
    return self.position.x / self.texture:getWidth(), self.position.y / self.texture:getHeight(), self.clipWidth / self.texture:getWidth(), self.clipHeight / self.texture:getHeight()
end

function AnimationFrame:getUVX()
    return self.position.x / self.texture:getWidth()
end

function AnimationFrame:getUVY()
    return self.position.y / self.texture:getHeight()
end

function AnimationFrame:getUVWidth()
    return self.clipWidth / self.texture:getWidth()
end

function AnimationFrame:getUVHeight()
    return self.clipHeight / self.texture:getHeight()
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
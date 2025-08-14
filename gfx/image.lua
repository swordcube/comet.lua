--- @class comet.gfx.Image : comet.gfx.Object2D
--- A basic object for displaying static images.
local Image, super = Object2D:subclass("Image")

-- TODO: texture caching

local math = math -- Faster access with local variable
local gfx = love.graphics

function Image:__init__(image)
    super.__init__(self)

    self.texture = nil --- @type comet.gfx.Texture
    self:loadTexture(image)

    -- Whether or not to display the image from it's center
    self.centered = true

    -- Whether or not to use antialiasing on this image
    self.antialiasing = true

    -- Alpha multiplier for this image
    self.alpha = 1

    --- @type comet.gfx.Color
    self._tint = Color:new(1, 1, 1, 1) --- @protected
end

function Image:loadTexture(tex)
    if self.texture then
        self.texture:dereference()
        self.texture = nil
    end
    if tex ~= nil then
        if type(tex) == "string" then
            local filePath = tex
            if not filePath or not love.filesystem.exists(filePath) then
                return self
            end
            if self.texture then
                self.texture:dereference()
            end
            self.texture = comet.gfx:get(filePath) --- @type comet.gfx.Texture
        else
            self.texture = tex --- @type comet.gfx.Texture
        end
        self.texture:reference()
    end
    return self
end

--- Returns the transform of this image
--- @return love.Transform
function Image:getTransform()
    local transform = self._transform:reset()
    transform = self:getParentTransform(transform)

    -- position
    transform:translate(self.position.x, self.position.y)
    if self.centered then
        transform:translate(-self:getWidth() * 0.5, -self:getHeight() * 0.5)
    end
    -- origin
    local ox, oy = self:getWidth() * self.origin.x, self:getHeight() * self.origin.y
    transform:translate(ox, oy)
    transform:rotate(math.rad(self.rotation))
    transform:translate(-ox, -oy)

    -- scale
    transform:scale(self.scale.x, self.scale.y)
    
    return transform
end

function Image:draw()
    if self.alpha <= 0.0001 or not self.texture then
        return
    end
    local transform = self:getTransform()
    local pr, pg, pb, pa = gfx.getColor()
    gfx.setColor(self._tint.r, self._tint.g, self._tint.b, self._tint.a * self.alpha)
    gfx.draw(self.texture:getImage(self.antialiasing and "linear" or "nearest"), transform)
    gfx.setColor(pr, pg, pb, pa)
end

--- Returns the unscaled width of this image.
--- @return number
function Image:getOriginalWidth()
    if not self.texture then
        return 0
    end
    return self.texture:getWidth()
end

--- Returns the unscaled height of this image.
--- @return number
function Image:getOriginalHeight()
    if not self.texture then
        return 0
    end
    return self.texture:getHeight()
end

--- Returns the current width of this image.
--- @return number
function Image:getWidth()
    if not self.texture then
        return 0
    end
    return self.texture:getWidth() * math.abs(self.scale.x)
end

--- Returns the current height of this image.
--- @return number
function Image:getHeight()
    if not self.texture then
        return 0
    end
    return self.texture:getHeight() * math.abs(self.scale.y)
end

--- Returns the tint of this image
--- @return comet.gfx.Color
function Image:getTint()
    return self._tint
end

--- Sets the tint of this image
--- @param tint comet.gfx.Color
function Image:setTint(tint)
    self._tint = Color:new(tint)
end

function Image:destroy()
    super.destroy(self)
    if self.texture then
        self.texture:dereference()
        self.texture = nil
    end
    self._tint = nil
end

return Image
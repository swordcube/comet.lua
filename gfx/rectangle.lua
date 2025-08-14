--- @class comet.gfx.Rectangle : comet.gfx.Object2D
--- A basic object for displaying static images.
local Rectangle, super = Object2D:subclass("Rectangle")

local math = math -- Faster access with local variable
local img = love.image -- Faster access with local variable
local gfx = love.graphics -- Faster access with local variable

-- Have to make this white pixel shit because gfx.applyTransform
-- just....never unapplies the transform??? ever??

-- Applying the inverse of the transform after we're done doesn't work either

-- So i'll just draw a white pixel and use the transform argument in love.graphics.draw
-- because that DOES work for whatever reason

local whitePixelData = img.newImageData(1, 1)
whitePixelData:setPixel(0, 0, 1, 1, 1, 1)

local whitePixel = gfx.newImage(whitePixelData)

function Rectangle:__init__(x, y)
    super.__init__(self)

    --- Whether or not to display the rectangle from it's center
    self.centered = true

    --- Alpha multiplier for this rectangle
    self.alpha = 1

    self._width = 1 --- @protected
    self._height = 1 --- @protected

    --- @type comet.gfx.Color
    self._tint = Color:new(1, 1, 1, 1) --- @protected
end

--- Returns the unscaled width of this rectangle.
--- @return number
function Rectangle:getOriginalWidth()
    return self._width
end

--- Returns the unscaled height of this rectangle.
--- @return number
function Rectangle:getOriginalHeight()
    return self._height
end

--- Returns the current width of this rectangle.
--- @return number
function Rectangle:getWidth()
    return self._width * math.abs(self.scale.x)
end

--- Sets the width of this rectangle.
--- @param newWidth number
function Rectangle:setWidth(newWidth)
    self._width = newWidth
end

--- Returns the current height of this rectangle.
--- @return number
function Rectangle:getHeight()
    return self._height * math.abs(self.scale.y)
end

--- Sets the height of this rectangle.
--- @param newHeight number
function Rectangle:setHeight(newHeight)
    self._height = newHeight
end

--- Sets the size of this rectangle.
--- @param newWidth number
--- @param newHeight number
function Rectangle:setSize(newWidth, newHeight)
    self._width = newWidth
    self._height = newHeight
end

--- Returns the transform of this rectangle
--- @return love.Transform
function Rectangle:getTransform()
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
    transform:scale(self._width * self.scale.x, self._height * self.scale.y)
    
    return transform
end

function Rectangle:draw()
    local pr, pg, pb, pa = gfx.getColor()
    gfx.setColor(self._tint.r, self._tint.g, self._tint.b, self._tint.a * self.alpha)
    
    local transform = self:getTransform()
    gfx.draw(whitePixel, transform)
    
    gfx.setColor(pr, pg, pb, pa)
end

--- Returns the tint of this rectangle
--- @return comet.gfx.Color
function Rectangle:getTint()
    return self._tint
end

--- Sets the tint of this rectangle
--- @param tint comet.gfx.Color
function Rectangle:setTint(tint)
    self._tint = Color:new(tint)
end

function Rectangle:destroy()
    super.destroy(self)
    self._tint = nil
end

return Rectangle
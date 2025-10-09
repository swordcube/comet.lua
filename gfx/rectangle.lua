--- @class comet.gfx.Rectangle : comet.gfx.Object2D
--- A basic object for displaying static images.
local Rectangle, super = Object2D:subclass("Rectangle", ...)

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
Rectangle.static.whitePixel = whitePixel

local function preMultiplyChannels(r, g, b, a)
    return r * a, g * a, b * a, a
end

function Rectangle:__init__(x, y, width, height)
    super.__init__(self, x, y)

    --- Whether or not to display the rectangle from it's center
    self.centered = true

    --- Alpha multiplier for this rectangle
    self.alpha = 1

    --- The size of this rectangle
    self.size = Vec2:new(width or 1, height or 1) --- @type comet.math.Vec2

    --- @type comet.gfx.Color
    self._color = Color:new(1, 1, 1, 1) --- @protected
end

--- Returns the unscaled width of this rectangle.
--- @return number
function Rectangle:getOriginalWidth()
    return self.size.x
end

--- Returns the unscaled height of this rectangle.
--- @return number
function Rectangle:getOriginalHeight()
    return self.size.y
end

--- Returns the current width of this rectangle.
--- @return number
function Rectangle:getWidth()
    return self.size.x * math.abs(self.scale.x)
end

--- Sets the width of this rectangle.
--- @param newWidth number
function Rectangle:setWidth(newWidth)
    self.size.x = newWidth
end

--- Returns the current height of this rectangle.
--- @return number
function Rectangle:getHeight()
    return self.size.y * math.abs(self.scale.y)
end

--- Sets the height of this rectangle.
--- @param newHeight number
function Rectangle:setHeight(newHeight)
    self.size.y = newHeight
end

--- Sets the size of this rectangle.
--- @param newWidth number
--- @param newHeight number
--- @deprecated
function Rectangle:setSize(newWidth, newHeight)
    Log.warn("Rectangle:setSize() is deprecated, use myRect.size:set() instead!")
    self.size:set(newWidth, newHeight)
end

--- @param axes  "x"|"y"|"xy"?
function Rectangle:screenCenter(axes)
    Image.screenCenter(self, axes)
end

--- Returns the transform of this rectangle
--- @param accountForParent boolean?
--- @param accountForCamera boolean?
--- @return comet.math.Transform
function Rectangle:getTransform(accountForParent, accountForCamera)
    if accountForParent == nil then
        accountForParent = true
    end
    if accountForCamera == nil then
        accountForCamera = true
    end
    local transform = self._transform:reset()
    if accountForParent then
        transform = self:getParentTransform(transform, accountForCamera)
    end

    -- position
    transform:translate(self.position.x + self.offset.x, self.position.y + self.offset.y)
    if self.centered then
        transform:translate(-self:getWidth() * 0.5, -self:getHeight() * 0.5)
    end
    -- origin
    local ox, oy = self:getWidth() * self.origin.x, self:getHeight() * self.origin.y
    transform:translate(ox, oy)
    transform:rotate(math.rad(self.rotation))
    transform:translate(-ox, -oy)

    -- scale
    transform:scale(self.size.x * self.scale.x, self.size.y * self.scale.y)
    
    return transform
end

--- Returns the bounding box of this rectangle, as a basic rectangle
--- @param trans comet.math.Transform?   The transform to use for the bounding box (optional)
--- @param rect  comet.math.Rect?  The rectangle to use as the bounding box (optional)
--- @return comet.math.Rect
function Rectangle:getBoundingBox(trans, rect)
    if not trans then
        trans = self:getTransform()
    end
    if not rect then
        rect = Rect:new()
    end
    local w, h = 1, 1
    local x1, y1 = trans:transformPoint(0, 0)
    local x2, y2 = trans:transformPoint(w, 0)
    local x3, y3 = trans:transformPoint(w, h)
    local x4, y4 = trans:transformPoint(0, h)

    local minX = math.min(x1, x2, x3, x4)
    local minY = math.min(y1, y2, y3, y4)
    local maxX = math.max(x1, x2, x3, x4)
    local maxY = math.max(y1, y2, y3, y4)

    rect:set(minX, minY, maxX - minX, maxY - minY)
    return rect
end

--- Checks if this rectangle is on screen
--- @param box comet.math.Rect?  The bounding box to check with (optional)
function Rectangle:isOnScreen(box)
    if not box then
        box = self:getBoundingBox()
    end
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
    local gx, gy, gw, gh = 0, 0, 0, 0
    local bxpw, byph = box.x + box.width, box.y + box.height
    if camera then
        local cameraBox = camera._rect
        gx, gy, gw, gh = cameraBox.x, cameraBox.y, cameraBox.width, cameraBox.height
    else
        gx, gy, gw, gh = 0, 0, comet.getDesiredWidth(), comet.getDesiredHeight()
    end
    if bxpw < gx or box.x > gx + gw or byph < gy or box.y > gy + gh then
        return false
    end
    return true
end

function Rectangle:draw()
    local transform = self:getTransform()
    local box = self:getBoundingBox(transform, self._rect)
    if not self:isOnScreen(box) then
        return
    end
    local pr, pg, pb, pa = gfx.getColor()
    gfx.setColor(preMultiplyChannels(self._color.r * pr, self._color.g * pg, self._color.b * pb, self._color.a * self.alpha * pa))
    
    gfx.setBlendMode("alpha", "premultiplied")
    gfx.draw(whitePixel, transform:getRenderValues())
    
    if comet.settings.debugDraw then
        gfx.setLineWidth(4)
        gfx.setColor(1, 1, 1, 1)
        gfx.rectangle("line", box.x, box.y, box.width, box.height)
    end
    gfx.setColor(pr, pg, pb, pa)
end

--- Returns the color of this rectangle
--- @return comet.gfx.Color
function Rectangle:getColor()
    return self._color
end

--- Sets the color of this rectangle
--- @param color comet.gfx.Color
function Rectangle:setColor(color)
    self._color = Color:new(color)
end

--- Returns the tint of this rectangle
--- @deprecated
--- @return comet.gfx.Color
function Rectangle:getTint()
    Log.warn("Rectangle:getTint() is deprecated, use Rectangle:getColor() instead")
    return self._color
end

--- Sets the tint of this rectangle
--- @deprecated
--- @param tint comet.gfx.Color
function Rectangle:setTint(tint)
    Log.warn("Rectangle:setTint() is deprecated, use Rectangle:setColor() instead")
    self._color = Color:new(tint)
end

function Rectangle:destroy()
    super.destroy(self)
    self._color = nil
end

return Rectangle
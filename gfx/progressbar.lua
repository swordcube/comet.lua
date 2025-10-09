--- @class comet.gfx.ProgressBar : comet.gfx.Object2D
--- A basic object for displaying rectangular progress bars.
local ProgressBar, super = Object2D:subclass("ProgressBar", ...)

local math = math -- Faster access with local variable
local gfx = love.graphics -- Faster access with local variable

local function preMultiplyChannels(r, g, b, a)
    return r * a, g * a, b * a, a
end

function ProgressBar:__init__(x, y, width, height)
    super.__init__(self, x, y)

    --- Whether or not to display the progress bar from it's center
    self.centered = true

    --- Alpha multiplier for this progress bar
    self.alpha = 1

    --- The size of this progress bar
    self.size = Vec2:new(width or 1, height or 1) --- @type comet.math.Vec2

    --- The fill direction of this progress bar
    self.fillStyle = "left-to-right" --- @type "left-to-right"|"right-to-left"|"top-to-bottom"|"bottom-to-top"

    --- @type number
    self._progress = 0.5 --- @protected

    --- @type comet.gfx.Color
    self._emptyColor = Color:new(0.5, 0.5, 0.5, 1) --- @protected

    --- @type comet.gfx.Color
    self._fillColor = Color:new(1, 1, 1, 1) --- @protected
end

--- Returns the unscaled width of this progress bar.
--- @return number
function ProgressBar:getOriginalWidth()
    return self.size.x
end

--- Returns the unscaled height of this progress bar.
--- @return number
function ProgressBar:getOriginalHeight()
    return self.size.y
end

--- Returns the current width of this progress bar.
--- @return number
function ProgressBar:getWidth()
    return self.size.x * math.abs(self.scale.x)
end

--- Sets the width of this progress bar.
--- @param newWidth number
function ProgressBar:setWidth(newWidth)
    self.size.x = newWidth
end

--- Returns the current height of this progress bar.
--- @return number
function ProgressBar:getHeight()
    return self.size.y * math.abs(self.scale.y)
end

--- Sets the height of this progress bar.
--- @param newHeight number
function ProgressBar:setHeight(newHeight)
    self.size.y = newHeight
end

--- @param axes  "x"|"y"|"xy"?
function ProgressBar:screenCenter(axes)
    Image.screenCenter(self, axes)
end

--- Returns the transform of this progress bar
--- @param accountForParent boolean?
--- @param accountForCamera boolean?
--- @param isFill boolean?
--- @return comet.math.Transform
function ProgressBar:getTransform(accountForParent, accountForCamera, isFill)
    if accountForParent == nil then
        accountForParent = true
    end
    if accountForCamera == nil then
        accountForCamera = true
    end
    if isFill == nil then
        isFill = false
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
    if isFill then
        if self.fillStyle == "right-to-left" then
            transform:translate(self:getWidth() * (1 - self._progress), 0)
        elseif self.fillStyle == "bottom-to-top" then
            transform:translate(0, self:getHeight() * (1 - self._progress))
        end
    end
    transform:translate(-ox, -oy)

    -- scale
    local scale = (isFill and math.clamp(self._progress, 0.0, 1.0) or 1.0)
    if self.fillStyle == "left-to-right" or self.fillStyle == "right-to-left" then
        transform:scale(self.size.x * self.scale.x * scale, self.size.y * self.scale.y)
    
    elseif self.fillStyle == "top-to-bottom" or self.fillStyle == "bottom-to-top" then
        transform:scale(self.size.x * self.scale.x, self.size.y * self.scale.y * scale)
    end
    return transform
end

--- Returns the bounding box of this progress bar, as a basic rectangle
--- @param trans comet.math.Transform?   The transform to use for the bounding box (optional)
--- @param rect  comet.math.Rect?  The rectangle to use as the bounding box (optional)
--- @return comet.math.Rect
function ProgressBar:getBoundingBox(trans, rect)
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

--- Checks if this progress bar is on screen
--- @param box comet.math.Rect?  The bounding box to check with (optional)
function ProgressBar:isOnScreen(box)
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

function ProgressBar:draw()
    local transform = self:getTransform()
    local box = self:getBoundingBox(transform, self._rect)
    if not self:isOnScreen(box) then
        return
    end
    local pr, pg, pb, pa = gfx.getColor()
    local x, y, r, sx, sy = transform:getRenderValues()

    gfx.setColor(preMultiplyChannels(self._emptyColor.r * pr, self._emptyColor.g * pg, self._emptyColor.b * pb, self._emptyColor.a * self.alpha * pa))
    
    gfx.setBlendMode("alpha", "premultiplied")
    gfx.draw(Rectangle.whitePixel, x, y, r, sx, sy)

    if self._progress > 0.0 then
        gfx.setColor(preMultiplyChannels(self._fillColor.r * pr, self._fillColor.g * pg, self._fillColor.b * pb, self._fillColor.a * self.alpha * pa))

        transform = self:getTransform(true, true, true)
        x, y, r, sx, sy = transform:getRenderValues()

        gfx.draw(Rectangle.whitePixel, x, y, r, sx, sy)
    end
    gfx.setColor(pr, pg, pb, pa)

    if comet.settings.debugDraw then
        gfx.setLineWidth(4)
        gfx.setColor(1, 1, 1, 1)
        gfx.rectangle("line", box.x, box.y, box.width, box.height)
    end
end

--- Returns the empty color of this progress bar
--- @return comet.gfx.Color
function ProgressBar:getEmptyColor()
    return self._emptyColor
end

--- Sets the empty color of this progress bar
--- @param color comet.gfx.Color
function ProgressBar:setEmptyColor(color)
    self._emptyColor = Color:new(color)
end

--- Returns the fill color of this progress bar
--- @return comet.gfx.Color
function ProgressBar:getFillColor()
    return self._fillColor
end

--- Sets the fill color of this progress bar
--- @param color comet.gfx.Color
function ProgressBar:setFillColor(color)
    self._fillColor = Color:new(color)
end

function ProgressBar:getProgress()
    return self._progress
end

--- @param progress number
function ProgressBar:setProgress(progress)
    self._progress = math.clamp(progress, 0.0, 1.0)
end

function ProgressBar:destroy()
    super.destroy(self)
    self._emptyColor = nil
    self._fillColor = nil
end

return ProgressBar
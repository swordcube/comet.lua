--- @class comet.gfx.Camera : comet.gfx.Object2D
--- A basic object for displaying static Cameras.
local Camera, super = Object2D:subclass("Camera")

local math = math -- Faster access with local variable

function Camera:__init__()
    super.__init__(self)

    -- Set position to center by default
    self.position:set(comet.getDesiredWidth() / 2, comet.getDesiredHeight() / 2)

    self.scroll = Vec2:new()
    
    --- Size of this camera
    self.size = Vec2:new(comet.getDesiredWidth(), comet.getDesiredHeight()) --- @type comet.math.Vec2

    --- Zoom of this camera
    self.zoom = Vec2:new(1.0, 1.0) --- @type comet.math.Vec2

    --- Non-functional on Cameras, use `zoom` instead.
    self.scale = nil

    --- @type comet.gfx.Color
    self._bgColor = Color:new(Color.BLACK) --- @protected

    --- @type comet.math.Rect
    self._rect = Rect:new() --- @protected
end

function Camera:getBackgroundColor()
    return self._bgColor
end

--- @param color comet.gfx.Color
function Camera:setBackgroundColor(color)
    self._bgColor = Color:new(color)
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
--- @param accountForScroll boolean?
--- @param accountForZoom boolean?
--- @return love.Transform
function Camera:getTransform(accountForScroll, accountForZoom)
    if accountForScroll == nil then
        accountForScroll = true
    end
    if accountForZoom == nil then
        accountForZoom = true
    end
    local transform = self._transform:reset()
    transform = self:getParentTransform(transform)

    -- position
    if accountForScroll then
        transform:translate(-self.scroll.x, -self.scroll.y)
    end
    local w, h = accountForZoom and self:getWidth() or self:getOriginalWidth(), accountForZoom and self:getHeight() or self:getOriginalHeight()
    transform:translate(self.position.x - (w * 0.5), self.position.y - (h * 0.5))

    -- origin
    local ox, oy = w * self.origin.x, h * self.origin.y
    transform:translate(ox, oy)
    transform:rotate(math.rad(self.rotation))
    transform:translate(-ox, -oy)

    -- scale
    if accountForZoom then
        transform:scale(math.max(self.zoom.x, 0.0), math.max(self.zoom.y, 0.0))
    end
    return transform
end

--- Returns the bounding box of this camera, as a rectangle
--- @param trans love.Transform?   The transform to use for the bounding box (optional)
--- @param rect  comet.math.Rect?  The rectangle to use as the bounding box (optional)
--- @return comet.math.Rect
function Camera:getBoundingBox(trans, rect)
    if not trans then
        trans = self:getTransform()
    end
    if not rect then
        rect = Rect:new()
    end
    local w, h = self:getOriginalWidth(), self:getOriginalHeight()
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

function Camera:_draw()
    local box = self:getBoundingBox(self:getTransform(false, false), self._rect)

    local px, py, pw, ph = love.graphics.getScissor()
    love.graphics.setScissor(comet.adjustToGameScissor(box.x, box.y, box.width, box.height))
    
    local pr, pg, pb, pa = love.graphics.getColor()
    love.graphics.setColor(self._bgColor.r, self._bgColor.g, self._bgColor.b, self._bgColor.a)
    love.graphics.rectangle("fill", box.x, box.y, box.width, box.height)
    love.graphics.setColor(pr, pg, pb, pa)
    
    super._draw(self)
    love.graphics.setScissor(px, py, pw, ph)
end

function Camera:destroy()
    super.destroy(self)
    self.size = nil
    self.zoom = nil
end

return Camera
--- @class comet.gfx.Label : comet.gfx.Object2D
--- A basic object for displaying static text.
local Label, super = Object2D:subclass("Label")

local gfx = love.graphics
-- TODO: font caching

local function _drawWithOffset(label, transform, x, y)
    transform:translate(x, y)
    gfx.draw(label._textObject, transform)
    transform:translate(-x, -y)
end

function Label:__init__(x, y)
    super.__init__(self, x, y)

    -- The text displayed on this label
    self.text = ""

    -- The alignment of the text displayed on this label
    self.alignment = "left" --- @type "left"|"center"|"right"|"justify"

    -- The maximum width of the text displayed on this label
    -- before it starts wrapping around
    self.maxWidth = 0

    -- The size of the border around this label
    self.borderSize = 0

    -- The precision of the border (how smooth it looks)
    self.borderPrecision = 8

    --- @type comet.gfx.Color
    self._color = Color:new(Color.WHITE) --- @protected

    --- @type comet.gfx.Color
    self._borderColor = Color:new(Color.BLACK) --- @protected

    -- Whether or not to display the label from it's center
    self.centered = true

    -- Whether or not to use antialiasing on this label
    self.antialiasing = true

    --- Alpha multiplier for this label
    self.alpha = 1

    --- @type string
    self._font = nil --- @protected

    --- @type string
    self._prevText = nil --- @protected

    --- @type number
    self._size = 16

    --- @type love.Font
    self._fontData = nil --- @protected

    --- @type love.Text
    self._textObject = nil --- @protected

    self:setFont() -- use default font immediately
end

function Label:getBorderColor()
    return self._borderColor
end

function Label:setBorderColor(color)
    self._borderColor = Color:new(color)
end

function Label:getColor()
    return self._color
end

function Label:setColor(color)
    self._color = Color:new(color)
end

function Label:getSize()
    return self._size
end

function Label:setSize(size)
    self._size = size
    self:setFont(self._font)
end

function Label:getFont()
    return self._font
end

function Label:setFont(font)
    self._font = font or comet.getEmbeddedFont("Roboto-Regular")
    if self._fontData then
        self._fontData:release()
    end
    self._fontData = gfx.newFont(self._font, self._size, "light")
    if not self._textObject then
        self._textObject = gfx.newTextBatch(self._fontData)
    end
    self._textObject:setFont(self._fontData)
end

--- Returns the transform of this label
--- @return love.Transform
function Label:getTransform()
    local transform = self._transform:reset()
    transform = self:getParentTransform(transform)

    -- position
    self:updateText()
    transform:translate(self.position.x, self.position.y)
    if self.centered then
        transform:translate(-self:getWidth() * 0.5, -self:getHeight() * 0.5)
    end
    local padding = math.floor(self.borderSize) + 2
    transform:translate(padding * 0.5, padding * 0.5)

    -- origin
    local ox, oy = self:getWidth() * self.origin.x, self:getHeight() * self.origin.y
    transform:translate(ox, oy)
    transform:rotate(math.rad(self.rotation))
    transform:translate(-ox, -oy)

    -- scale
    transform:scale(self.scale.x, self.scale.y)
    
    return transform
end

function Label:updateText()
    if self._prevText == self.text then
        return
    end
    local alignment = self.alignment
    if not self.text:contains("\n") then
        alignment = "left"
    end
    if self.maxWidth > 0 then
        self._textObject:setf(self.text, self.maxWidth, alignment)
    else
        self._textObject:setf(self.text, self._fontData:getWidth(self.text), alignment)
    end
    self._prevText = self.text
end

--- Returns the unscaled width of this label.
--- @return number
function Label:getOriginalWidth()
    self:updateText()
    local padding = math.floor(self.borderSize) + 2
    return self._fontData:getWidth(self.text) + padding
end

--- Returns the unscaled height of this label.
--- @return number
function Label:getOriginalHeight()
    self:updateText()
    local padding = math.floor(self.borderSize) + 2
    return self._textObject:getHeight() + padding
end

--- Returns the current width of this label.
--- @return number
function Label:getWidth()
    self:updateText()
    local padding = math.floor(self.borderSize) + 2
    return (self._fontData:getWidth(self.text) + padding) * math.abs(self.scale.x)
end

--- Returns the current height of this label.
--- @return number
function Label:getHeight()
    self:updateText()
    local padding = math.floor(self.borderSize) + 2
    return (self._textObject:getHeight() + padding) * math.abs(self.scale.y)
end

function Label:draw()
    if self.alpha <= 0.0001 then
        return
    end
    self:updateText()
    local pr, pg, pb, pa = gfx.getColor()

    local filter = self.antialiasing and "linear" or "nearest"
    self._fontData:setFilter(filter, filter)

    local transform = self:getTransform()
    if self.borderSize > 0 and self._borderColor.a > 0 then
        local r, g, b, a = self._borderColor:unpack()
        gfx.setColor(r, g, b, a * self.alpha)

        local size = self.borderSize
        local precision = self.borderPrecision

        local step = (2 * math.pi) / precision
        for i = 1, precision do
            local dx = math.round(math.fastcos(i * step) * size)
            local dy = math.round(math.fastsin(i * step) * size)
            _drawWithOffset(self, transform, dx, dy)
        end
    end
    gfx.setColor(self._color.r, self._color.g, self._color.b, self._color.a * self.alpha)
    gfx.draw(self._textObject, transform)
    gfx.setColor(pr, pg, pb, pa)
end

return Label:finalize()
local bit = require("bit")
local middleclass = cometreq("lib.middleclass") --- @type comet.lib.MiddleClass

--- @class comet.gfx.Color : comet.util.Class
--- Basic class for representing RGBA color
local Color = {}

-- these are here for documentation purposes

Color.TRANSPARENT = nil --- @type comet.gfx.Color
Color.WHITE       = nil --- @type comet.gfx.Color
Color.GRAY        = nil --- @type comet.gfx.Color
Color.BLACK       = nil --- @type comet.gfx.Color
Color.RED         = nil --- @type comet.gfx.Color
Color.ORANGE      = nil --- @type comet.gfx.Color
Color.YELLOW      = nil --- @type comet.gfx.Color
Color.LIME        = nil --- @type comet.gfx.Color
Color.GREEN       = nil --- @type comet.gfx.Color
Color.CYAN        = nil --- @type comet.gfx.Color
Color.BLUE        = nil --- @type comet.gfx.Color
Color.PURPLE      = nil --- @type comet.gfx.Color
Color.MAGENTA     = nil --- @type comet.gfx.Color
Color.PINK        = nil --- @type comet.gfx.Color
Color.BROWN       = nil --- @type comet.gfx.Color

Color = Class("Color", ...)

function Color:__init__(r, g, b, a)
    -- Red channel of this color
    self.r = 0

    -- Green channel of this color
    self.g = 0

    -- Blue channel of this color
    self.b = 0

    -- Alpha channel of this color
    self.a = 0

    self:set(r, g, b, a)
end

-- Sets the RGBA values of this color and returns it
--- @param r number|string? The red channel (or hex color as int or string)
--- @param g number        The green channel (ignored if hex color is provided)
--- @param b number        The blue channel (ignored if hex color is provided)
--- @param a number        The alpha channel (ignored if hex color is provided)
function Color:set(r, g, b, a)
    if not r then return self end
    if type(r) == "table" then
        if middleclass.isinstanceof(r, Color) then
            self.r, self.g, self.b, self.a = r.r, r.g, r.b, r.a
        else
            self.r, self.g, self.b, self.a = r[1], r[2], r[3], r[4]
        end
        return self
    end
    if type(r) == "string" then
        r = tonumber(r:replace("#", "0x"))
        return self
    end
    if type(r) == "number" and (not g or not b or not a) then
        self.r = bit.band(bit.rshift(r, 16), 0xFF) / 255
		self.g = bit.band(bit.rshift(r, 8), 0xFF) / 255
		self.b = bit.band(r, 0xFF) / 255
		self.a = bit.band(bit.rshift(r, 24), 0xFF) / 255
        return self
    end
    self.r, self.g, self.b, self.a = r, g, b, a
    return self
end

-- Unpacks the RGBA values of this color
function Color:unpack()
    return self.r, self.g, self.b, self.a
end

-- Packs the RGBA values of this color into an array
function Color:array()
    return {self.r, self.g, self.b, self.a}
end

-- these are here again to make them actually work in static context

Color.static.TRANSPARENT = Color:new(0x00000000) --- @type comet.gfx.Color
Color.static.WHITE       = Color:new(0xFFFFFFFF) --- @type comet.gfx.Color
Color.static.GRAY        = Color:new(0xFF808080) --- @type comet.gfx.Color
Color.static.BLACK       = Color:new(0xFF000000) --- @type comet.gfx.Color
Color.static.RED         = Color:new(0xFFFF0000) --- @type comet.gfx.Color
Color.static.ORANGE      = Color:new(0xFFFFA500) --- @type comet.gfx.Color
Color.static.YELLOW      = Color:new(0xFFFFFF00) --- @type comet.gfx.Color
Color.static.LIME        = Color:new(0xFF00FF00) --- @type comet.gfx.Color
Color.static.GREEN       = Color:new(0xFF008000) --- @type comet.gfx.Color
Color.static.CYAN        = Color:new(0xFF00FFFF) --- @type comet.gfx.Color
Color.static.BLUE        = Color:new(0xFF0000FF) --- @type comet.gfx.Color
Color.static.PURPLE      = Color:new(0xFF800080) --- @type comet.gfx.Color
Color.static.MAGENTA     = Color:new(0xFFFF00FF) --- @type comet.gfx.Color
Color.static.PINK        = Color:new(0xFFFFC0CB) --- @type comet.gfx.Color
Color.static.BROWN       = Color:new(0xFF8B4513) --- @type comet.gfx.Color

return Color
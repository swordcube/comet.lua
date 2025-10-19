local ffi = require("ffi")
local bit = require("bit")

--- @class comet.gfx.Color : comet.util.Class
--- Basic class for representing RGBA color
--- 
--- @field r number Red channel of this color
--- @field g number Green channel of this color
--- @field b number Blue channel of this color
--- @field a number Alpha channel of this color
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

ffi.cdef "typedef struct { double r,g,b,a; bool _isClone; bool _isColor; } comet_color;"

Color = {}
Color.__index = Color

local _new = ffi.typeof("comet_color")
local impl = {new = function(_, r, g, b, a)
    local v = _new()
    v._isClone = false
    v._isColor = true
    Color.set(v, r, g, b, a)
    return v
end}
impl.mt = Color

local function _iscolor(t)
    return t._isColor == true
end

--- check if an object is a color
---@param t any
---@return boolean
local function iscolor(t)
    local success, result = pcall(_iscolor, t)
    return type(t) == "cdata" and (success and result == true)
end
impl.isColor = iscolor
Color.isColor = iscolor

-- Sets the RGBA values of this color and returns it
--- @param r number|string? The red channel (or hex color as int or string)
--- @param g number        The green channel (ignored if hex color is provided)
--- @param b number        The blue channel (ignored if hex color is provided)
--- @param a number        The alpha channel (ignored if hex color is provided)
function Color:set(r, g, b, a)
    if not r then return self end
    if iscolor(r) then
        self._isClone = true
        self.r, self.g, self.b, self.a = r.r, r.g, r.b, r.a
        return self
    elseif type(r) == "table" then
        self.r, self.g, self.b, self.a = r[1], r[2], r[3], r[4]
        return self
    end
    if type(r) == "string" then
        r = tonumber(r:replace("#", "0x"))
        isRNumber = true
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

--- Creates a clone of this color
--- @return comet.gfx.Color
function Color:clone()
    local v = _new()
    v._isClone = true
    v._isColor = true
    Color.set(v, self.r, self.g, self.b, self.a)
    return v
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

impl.TRANSPARENT = impl:new(0x00000000) --- @type comet.gfx.Color
impl.WHITE       = impl:new(0xFFFFFFFF) --- @type comet.gfx.Color
impl.GRAY        = impl:new(0xFF808080) --- @type comet.gfx.Color
impl.BLACK       = impl:new(0xFF000000) --- @type comet.gfx.Color
impl.RED         = impl:new(0xFFFF0000) --- @type comet.gfx.Color
impl.ORANGE      = impl:new(0xFFFFA500) --- @type comet.gfx.Color
impl.YELLOW      = impl:new(0xFFFFFF00) --- @type comet.gfx.Color
impl.LIME        = impl:new(0xFF00FF00) --- @type comet.gfx.Color
impl.GREEN       = impl:new(0xFF008000) --- @type comet.gfx.Color
impl.CYAN        = impl:new(0xFF00FFFF) --- @type comet.gfx.Color
impl.BLUE        = impl:new(0xFF0000FF) --- @type comet.gfx.Color
impl.PURPLE      = impl:new(0xFF800080) --- @type comet.gfx.Color
impl.MAGENTA     = impl:new(0xFFFF00FF) --- @type comet.gfx.Color
impl.PINK        = impl:new(0xFFFFC0CB) --- @type comet.gfx.Color
impl.BROWN       = impl:new(0xFF8B4513) --- @type comet.gfx.Color

ffi.metatype("comet_color", impl.mt)
return impl
local middleclass = cometreq("lib.middleclass") --- @type comet.lib.MiddleClass

---@class comet.math.Rect
local Rect = Class("Rect")

-- get a random function from Love2d or base lua, in that order.
local rand = math.random
if love and love.math then rand = love.math.random end

function Rect:__init__(x, y, w, h)
    self.x = x and x or 0.0
    self.y = y and y or 0.0
    self.width = w and w or 0.0
    self.height = h and h or 0.0
end

--- makes a new rectangle
---@param x number?
---@param y number?
---@return comet.math.Rect
local function new(x,y,w,h)
  return Rect:new(x,y,w,h)
end

--- check if an object is a rectangle
---@param t any
---@return boolean
local function isrect(t)
  return middleclass.isinstanceof(t, Rect)
end

--- set the values of the rectangle to something new
---@param x number
---@param y number
---@param w number
---@param h number
---@overload fun(self: comet.math.Rect, vec: comet.math.Rect): self
---@return self
function Rect:set(x,y,w,h)
---@diagnostic disable-next-line: undefined-field
  if isrect(x) then self.x, self.y, self.width, self.height = x.x, x.y, x.width, x.height; return self end
  self.x, self.y, self.width, self.height = x or 0.0, y or 0.0, w or 0.0, h or 0.0
  return self
end

--- replace the values of a rectangle with the values of another rectangle
---@param v comet.math.Rect
---@return self
function Rect:replace(v)
  assert(isrect(v), "replace: wrong argument type: (expected <rectangle>, got "..type(v)..")")
  self.x, self.y, self.width, self.height = v.x, v.y, v.width, v.height
  return self
end

--- returns a copy of a rectangle
---@return comet.math.Rect
function Rect:clone()
  return new(self.x, self.y, self.width, self.height)
end

--- @return comet.math.Rect
function Rect:getRotatedBounds(radians, origin, newRect)
    if not origin then
        origin = Vec2:new(0.0, 0.0)
    end
    if not newRect then
        newRect = Rect:new()
    end
    local degrees = math.deg(radians) % 360
    if degrees == 0 then
        return newRect:set(self.x, self.y, self.width, self.height)
    end
    if degrees < 0 then
        degrees = degrees + 360
    end
    radians = math.rad(degrees)
    
    local cos = math.fastcos(radians)
    local sin = math.fastsin(radians)

    local left = -origin.x
    local top = -origin.y
    local right = -origin.x + self.width
    local bottom = -origin.y + self.height

    if degrees < 90 then
        newRect.x = self.x + origin.x + cos * left - sin * bottom
        newRect.y = self.y + origin.y + sin * left + cos * top
    elseif degrees < 180 then
        newRect.x = self.x + origin.x + cos * right - sin * bottom
        newRect.y = self.y + origin.y + sin * left  + cos * bottom
    elseif degrees < 270 then
        newRect.x = self.x + origin.x + cos * right - sin * top
        newRect.y = self.y + origin.y + sin * right + cos * bottom
    else
        newRect.x = self.x + origin.x + cos * left - sin * top
        newRect.y = self.y + origin.y + sin * right + cos * top
    end
    local newHeight = math.abs(cos * self.height) + math.abs(sin * self.width)
    newRect.width = math.abs(cos * self.width) + math.abs(sin * self.height)
    newRect.height = newHeight
    return newRect
end

--- meta function to make rectangles negative
--- ex: (negative) -rectangle(5,6) is the same as rectangle(-5,-6)
---@param v comet.math.Rect
---@return comet.math.Rect
function Rect.__unm(v)
  return new(-v.x, -v.y, -v.width, -v.height)
end

--- meta function to add rectangles together
--- ex: (rectangle(5,6) + rectangle(6,5)) is the same as rectangle(11,11)
---@param a comet.math.Rect
---@param b comet.math.Rect
---@return comet.math.Rect
function Rect.__add(a,b)
  assert(isrect(a) and isrect(b), "add: wrong argument types: (expected <rectangle> and <rectangle>)")
  return new(a.x+b.x, a.y+b.y, a.w+b.width, a.h+b.height)
end

--- meta function to subtract rectangles
---@param a comet.math.Rect
---@param b comet.math.Rect
---@return comet.math.Rect
function Rect.__sub(a,b)
  assert(isrect(a) and isrect(b), "sub: wrong argument types: (expected <rectangle> and <rectangle>)")
  return new(a.x-b.x, a.y-b.y, a.w-b.width, a.h-b.height)
end

--- meta function to multiply rectangles
---@param a comet.math.Rect | number
---@param b comet.math.Rect | number
---@return comet.math.Rect
function Rect.__mul(a,b)
  if type(a) == 'number' then
    return new(a * b.x, a * b.y, a * b.width, a * b.height)
  elseif type(b) == 'number' then
    return new(a.x * b, a.y * b, a.width * b, a.height * b)
  else
    assert(isrect(a) and isrect(b),  "mul: wrong argument types: (expected <rectangle> or <number>)")
    return new(a.x*b.x, a.y*b.y, a.width*b.w, a.h*b.height)
  end
end

--- meta function to divide rectangles
---@param a comet.math.Rect | number
---@param b comet.math.Rect | number
---@return comet.math.Rect
function Rect.__div(a,b)
  assert(isrect(a) and type(b) == "number", "div: wrong argument types (expected <rectangle> and <number>)")
  return new(a.x/b, a.y/b, a.width/b, a.height/b)
end

--- meta function to change how rectangles appear as string
--- ex: print(rectangle(2,8)) - this prints 'instance of Rect(2,8)'
---@return string
function Rect:__tostring__()
  return "instance of Rect("..self.x..", "..self.y..")"
end

--- return x, y, w, and h of rectangle as a regular array
---@return { [1]: number, [2]: number, [3]: number, [4]: number }
function Rect:array()
  return {self.x, self.y, self.width, self.height}
end

-- return x, y, w, and h of rectangle, unpacked from table
---@return number, number, number, number
function Rect:unpack()
  return self.x, self.y, self.width, self.height
end

return Rect
local middleclass = cometreq("lib.middleclass") --- @type comet.lib.MiddleClass

---@class comet.math.Vec2
local Vec2 = Class("Vec2", ...)

-- get a random function from Love2d or base lua, in that order.
local rand = math.random
if love and love.math then rand = love.math.random end

function Vec2:__init__(x, y)
    self.x = x and x or 0.0
    self.y = y and y or 0.0
end

--- check if an object is a vector
---@param t any
---@return boolean
local function isvector(t)
    return middleclass.isinstanceof(t, Vec2)
end

--- set the values of the vector to something new
---@param x number?
---@param y number?
---@overload fun(self: comet.math.Vec2, vec: comet.math.Vec2): self
---@return self
function Vec2:set(x, y)
    ---@diagnostic disable-next-line: undefined-field
    if isvector(x) then
        self.x, self.y = x.x, x.y; return self
    end
    self.x, self.y = x or 0.0, y or 0.0
    return self
end

--- replace the values of a vector with the values of another vector
---@param v comet.math.Vec2
---@return self
function Vec2:replace(v)
    assert(isvector(v), "replace: wrong argument type: (expected <vector>, got " .. type(v) .. ")")
    self.x, self.y = v.x, v.y
    return self
end

--- returns a copy of a vector
---@return comet.math.Vec2
function Vec2:clone()
    return Vec2:new(self.x, self.y)
end

--- get the magnitude of a vector
---@return number
function Vec2:getmag()
    return math.sqrt(self.x ^ 2 + self.y ^ 2)
end

--- get the magnitude squared of a vector
---@return number
function Vec2:magSq()
    return self.x ^ 2 + self.y ^ 2
end

--- set the magnitude of a vector
---@return self
function Vec2:setmag(mag)
    assert(self:getmag() ~= 0, "Cannot set magnitude when direction is ambiguous")
    self:norm()
    local v = self * mag
    self:replace(v)
    return self
end

--- meta function to make vectors negative
--- ex: (negative) -vector(5,6) is the same as vector(-5,-6)
---@param v comet.math.Vec2
---@return comet.math.Vec2
function Vec2.__unm(v)
    return Vec2:new(-v.x, -v.y)
end

--- meta function to add vectors together
--- ex: (vector(5,6) + vector(6,5)) is the same as vector(11,11)
---@param a comet.math.Vec2
---@param b comet.math.Vec2
---@return comet.math.Vec2
function Vec2.__add(a, b)
    assert(isvector(a) and isvector(b), "add: wrong argument types: (expected <vector> and <vector>)")
    return Vec2:new(a.x + b.x, a.y + b.y)
end

--- meta function to subtract vectors
---@param a comet.math.Vec2
---@param b comet.math.Vec2
---@return comet.math.Vec2
function Vec2.__sub(a, b)
    assert(isvector(a) and isvector(b), "sub: wrong argument types: (expected <vector> and <vector>)")
    return Vec2:new(a.x - b.x, a.y - b.y)
end

--- meta function to multiply vectors
---@param a comet.math.Vec2 | number
---@param b comet.math.Vec2 | number
---@return comet.math.Vec2
function Vec2.__mul(a, b)
    if type(a) == 'number' then
        return Vec2:new(a * b.x, a * b.y)
    elseif type(b) == 'number' then
        return Vec2:new(a.x * b, a.y * b)
    else
        assert(isvector(a) and isvector(b), "mul: wrong argument types: (expected <vector> or <number>)")
        return Vec2:new(a.x * b.x, a.y * b.y)
    end
end

--- meta function to divide vectors
---@param a comet.math.Vec2 | number
---@param b comet.math.Vec2 | number
---@return comet.math.Vec2
function Vec2.__div(a, b)
    assert(isvector(a) and type(b) == "number", "div: wrong argument types (expected <vector> and <number>)")
    return Vec2:new(a.x / b, a.y / b)
end

--- meta function to change how vectors appear as string
--- ex: print(vector(2,8)) - this prints 'instance of Vec2(2,8)'
---@return string
function Vec2:__tostring__()
    return "instance of Vec2(" .. self.x .. ", " .. self.y .. ")"
end

--- get the distance between two vectors
---@param a comet.math.Vec2
---@param b comet.math.Vec2
---@return number
function Vec2.dist(a, b)
    assert(isvector(a) and isvector(b), "dist: wrong argument types (expected <vector> and <vector>)")
    return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)
end

--- return the dot product of the vector
---@param v comet.math.Vec2
---@return number
function Vec2:dot(v)
    assert(isvector(v), "dot: wrong argument type (expected <vector>)")
    return self.x * v.x + self.y * v.y
end

--- normalize the vector (give it a magnitude of 1)
---@return comet.math.Vec2
function Vec2:norm()
    local m = self:getmag()
    if m ~= 0 then
        self:replace(self / m)
    end
    return self
end

--- limit the vector to a certain amount
---@param max number
---@return comet.math.Vec2
function Vec2:limit(max)
    assert(type(max) == 'number', "limit: wrong argument type (expected <number>)")
    local mSq = self:magSq()
    if mSq > max ^ 2 then
        self:setmag(max)
    end
    return self
end

--- Clamp each axis between max and min's corresponding axis
---@param min comet.math.Vec2
---@param max comet.math.Vec2
---@return comet.math.Vec2
function Vec2:clamp(min, max)
    assert(isvector(min) and isvector(max), "clamp: wrong argument type (expected <vector>) and <vector>")
    local x = math.min(math.max(self.x, min.x), max.x)
    local y = math.min(math.max(self.y, min.y), max.y)
    self:set(x, y)
    return self
end

--- get the heading (direction) of a vector
---@return number
function Vec2:heading()
    return -math.atan2(self.y, self.x)
end

--- rotate a vector clockwise by a certain number of radians
---@param theta number
---@return comet.math.Vec2
function Vec2:rotate(theta)
    local s = math.sin(theta)
    local c = math.cos(theta)
    local v = Vec2:new(
        (c * self.x) + (s * self.y),
        -(s * self.x) + (c * self.y))
    self:replace(v)
    return self
end

function Vec2:lerp(newx, newy, ratio)
    ratio = math.clamp(ratio, 0.0, 1.0)
    self.x = math.lerp(self.x, newx, ratio)
    self.y = math.lerp(self.y, newy, ratio)
    return self
end

--- return x and y of vector as a regular array
---@return { [1]: number, [2]: number }
function Vec2:array()
    return { self.x, self.y }
end

-- return x and y of vector, unpacked from table
---@return number, number
function Vec2:unpack()
    return self.x, self.y
end

return Vec2

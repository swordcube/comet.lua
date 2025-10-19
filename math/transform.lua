--- @diagnostic disable: cast-local-type
local ffi = require("ffi")
ffi.cdef "typedef struct { double _m[9]; } comet_mat3;"

local abs, atan2, sqrt, epsilon = math.abs, math.atan2, math.sqrt, math.epsilon

---@class comet.math.Transform
local Transform = {}
Transform.__index = Transform

local _new = ffi.typeof("comet_mat3")
local impl = {new = function(_)
    local v = _new()
    v._m[0], v._m[1], v._m[2] = 1, 0, 0
    v._m[3], v._m[4], v._m[5] = 0, 1, 0
    v._m[6], v._m[7], v._m[8] = 0, 0, 1
    return v
end}
impl.mt = Transform

function Transform:reset()
    local m = self._m
    m[0], m[1], m[2] = 1, 0, 0
    m[3], m[4], m[5] = 0, 1, 0
    m[6], m[7], m[8] = 0, 0, 1
    return self
end

function Transform:translate(x, y)
    local m = self._m
    m[6] = m[6] + m[0] * x + m[3] * y
    m[7] = m[7] + m[1] * x + m[4] * y
    return self
end

function Transform:scale(sx, sy)
    local m = self._m
    m[0] = m[0] * sx
    m[1] = m[1] * sx
    m[3] = m[3] * sy
    m[4] = m[4] * sy
    return self
end

function Transform:rotate(r)
    local m = self._m
    local cosr, sinr = math.cos(r), math.sin(r)
    local a, b, c, d = m[0], m[1], m[3], m[4]

    m[0] = cosr * a - sinr * b
    m[1] = sinr * a + cosr * b
    m[3] = cosr * c - sinr * d
    m[4] = sinr * c + cosr * d

    return self
end

function Transform:transformPoint(x, y)
    local m = self._m
    return x * m[0] + y * m[3] + m[6],
           x * m[1] + y * m[4] + m[7]
end

function Transform:apply(other)
    local a = self._m
    local b = other._m

    -- cache a values because we’re overwriting in-place
    local a0,a1,a3,a4,a6,a7 = a[0],a[1],a[3],a[4],a[6],a[7]

    -- multiply 2x2 rotation/scale part
    a[0] = a0*b[0] + a3*b[1]
    a[1] = a1*b[0] + a4*b[1]
    a[3] = a0*b[3] + a3*b[4]
    a[4] = a1*b[3] + a4*b[4]

    -- multiply translation
    a[6] = a0*b[6] + a3*b[7] + a6
    a[7] = a1*b[6] + a4*b[7] + a7

    return self
end

function Transform:getRenderValues()
    local m = self._m
    local a, b, c, d = m[0], m[1], m[3], m[4]

    local sx = sqrt(a * a + b * b)
    local sy = sqrt(c * c + d * d)

    if sx < epsilon then sx = 0 end
    if sy < epsilon then sy = 0 end

    local det = a * d - b * c
    local mirrorX, mirrorY = false, false

    if det < -epsilon then
        if abs(a * d) > abs(b * c) then
            mirrorX = true
        else
            mirrorY = true
        end
    end
    local r = atan2(b, a)
    if mirrorX then
        sx = -sx
        r = r + math.pi
    elseif mirrorY then
        sy = -sy
        r = -r
    end
    return m[6], m[7], r, sx, sy
end

ffi.metatype("comet_mat3", impl.mt)
return impl
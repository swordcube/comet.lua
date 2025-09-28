local Signal = cometreq("util.signal") --- @type comet.util.Signal

--- @class comet.gfx.Tween : comet.core.Object
local Tween = Class("Tween", ...)

-- eases taken from https://github.com/kikito/tween.lua/blob/master/tween.lua#L42
local pow, sin, cos, pi, sqrt, abs, asin = math.pow, math.sin, math.cos, math.pi, math.sqrt, math.abs, math.asin

-- linear
local function linear(t, b, c, d) return c * t / d + b end

-- quad
local function inQuad(t, b, c, d) return c * pow(t / d, 2) + b end
local function outQuad(t, b, c, d)
    t = t / d
    return -c * t * (t - 2) + b
end
local function inOutQuad(t, b, c, d)
    t = t / d * 2
    if t < 1 then return c / 2 * pow(t, 2) + b end
    return -c / 2 * ((t - 1) * (t - 3) - 1) + b
end
local function outInQuad(t, b, c, d)
    if t < d / 2 then return outQuad(t * 2, b, c / 2, d) end
    return inQuad((t * 2) - d, b + c / 2, c / 2, d)
end

-- cubic
local function inCubic(t, b, c, d) return c * pow(t / d, 3) + b end
local function outCubic(t, b, c, d) return c * (pow(t / d - 1, 3) + 1) + b end
local function inOutCubic(t, b, c, d)
    t = t / d * 2
    if t < 1 then return c / 2 * t * t * t + b end
    t = t - 2
    return c / 2 * (t * t * t + 2) + b
end
local function outInCubic(t, b, c, d)
    if t < d / 2 then return outCubic(t * 2, b, c / 2, d) end
    return inCubic((t * 2) - d, b + c / 2, c / 2, d)
end

-- quart
local function inQuart(t, b, c, d) return c * pow(t / d, 4) + b end
local function outQuart(t, b, c, d) return -c * (pow(t / d - 1, 4) - 1) + b end
local function inOutQuart(t, b, c, d)
    t = t / d * 2
    if t < 1 then return c / 2 * pow(t, 4) + b end
    return -c / 2 * (pow(t - 2, 4) - 2) + b
end
local function outInQuart(t, b, c, d)
    if t < d / 2 then return outQuart(t * 2, b, c / 2, d) end
    return inQuart((t * 2) - d, b + c / 2, c / 2, d)
end

-- quint
local function inQuint(t, b, c, d) return c * pow(t / d, 5) + b end
local function outQuint(t, b, c, d) return c * (pow(t / d - 1, 5) + 1) + b end
local function inOutQuint(t, b, c, d)
    t = t / d * 2
    if t < 1 then return c / 2 * pow(t, 5) + b end
    return c / 2 * (pow(t - 2, 5) + 2) + b
end
local function outInQuint(t, b, c, d)
    if t < d / 2 then return outQuint(t * 2, b, c / 2, d) end
    return inQuint((t * 2) - d, b + c / 2, c / 2, d)
end

-- sine
local function inSine(t, b, c, d) return -c * cos(t / d * (pi / 2)) + c + b end
local function outSine(t, b, c, d) return c * sin(t / d * (pi / 2)) + b end
local function inOutSine(t, b, c, d) return -c / 2 * (cos(pi * t / d) - 1) + b end
local function outInSine(t, b, c, d)
    if t < d / 2 then return outSine(t * 2, b, c / 2, d) end
    return inSine((t * 2) - d, b + c / 2, c / 2, d)
end

-- expo
local function inExpo(t, b, c, d)
    if t == 0 then return b end
    return c * pow(2, 10 * (t / d - 1)) + b - c * 0.001
end
local function outExpo(t, b, c, d)
    if t == d then return b + c end
    return c * 1.001 * (-pow(2, -10 * t / d) + 1) + b
end
local function inOutExpo(t, b, c, d)
    if t == 0 then return b end
    if t == d then return b + c end
    t = t / d * 2
    if t < 1 then return c / 2 * pow(2, 10 * (t - 1)) + b - c * 0.0005 end
    return c / 2 * 1.0005 * (-pow(2, -10 * (t - 1)) + 2) + b
end
local function outInExpo(t, b, c, d)
    if t < d / 2 then return outExpo(t * 2, b, c / 2, d) end
    return inExpo((t * 2) - d, b + c / 2, c / 2, d)
end

-- circ
local function inCirc(t, b, c, d) return (-c * (sqrt(1 - pow(t / d, 2)) - 1) + b) end
local function outCirc(t, b, c, d) return (c * sqrt(1 - pow(t / d - 1, 2)) + b) end
local function inOutCirc(t, b, c, d)
    t = t / d * 2
    if t < 1 then return -c / 2 * (sqrt(1 - t * t) - 1) + b end
    t = t - 2
    return c / 2 * (sqrt(1 - t * t) + 1) + b
end
local function outInCirc(t, b, c, d)
    if t < d / 2 then return outCirc(t * 2, b, c / 2, d) end
    return inCirc((t * 2) - d, b + c / 2, c / 2, d)
end

-- elastic
local function calculatePAS(p, a, c, d)
    p, a = p or d * 0.3, a or 0
    if a < abs(c) then return p, c, p / 4 end -- p, a, s
    return p, a, p / (2 * pi) * asin(c / a) -- p,a,s
end
local function inElastic(t, b, c, d, a, p)
    local s
    if t == 0 then return b end
    t = t / d
    if t == 1 then return b + c end
    p, a, s = calculatePAS(p, a, c, d)
    t = t - 1
    return -(a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
end
local function outElastic(t, b, c, d, a, p)
    local s
    if t == 0 then return b end
    t = t / d
    if t == 1 then return b + c end
    p, a, s = calculatePAS(p, a, c, d)
    return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p) + c + b
end
local function inOutElastic(t, b, c, d, a, p)
    local s
    if t == 0 then return b end
    t = t / d * 2
    if t == 2 then return b + c end
    p, a, s = calculatePAS(p, a, c, d)
    t = t - 1
    if t < 0 then return -0.5 * (a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b end
    return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p) * 0.5 + c + b
end
local function outInElastic(t, b, c, d, a, p)
    if t < d / 2 then return outElastic(t * 2, b, c / 2, d, a, p) end
    return inElastic((t * 2) - d, b + c / 2, c / 2, d, a, p)
end

-- back
local function inBack(t, b, c, d, s)
    s = s or 1.70158
    t = t / d
    return c * t * t * ((s + 1) * t - s) + b
end
local function outBack(t, b, c, d, s)
    s = s or 1.70158
    t = t / d - 1
    return c * (t * t * ((s + 1) * t + s) + 1) + b
end
local function inOutBack(t, b, c, d, s)
    s = (s or 1.70158) * 1.525
    t = t / d * 2
    if t < 1 then return c / 2 * (t * t * ((s + 1) * t - s)) + b end
    t = t - 2
    return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
end
local function outInBack(t, b, c, d, s)
    if t < d / 2 then return outBack(t * 2, b, c / 2, d, s) end
    return inBack((t * 2) - d, b + c / 2, c / 2, d, s)
end

-- bounce
local function outBounce(t, b, c, d)
    t = t / d
    if t < 1 / 2.75 then return c * (7.5625 * t * t) + b end
    if t < 2 / 2.75 then
        t = t - (1.5 / 2.75)
        return c * (7.5625 * t * t + 0.75) + b
    elseif t < 2.5 / 2.75 then
        t = t - (2.25 / 2.75)
        return c * (7.5625 * t * t + 0.9375) + b
    end
    t = t - (2.625 / 2.75)
    return c * (7.5625 * t * t + 0.984375) + b
end
local function inBounce(t, b, c, d) return c - outBounce(d - t, 0, c, d) + b end
local function inOutBounce(t, b, c, d)
    if t < d / 2 then return inBounce(t * 2, 0, c, d) * 0.5 + b end
    return outBounce(t * 2 - d, 0, c, d) * 0.5 + c * .5 + b
end
local function outInBounce(t, b, c, d)
    if t < d / 2 then return outBounce(t * 2, b, c / 2, d) end
    return inBounce((t * 2) - d, b + c / 2, c / 2, d)
end

local easingMap = {
    linear = linear,
    inQuad = inQuad,
    outQuad = outQuad,
    inOutQuad = inOutQuad,
    outInQuad = outInQuad,
    inCubic = inCubic,
    outCubic = outCubic,
    inOutCubic = inOutCubic,
    outInCubic = outInCubic,
    inQuart = inQuart,
    outQuart = outQuart,
    inOutQuart = inOutQuart,
    outInQuart = outInQuart,
    inQuint = inQuint,
    outQuint = outQuint,
    inOutQuint = inOutQuint,
    outInQuint = outInQuint,
    inSine = inSine,
    outSine = outSine,
    inOutSine = inOutSine,
    outInSine = outInSine,
    inExpo = inExpo,
    outExpo = outExpo,
    inOutExpo = inOutExpo,
    outInExpo = outInExpo,
    inCirc = inCirc,
    outCirc = outCirc,
    inOutCirc = inOutCirc,
    outInCirc = outInCirc,
    inElastic = inElastic,
    outElastic = outElastic,
    inOutElastic = inOutElastic,
    outInElastic = outInElastic,
    inBack = inBack,
    outBack = outBack,
    inOutBack = inOutBack,
    outInBack = outInBack,
    inBounce = inBounce,
    outBounce = outBounce,
    inOutBounce = inOutBounce,
    outInBounce = outInBounce
}

function Tween:__init__(tweenManager)
    self.exists = true
    
    self.time = 0 --- @type number
    self.duration = 0 --- @type number
    self.currentTargets = {} --- @type table
    self.startValues = {} --- @type table
    self.properties = {} --- @type table
    self.ease = easingMap.linear --- @type function

    ---
    --- The type the tween, determines how it behaves
    --- when reaching the end
    --- 
    --- - `oneshot`: Stops and removes itself from its core container when it finishes
    --- - `persist`: Like `oneshot`, but after it finishes you may call `start()` again
    --- - `backward`: Like `oneshot`, but plays in the reverse direction
    --- - `looping`: Restarts immediately when it finishes
    --- - `pingpong`: Like `looping`, but every second execution is in reverse direction
    ---
    self.type = "oneshot" --- @type "oneshot"|"persist"|"backward"|"looping"|"pingpong"

    self.paused = false
    self.reversed = false
    self.tweenManager = tweenManager or TweenManager.instance --- @type comet.plugins.TweenManager

    --- Signal that gets emitted when the tween updates
    ---
    --- This signal has the following attached to it's listeners:
    --- `tween`
    self.onUpdate = Signal:new() --- @type comet.util.Signal

    --- Signal that gets emitted when the tween finishes/loops
    --- 
    --- This signal has the following attached to it's listeners:
    --- `tween`
    self.onComplete = Signal:new() --- @type comet.util.Signal
end

--- @param object any
function Tween.cancelTweensOf(object)
    local toRemove = {}
    for i = 1, #TweenManager.instance.tweens.children do
        local tween = TweenManager.instance.tweens.children[i] --- @type comet.gfx.Tween
        if table.contains(tween.currentTargets, object) then
            table.insert(toRemove, tween)
        end
    end
    for i = 1, #toRemove do
        TweenManager.instance.tweens:removeChild(toRemove[i])
    end
end

--- Determines the target object and target properties of the tween
--- 
--- Will target nothing if no parameters are given
--- 
--- @param params? {target: any, properties: string[]}
function Tween:target(params)
    if params then
        if params.target then
            table.insert(self.currentTargets, params.target)
        end
        self.startValues[#self.currentTargets] = {}
        if params.properties then
            self.properties[#self.currentTargets] = params.properties
            local startValues = self.startValues[#self.currentTargets]
            for key, _ in pairs(self.properties[#self.currentTargets]) do
                startValues[key] = params.target[key]
            end
        else
            self.properties[#self.currentTargets] = {}
        end
    end
    return self
end

--- Starts the tween
--- 
--- @param params? {delay: number, duration: number, ease: string, type: "oneshot"|"persist"|"backward"|"looping"|"pingpong"}
function Tween:start(params)
    if not params then
        self.time = -self.delay
        self.paused = false
        self.reversed = self.type == "backward"
        return self
    end
    if params.target and params.properties then
        self:target(params)
    end
    self.delay = params.delay or 0.0
    self.time = -self.delay
    self.duration = params.duration or 0.0
    self.ease = easingMap[params.ease] or easingMap.linear
    self.type = params.type or "oneshot"
    self.paused = false
    self.reversed = self.type == "backward"
    self.tweenManager.tweens:addChild(self)
    return self
end

function Tween:pause()
    self.paused = true
    return self
end

function Tween:resume()
    self.paused = false
    return self
end

function Tween:getProgress()
    if self.duration <= 0 then
        return 1 -- cut the chase and skip to the end
    end
    if self.time <= 0 then
        return 0 -- assume start delay and use zero
    end
    return math.min(self.time / self.duration, 1)
end

function Tween:update(dt)
    if self.paused then
        return
    end
    self.time = self.time + dt
    if self.time > self.duration then
        self.time = self.duration
    end
    local progress = self:getProgress()
    for i = 1, #self.currentTargets do
        local target = self.currentTargets[i]
        for key, value in pairs(self.properties[i]) do
            -- TODO: handle table values
            local start = self.startValues[i][key]
            target[key] = self.ease(math.max(self.time, 0.0), start, value - start, self.duration)
        end
    end
    self.onUpdate:emit(self)
    
    if progress >= 1 then
        if self.type == "oneshot" then
            self:destroy()
        
        elseif self.type == "backward" then
            self.reversed = not self.reversed
        
        elseif self.type == "looping" then
            self.time = 0
        
        elseif self.type == "pingpong" then
            self.reversed = not self.reversed
            self.time = -self.delay
        end
        self.onComplete:emit(self)
    end
    if self.reversed then
        progress = 1 - progress
    end
end
Tween._update = Tween.update

function Tween:shouldUpdate()
    return true
end

function Tween:destroy()
    self.tweenManager.tweens:removeChild(self)
end

return Tween
local Signal = cometreq("util.signal") --- @type comet.util.Signal

--- @class comet.util.Timer : comet.util.Class
local Timer = Class:extend("Timer", ...)

function Timer:__init__()
    self.exists = true
    self.active = false
    self.paused = false

    self.onComplete = Signal:new():type("comet.util.Timer", "void") --- @type comet.util.Signal
    
    --- The current time of the timer.
    self.time = 0.0 --- @type number
    
    --- The duration of the timer.
    self.duration = 0.0 --- @type number

    --- The amount of times this timer should loop for.
    self.loops = 0 --- @type integer

    --- The amount of loops left before this timer stops.
    self.loopsLeft = 0 --- @type integer
end

function Timer:getProgress()
    return self.time / self.duration
end

--- @param duration  number    The duration of the timer
--- @param func      function  The function to call when the timer finishes/loops
--- @return comet.util.Timer
function Timer.wait(duration, func)
    local t = Timer:new() --- @type comet.util.Timer
    t:start(duration, func)
    return t
end

--- @param duration  number    The duration of the timer
--- @param func      function  The function to call when the timer finishes/loops
--- @param loops     integer?  Determines how many times this timer should loop. 0 means infinite looping
--- @return comet.util.Timer
function Timer.loop(duration, func, loops)
    local t = Timer:new() --- @type comet.util.Timer
    t:start(duration, func, loops)
    return t
end

--- @param duration  number    The duration of the timer
--- @param func      function  The function to call when the timer finishes/loops
--- @param loops     integer?  Determines how many times this timer should loop. 0 means infinite looping
--- @return comet.util.Timer
function Timer:start(duration, func, loops)
    self.time = 0.0
    self.duration = math.max(duration or 0.0, math.epsilon) -- for some reason having 0 duration will cause the game to freeze??? tf???

    self.loops = loops or 1
    self.loopsLeft = self.loops

    self.active = true
    self.paused = false
    
    if func then
        self.onComplete:connect(func)
    end
    TimerManager.instance.timers:addChild(self)
    return self
end

function Timer:update(dt)
    if not self.active or self.paused then
        return
    end
    self.time = self.time + dt
    while self.time >= self.duration do
        self.time = self.time - self.duration
        if self.loops ~= 0 then
            self.loopsLeft = self.loopsLeft - 1
        else
            self.loopsLeft = 9999999
        end
        self.onComplete:emit(self)

        if self.loopsLeft <= 0 then
            self:cancel()
            break
        end
    end
end
Timer._update = Timer.update

function Timer:shouldUpdate()
    return true
end

function Timer:cancel()
    self.active = false
    self.paused = true
    self:destroy()
end

function Timer:destroy()
    TimerManager.instance.timers:removeChild(self)
end

return Timer
local Signal = cometreq("util.signal") --- @type comet.util.Signal

--- @class comet.util.Timer : comet.util.Class
local Timer = Class("Timer")

function Timer:__init__()
    self.active = false
    self.paused = false

    self.onComplete = Signal:new():type("comet.util.Timer", "void") --- @type comet.util.Signal
    
    --- @type number
    self._time = 0.0 --- @protected
    
    --- @type number
    self._duration = 0.0 --- @protected

    --- @type integer
    self._loops = 0 --- @protected

    --- @type integer
    self._loopsLeft = 0 --- @protected
end

function Timer:getTime()
    return self._time
end

function Timer:getDuration()
    return self._duration
end

function Timer:getProgress()
    return self._time / self._duration
end

--- @param duration  number    The duration of the timer
--- @param func      function  The function to call when the timer finishes/loops
function Timer.wait(duration, func)
    local t = Timer:new() --- @type comet.util.Timer
    t:start(duration, func)
end

--- @param duration  number    The duration of the timer
--- @param func      function  The function to call when the timer finishes/loops
--- @param loops     integer?  Determines how many times this timer should loop. 0 means infinite looping
function Timer.loop(duration, func, loops)
    local t = Timer:new() --- @type comet.util.Timer
    t:start(duration, func, loops)
end

--- @param duration  number    The duration of the timer
--- @param func      function  The function to call when the timer finishes/loops
--- @param loops     integer?  Determines how many times this timer should loop. 0 means infinite looping
--- @return comet.util.Timer
function Timer:start(duration, func, loops)
    self._time = 0.0
    self._duration = duration

    self._loops = loops or 1
    self._loopsLeft = self._loops

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
    self._time = self._time + dt
    while self._time >= self._duration do
        self._time = self._time - self._duration
        if self._loops ~= 0 then
            self._loopsLeft = self._loopsLeft - 1
        else
            self._loopsLeft = 9999999
        end
        self.onComplete:emit(self)

        if self._loopsLeft <= 0 then
            self:destroy()
        end
    end
end
Timer._update = Timer.update

function Timer:destroy()
    TimerManager.instance.timers:removeChild(self)
end

return Timer
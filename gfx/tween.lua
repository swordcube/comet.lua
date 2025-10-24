local Signal = cometreq("util.signal") --- @type comet.util.Signal

--- @class comet.gfx.Tween : comet.core.Object
local Tween = Class:extend("Tween", ...)

function Tween:__init__(tweenManager)
    self.exists = true
    
    self.time = 0 --- @type number
    self.duration = 0 --- @type number
    self.currentTargets = {} --- @type table
    self.startValues = {} --- @type table
    self.properties = {} --- @type table
    self.ease = Ease.linear --- @type function

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
    self.ease = Ease[params.ease] or Ease.linear
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

function Tween:getEasedProgress()
    return self.ease(math.clamp(self.time / self.duration, 0, 1))
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
            target[key] = math.lerp(start, value, self:getEasedProgress())
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

function Tween:cancel()
    self.active = false
    self.paused = true
    self:destroy()
end

function Tween:destroy()
    self.tweenManager.tweens:removeChild(self)
end

return Tween
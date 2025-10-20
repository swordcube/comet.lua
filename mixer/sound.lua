local Signal = cometreq("util.signal") --- @type comet.util.Signal

--- @class comet.mixer.Sound : comet.util.Class
local Sound = Class("Sound", ...)

function Sound:__init__()
    self.exists = true

    --- Whether or not this sound should be auto-destroyed
    --- when it finishes playing.
    self.autoDestroy = true

    --- Signal that gets emitted when the sound finishes playing.
    self.onComplete = Signal:new() --- @type comet.util.Signal

    --- @protected
    self._source = nil --- @type comet.mixer.Source

    --- @protected
    self._loveSource = nil --- @type love.Source

    --- @protected
    self._playing = false

    --- @protected
    self._fadeTween = nil --- @type comet.gfx.Tween

    if comet.mixer then
        comet.mixer.sounds:addChild(self)
    end
end

function Sound:getSource()
    return self._source
end

function Sound:getLoveSource()
    return self._loveSource
end

function Sound:setSource(src)
    if self._source then
        self._source:dereference()
    end
    if self._loveSource then
        self._loveSource:release()
    end
    if type(src) == "string" then
        src = comet.mixer:getSource(src)
    end
    self._source = src
    self._source:reference()
    
    self._loveSource = src.data:clone()
end

function Sound:getTime()
    local src = self._loveSource
    if not src then
        return 0.0
    end
    return src:tell("seconds") * 1000.0
end

function Sound:tell()
    return self:getTime()
end

function Sound:setTime(t)
    local src = self._loveSource
    if not src then
        return
    end
    src:seek(t / 1000.0, "seconds")
end

function Sound:seek(t)
    self:setTime(t)
end

function Sound:getDuration()
    local src = self._loveSource
    if not src then
        return 0.0
    end
    return src:getDuration("seconds") * 1000.0
end

function Sound:getVolume()
    local src = self._loveSource
    if not src then
        return 0.0
    end
    return src:getVolume()
end

function Sound:setVolume(v)
    local src = self._loveSource
    if not src then
        return
    end
    src:setVolume(v)
end

function Sound:getPitch()
    local src = self._loveSource
    if not src then
        return 0.0
    end
    return src:getPitch()
end

function Sound:setPitch(p)
    local src = self._loveSource
    if not src then
        return
    end
    src:setPitch(math.clamp(p, 0.001, 1000.0))
end

function Sound:isLooping()
    local src = self._loveSource
    if not src then
        return false
    end
    return src:isLooping()
end

function Sound:setLooping(looping)
    local src = self._loveSource
    if not src then
        return
    end
    src:setLooping(looping)
end

function Sound:isPlaying()
    local src = self._loveSource
    if not src then
        return false
    end
    return src:isPlaying()
end

function Sound:play()
    local src = self._loveSource
    if not src then
        return
    end
    self._playing = true
    src:play()
end

function Sound:stop()
    local src = self._loveSource
    if not src then
        return
    end
    self._playing = false
    src:stop()
end

function Sound:pause()
    local src = self._loveSource
    if not src then
        return
    end
    self._playing = false
    src:pause()
end

function Sound:fadeIn(duration, from, to, onComplete)
    if from == nil then
        from = 0
    end
    if to == nil then
        to = 1
    end
    if self._fadeTween then
        self._fadeTween:cancel()
        self._fadeTween = nil
    end
    local temp = {v = from}
    self._fadeTween = Tween:new() --- @type comet.gfx.Tween
    self._fadeTween:target({target = temp, properties = {v = to}})
    self._fadeTween.onUpdate:connect(function(t)
        self:setVolume(temp.v)
    end)
    if onComplete then
        self._fadeTween.onComplete:connect(onComplete)
    end
    self._fadeTween:start({duration = duration})
end

function Sound:fadeOut(duration, to, onComplete)
    if duration == nil then
        duration = 1
    end
    if to == nil then
        to = 0
    end
    if self._fadeTween then
        self._fadeTween:cancel()
        self._fadeTween = nil
    end
    local temp = {v = self:getVolume()}
    self._fadeTween = Tween:new() --- @type comet.gfx.Tween
    self._fadeTween:target({target = temp, properties = {v = to}})
    self._fadeTween.onUpdate:connect(function(t)
        self:setVolume(temp.v)
    end)
    if onComplete then
        self._fadeTween.onComplete:connect(onComplete)
    end
    self._fadeTween:start({duration = duration})
end

function Sound:update(dt)
    if self._playing and not self:isPlaying() and not self:isLooping() then
        self:stop()
        self.onComplete:emit(self)

        if self.autoDestroy then
            self:destroy()
        end
    end
end
Sound._update = Sound.update

function Sound:shouldUpdate()
    return true
end

function Sound:destroy()
    local twn = self._fadeTween
    if twn then
        twn:cancel()
        self._fadeTween = nil
    end
    local src = self._source
    if src then
        src:dereference()
        self._source = nil
    end
    local lsrc = self._loveSource
    if lsrc then
        lsrc:stop()
        lsrc:release()
        self._loveSource = nil
    end
    comet.mixer.sounds:removeChild(self)
end

return Sound
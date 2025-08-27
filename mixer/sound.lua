local Signal = cometreq("util.signal") --- @type comet.util.Signal

--- @class comet.mixer.Sound : comet.util.Class
local Sound = Class("Sound")

function Sound:__init__()
    --- Whether or not this sound should be auto-destroyed
    --- when it finishes playing.
    self.autoDestroy = true

    --- Signal that gets emitted when the sound finishes playing.
    self.onComplete = Signal:new() --- @type comet.util.Signal

    --- @protected
    self._source = nil --- @type comet.mixer.Source

    --- @protected
    self._playing = false

    if comet.mixer then
        comet.mixer.sounds:addChild(self)
    end
end

function Sound:getSource()
    return self._source
end

function Sound:setSource(src)
    if type(src) == "string" then
        src = comet.mixer:getSource(src)
    end
    if self._source then
        self._source:dereference()
    end
    self._source = src
end

function Sound:destroy()
    if self._source then
        self._source:dereference()
        self._source = nil
    end
end

function Sound:getTime()
    local src = self._source
    if not src then
        return 0.0
    end
    return src.data:tell("seconds") * 1000.0
end

function Sound:tell()
    return self:getTime()
end

function Sound:setTime(t)
    local src = self._source
    if not src then
        return
    end
    src.data:seek(t / 1000.0, "seconds")
end

function Sound:seek(t)
    self:setTime(t)
end

function Sound:getDuration()
    local src = self._source
    if not src then
        return 0.0
    end
    return src.data:getDuration("seconds") * 1000.0
end

function Sound:getVolume()
    local src = self._source
    if not src then
        return 0.0
    end
    return src.data:getVolume()
end

function Sound:setVolume(v)
    local src = self._source
    if not src then
        return
    end
    src.data:setVolume(v)
end

function Sound:getPitch()
    local src = self._source
    if not src then
        return 0.0
    end
    return src.data:getPitch()
end

function Sound:setPitch(p)
    local src = self._source
    if not src then
        return
    end
    src.data:setPitch(p)
end

function Sound:isLooping()
    local src = self._source
    if not src then
        return false
    end
    return src.data:isLooping()
end

function Sound:setLooping(looping)
    local src = self._source
    if not src then
        return
    end
    src.data:setLooping(looping)
end

function Sound:isPlaying()
    local src = self._source
    if not src then
        return false
    end
    return src.data:isPlaying()
end

function Sound:play()
    local src = self._source
    if not src then
        return
    end
    self._playing = true
    src.data:play()
end

function Sound:stop()
    local src = self._source
    if not src then
        return
    end
    if src.data:isPlaying() then
        src.data:stop()
    end
    self._playing = false
end

function Sound:pause()
    local src = self._source
    if not src then
        return
    end
    self._playing = false
    src.data:pause()
end

function Sound:update(dt)
    if self._playing and not self:isPlaying() and not self:isLooping() then
        self:stop()
        self.onComplete:emit()

        if self.autoDestroy then
            self:destroy()
        end
    end
end

function Sound:destroy()
    local src = self._source
    if src then
        src:dereference()
        self._source = nil
    end
    comet.mixer.sounds:removeChild(self)
end

return Sound
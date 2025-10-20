local Class = cometreq("util.class") --- @type comet.util.Class

--- @class comet.modules.mixer
local mixer = Class("comet.modules.mixer", ...)

function mixer:__init__()
    self._volume = 1.0 --- @protected
    self._muted = false --- @protected

    self.sounds = Object:new() --- @type comet.core.Object
    self.sounds.updateMode = "always"

    self.music = Sound:new() --- @type comet.mixer.Sound
    self.music.autoDestroy = false

    --- @type table
    self._sourceCache = {} --- @protected
end

function mixer:load(src, volume, looping)
    if type(src) == "string" then
        src = self:getSource(src)
    end
    local sound = Sound:new() --- @type comet.mixer.Sound
    sound:setSource(src)
    sound:setVolume(volume ~= nil and volume or 1.0)
    sound:setLooping(looping ~= nil and looping or false)
    return sound
end

function mixer:play(src, volume, looping)
    local sound = self:load(src, volume, looping)
    sound:play()
    return sound
end

function mixer:getMasterVolume()
    return self._volume
end

function mixer:setMasterVolume(volume)
    self._volume = volume
    love.audio.setVolume(volume * (self._muted and 0.0 or 1.0))
end

function mixer:isMasterMuted()
    return self._muted
end

function mixer:muteMaster()
    self._muted = true
    love.audio.setVolume(0.0)
end

function mixer:unmuteMaster()
    self._muted = false
    love.audio.setVolume(self._volume)
end

--- @param  filePath  string
function mixer:getSource(filePath)
    if not self._sourceCache[filePath] then
        self._sourceCache[filePath] = Source:new(filePath, filePath)
    end
    return self._sourceCache[filePath]
end

--- @param  source  comet.mixer.Source
function mixer:removeSource(source)
    if not source._destroyed then
        source:destroy()
    end
    self._sourceCache[source.key] = nil
end

function mixer:update(dt)
    self.music:update(dt)
    self.sounds:_update(dt)
end

return mixer
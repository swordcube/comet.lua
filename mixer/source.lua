local RefCounted = cometreq("core.refcounted") --- @type comet.core.RefCounted

--- @class comet.mixer.Source : comet.core.RefCounted
--- A basic object for storing a audio source.
local Source, super = RefCounted:subclass("Source")

function Source:__init__(data, key)
    super.__init__(self)
    if data then
        self.data = love.audio.newSource(data, "static")
    end
    self.key = key
    self._destroyed = false
end

function Source:destroy()
    if self._destroyed then
        return
    end
    if self.data then
        self.data:release()
        self.data = nil
    end
    self._destroyed = true
    comet.mixer:removeSource(self)
end

return Source
--- @class comet.core.RefCounted : comet.util.Class
local RefCounted = Class("RefCounted", ...)

function RefCounted:__init__()
    --- @type integer
    self._refs = 0 --- @protected

    --- @type boolean
    self._destroyed = false --- @protected
end

function RefCounted:getReferences()
    return self._refs
end

function RefCounted:reference()
    self._refs = self._refs + 1
end

function RefCounted:dereference()
    self._refs = self._refs - 1
    if self._refs <= 0 and not self._destroyed then
        self._destroyed = true
        self:destroy()
    end
end

function RefCounted:destroy() end

return RefCounted
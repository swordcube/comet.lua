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

function RefCounted:dereference(checkRefs)
    if checkRefs == nil then
        checkRefs = true
    end
    self._refs = self._refs - 1
    if checkRefs then
        self:checkRefs()
    end
end

--- Checks if there are no more references to this object and destroys it if so.
function RefCounted:checkRefs()
    if self._refs <= 0 and not self._destroyed then
        self:destroy()
        self._destroyed = true
    end
end

function RefCounted:destroy() end

return RefCounted
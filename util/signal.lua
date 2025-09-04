local Class = cometreq("util.class") --- @type comet.util.Class

--- @class comet.util.Signal : comet.util.Class
local Signal = Class("Signal")

function Signal:__init__()
    self.listeners = {}
end

--- Syntax sugar function, can be used to describe what this signal takes in and returns
--- @return comet.util.Signal
function Signal:type(...)
    return self
end

---
--- Connects a listener to this signal
---
--- @param listener function  The listener to connect
--- @param once     boolean?  Whether or not to call the listener only once
---
function Signal:connect(listener, once)
    once = once ~= nil and once or false
    table.insert(self.listeners, {method = listener, once = once})
end

---
--- Disconnects a listener from this signal
---
--- @param listener function  The listener to disconnect
---
function Signal:disconnect(listener)
    for i = 1, #self.listeners do
        if self.listeners[i].method == listener then
            table.remove(self.listeners, i)
            break
        end
    end
end

function Signal:disconnectAll()
    self.listeners = {}
end

function Signal:emit(...)
    local deadListeners = {}
    for i = 1, #self.listeners do
        local listener = self.listeners[i]
        listener.method(...)
        if listener.once then
            listener.__index = i
            table.insert(deadListeners, listener)
        end
    end
    if #deadListeners > 0 then
        for i = 1, #deadListeners do
            table.remove(self.listeners, deadListeners[i].__index)
        end
        deadListeners = nil
    end
end

return Signal
local Class = cometreq("util.class") --- @type comet.util.Class

--- @class comet.util.Signal : comet.util.Class
local Signal = Class:extend("Signal", ...)

function Signal:__init__()
    self.listeners = {}
    self.cancelled = false
end

function Signal:cancel()
    self.cancelled = true
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
--- @param priority integer?  The priority of the listener (optional, lower values mean higher priority)
---
function Signal:connect(listener, once, priority)
    once = once ~= nil and once or false
    priority = priority ~= nil and priority or -1

    if priority < 0 then
        table.insert(self.listeners, {method = listener, once = once})
    else
        table.insert(self.listeners, priority, {method = listener, once = once})
    end
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
    self.cancelled = false
    local deadListeners = {}
    for i = 1, #self.listeners do
        local listener = self.listeners[i]
        if listener then
            listener.method(...)
        end
        if self.cancelled then
            break
        end
        if listener and listener.once then
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
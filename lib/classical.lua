--- @class comet.lib.classical
local classical = {}
classical.__index = classical

function classical:__init__(...) end

function classical:new(...)
    local obj = setmetatable({}, self)
    obj.class = self
    obj.__isinstance = true
    obj:__init__(...)
    return obj
end

function classical:extend(name, path)
    local cls = {
        name = name,
        path = path,
        __isclass = true
    }
    for k, v in pairs(self) do
        if k:find("__") == 1 then
            cls[k] = v
        end
    end
    cls.__index = cls
    cls.super = self
    setmetatable(cls, self)
    return cls, cls.super
end

function classical:implement(...)
    for _, cls in pairs({ ... }) do
        for k, v in pairs(cls) do
            if self[k] == nil and type(v) == "function" then
                self[k] = v
            end
        end
    end
    return self
end

function classical:is(other)
    local mt = getmetatable(self)
    while mt do
        if mt == other then
            return true
        end
        mt = getmetatable(mt)
    end
    return false
end

function classical:__tostring()
    return "Class"
end

function classical.isInstanceOf(cl, other)
    return type(cl) == "table" and cl.__isclass and cl:is(other)
end

return classical

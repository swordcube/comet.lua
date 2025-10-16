-- generic stdlib extensions 

--- @class comet.tools.stdlibtools
local dummy = {}

local _keys_iterator = function(t, k)
    local next_key, _ = next(t, k)
    return next_key
end

--- @brief iterate all keys of a table
function keys(t)
    return _keys_iterator, t
end

--- @brief iterate all values of a table
function values(t)
    local k, v
    return function()
        k, v = next(t, k)
        return v
    end
end

local function _range_iterator(state)
    local next_i, out = next(state, state[1])
    state[1] = next_i
    return out, state
end

function range(...)
    return _range_iterator, {1, ...}
end
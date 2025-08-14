local Class = cometreq("util.class") --- @type comet.util.Class
local Texture = cometreq("gfx.texture") --- @type comet.gfx.Texture

--- @class comet.modules.gfx
local gfx = Class("comet.modules.gfx")

function gfx:__init__()
    --- @type table
    self._cache = {} --- @protected
end

--- @param  filePath  string
function gfx:get(filePath)
    if not self._cache[filePath] then
        self._cache[filePath] = Texture:new(filePath, filePath)
    end
    return self._cache[filePath]
end

--- @param  texture  comet.gfx.Texture
function gfx:remove(texture)
    if not texture._destroyed then
        texture:destroy()
    end
    self._cache[texture.key] = nil
end

return gfx
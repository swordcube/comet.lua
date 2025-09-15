local Class = cometreq("util.class") --- @type comet.util.Class
local Texture = cometreq("gfx.texture") --- @type comet.gfx.Texture

--- @class comet.modules.gfx
local gfx = Class("comet.modules.gfx")

function gfx:__init__()
    --- @type table
    self._cache = {} --- @protected
end

--- @param  filePath  string
--- @return comet.gfx.Texture
function gfx:getTexture(filePath)
    if not self._cache[filePath] then
        self._cache[filePath] = Texture:new(filePath, filePath)
    end
    return self._cache[filePath]
end

--- @deprecated
--- @param  filePath  string
--- @return comet.gfx.Texture
function gfx:get(filePath)
    Log.warn("comet.gfx:get() is deprecated! use comet.gfx:getTexture() instead!")
    return self:getTexture(filePath)
end

--- @param  texture  comet.gfx.Texture
function gfx:removeTexture(texture)
    if not texture._destroyed then
        texture:destroy()
    end
    self._cache[texture.key] = nil
end

function gfx:remove(texture)
    Log.warn("comet.gfx:remove() is deprecated! use comet.gfx:removeTexture() instead!")
    self:removeTexture(texture)
end

--- Returns a shader either from fragment and vertex shader paths, or a single file name (`res/shaders/ntsc` for example)
--- 
--- NOTE: This returns a new shader on every call! There is no caching!
--- 
--- @param  fragOrName  string?
--- @param  vertOrName  string?
--- @return comet.gfx.Shader
function gfx:getShader(fragOrName, vertOrName)
    local frag = nil
    if love.filesystem.exists(fragOrName) then
        frag = love.filesystem.getContent(fragOrName)
    elseif love.filesystem.exists(fragOrName .. ".frag") then
        frag = love.filesystem.getContent(fragOrName .. ".frag")
    else
        frag = fragOrName
    end
    local vert = nil
    if love.filesystem.exists(vertOrName) then
        vert = love.filesystem.getContent(vertOrName)
    elseif love.filesystem.exists(vertOrName .. ".vert") then
        vert = love.filesystem.getContent(vertOrName .. ".vert")
    else
        vert = vertOrName
    end
    return Shader:new(frag, vert)
end

return gfx
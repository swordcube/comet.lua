local RefCounted = cometreq("core.refcounted") --- @type comet.core.RefCounted

--- @class comet.gfx.Texture : comet.core.RefCounted
--- A basic object for storing a texture.
local Texture, super = RefCounted:subclass("Texture")

local img = love.image
local gfx = love.graphics

function Texture:__init__(image, key)
    super.__init__(self)
    if image then
        local data = type(image) == "string" and img.newImageData(image) or image
        self.linearImage = gfx.newImage(data, {linear = true})
        self.nearestImage = gfx.newImage(data, {linear = false})
    end
    if not key and type(image) == "string" then
        key = image
    end
    self.key = key
    self._destroyed = false
end

--- @param filter "linear"|"nearest"
function Texture:getImage(filter)
    if not filter then
        filter = "nearest"
    end
    if filter == "linear" then
        return self.linearImage
    end
    return self.nearestImage
end

--- Returns the width of this texture.
--- @return number
function Texture:getWidth()
    return self:getImage("nearest"):getWidth()
end

--- Returns the height of this texture.
--- @return number
function Texture:getHeight()
    return self:getImage("nearest"):getHeight()
end

function Texture:destroy()
    if self._destroyed then
        return
    end
    if self.linearImage then
        self.linearImage:release()
        self.linearImage = nil
    end
    if self.nearestImage then
        self.nearestImage:release()
        self.nearestImage = nil
    end
    self._destroyed = true
    comet.gfx:remove(self)
end

return Texture
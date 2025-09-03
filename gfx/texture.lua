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
        self.image = gfx.newImage(data)
        data:release()
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
    self.image:setFilter(filter, filter)
    return self.image
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
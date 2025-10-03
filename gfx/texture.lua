local RefCounted = cometreq("core.refcounted") --- @type comet.core.RefCounted

--- @class comet.gfx.Texture : comet.core.RefCounted
--- A basic object for storing a texture.
local Texture, super = RefCounted:subclass("Texture", ...)

local img = love.image
local gfx = love.graphics

function Texture:__init__(image, key)
    super.__init__(self)
    if image then
        local data = nil --- @type love.ImageData
        if type(image) == "string" then
            if love.filesystem.exists(image) then
                data = img.newImageData(image)
            else
                local size = 16
                local halfSize = size / 2
                data = img.newImageData(size, size)
                for x = 1, size do
                    for y = 1, size do
                        local color = ((x > halfSize and y <= halfSize) or (x <= halfSize and y > halfSize)) and Color.MAGENTA or Color.BLACK
                        data:setPixel(x - 1, y - 1, color:array())
                    end
                end
                Log.warn("Image at " .. image .. " does not exist, generating fallback instead!")
            end
        else
            data = image
        end
        if data:typeOf("Texture") then
            self._loveImage = data
        else
            self._loveImage = gfx.newImage(data)
            data:release()
        end
        self.linearImage = {_type = "FilteredImage", image = self._loveImage, filter = "linear"}
        self.nearestImage = {_type = "FilteredImage", image = self._loveImage, filter = "nearest"}
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
    return self:getImage("nearest").image:getWidth()
end

--- Returns the height of this texture.
--- @return number
function Texture:getHeight()
    return self:getImage("nearest").image:getHeight()
end

function Texture:destroy()
    if self._destroyed then
        return
    end
    if self._loveImage then
        self._loveImage:release()
        self._loveImage = nil
    end
    if self.linearImage then
        -- self.linearImage:release()
        self.linearImage = nil
    end
    if self.nearestImage then
        -- self.nearestImage:release()
        self.nearestImage = nil
    end
    self._destroyed = true
    comet.gfx:removeTexture(self)
end

return Texture
--- @class comet.gfx.Image : comet.gfx.Object2D
--- A basic object for displaying static images.
local Image, super = Object2D:extend("Image", ...)

Image.NO_OFF_SCREEN_CHECKS = false
Image._lastBlendMode = ""
Image._lastAlphaMode = ""

local abs, floor, rad, fastsin, wrap, clamp, min, max = math.abs, math.floor, math.rad, math.fastsin, math.wrap, math.clamp, math.min, math.max
local gfx = love.graphics -- Faster access with local variable

local function preMultiplyChannels(r, g, b, a)
    return r * a, g * a, b * a, a
end

local stencilSprite = nil
local function stencil(tx, ty, tr, tsx, tsy)
	if stencilSprite then
        local cr = stencilSprite.clipRect
        gfx.push()
        gfx.translate(tx, ty)
        gfx.rotate(tr)
        gfx.scale(tsx, tsy)
		gfx.rectangle("fill", cr.x, cr.y, cr.width, cr.height)
        gfx.pop()
	end
end

function Image:__init__(image)
    super.__init__(self)

    self.texture = nil --- @type comet.gfx.Texture
    self:loadTexture(image)

    --- Whether or not to display the image from it's center
    self.centered = true

    --- Whether or not to use antialiasing on this image
    self.antialiasing = true

    --- Alpha multiplier for this image
    self.alpha = 1

    --- Whether or not to horizontally flip this image
    self.flipX = false

    --- Whether or not to vertically flip this image
    self.flipY = false

    --- The blend mode to use for this image
    self.blend = "alpha" --- @type love.BlendMode

    --- The blend alpha mode to use for this image
    self.blendAlpha = "premultiplied" --- @type love.BlendAlphaMode

    --- The clipping rectangle to use for this image
    self.clipRect = nil --- @type comet.math.Rect?

    --- @type comet.gfx.Shader
    self._shader = nil --- @protected

    --- @type comet.gfx.Color
    self._tint = Color:new(1, 1, 1, 1) --- @protected

    --- @type comet.math.Rect
    self._rect = Rect:new() --- @protected
end

function Image:loadTexture(tex)
    assert((type(tex) == "table" and Class.isInstanceOf(tex, Texture)) or type(tex) == "string" or tex == nil, "Image:loadTexture(): You must pass in a texture instance or file path")
    if self.texture then
        self.texture:dereference()
        self.texture = nil
    end
    if tex ~= nil then
        if type(tex) == "string" then
            local filePath = tex
            if not filePath then
                return self
            end
            if self.texture then
                self.texture:dereference()
            end
            self.texture = comet.gfx:getTexture(filePath) --- @type comet.gfx.Texture
        else
            self.texture = tex --- @type comet.gfx.Texture
        end
        self.texture:reference()
    end
    return self
end

function Image:getShader()
    return self._shader
end

--- @param shader comet.gfx.Shader
function Image:setShader(shader)
    assert(type(shader) == "table" and Class.isInstanceOf(shader, Shader), "Image:setShader(): You must pass in a shader instance")
    if self._shader == shader then
        return
    end
    if self._shader then
        self._shader:dereference()
        self._shader = nil
    end
    if not shader then
        return
    end
    self._shader = shader
    self._shader:reference()
end

--- Returns the transform of this image
--- @param accountForParent    boolean?
--- @param accountForCamera    boolean?
--- @param accountForCentering boolean?
--- @return comet.math.Transform
function Image:getTransform(accountForParent, accountForCamera, accountForCentering)
    if accountForParent == nil then
        accountForParent = true
    end
    if accountForCamera == nil then
        accountForCamera = true
    end
    if accountForCentering == nil then
        accountForCentering = false
    end
    local transform = self._transform:reset()
    if accountForParent then
        transform = self:getParentTransform(transform, accountForCamera)
    end

    -- position
    transform:translate(self.position.x + self.offset.x, self.position.y + self.offset.y)
    if accountForCentering and self.centered then
        transform:translate(-abs(self:getWidth()) * 0.5, -abs(self:getHeight()) * 0.5)
    end
    -- origin
    local ox, oy = abs(self:getWidth()) * self.origin.x, abs(self:getHeight()) * self.origin.y
    transform:translate(ox, oy)
    transform:rotate(rad(self.rotation))
    transform:translate(-ox, -oy)

    -- scale
    local ox2, oy2 = abs(self:getOriginalWidth()) * 0.5, abs(self:getOriginalHeight()) * 0.5
    if self.centered then
        transform:scale(abs(self.scale.x), abs(self.scale.y))

        if self.scale.x < -math.epsilon then
            transform:translate(ox2, oy2)
            transform:scale(-1, 1)
            transform:translate(-ox2, -oy2)
        end
        if self.scale.y < -math.epsilon then
            transform:translate(ox2, oy2)
            transform:scale(1, -1)
            transform:translate(-ox2, -oy2)
        end
    else
        transform:scale(self.scale.x, self.scale.y)
    end
    if self.flipX then
        transform:translate(ox2, oy2)
        transform:scale(-1, 1)
        transform:translate(-ox2, -oy2)
    end
    if self.flipY then
        transform:translate(ox2, oy2)
        transform:scale(1, -1)
        transform:translate(-ox2, -oy2)
    end
    return transform
end

--- Returns the bounding box of this image, as a rectangle
--- @param trans comet.math.Transform?   The transform to use for the bounding box (optional)
--- @param rect  comet.math.Rect?  The rectangle to use as the bounding box (optional)
--- @return comet.math.Rect
function Image:getBoundingBox(trans, rect)
    if not trans then
        trans = self:getTransform()
    end
    if not rect then
        rect = Rect:new()
    end
    local w, h = self:getOriginalWidth(), self:getOriginalHeight()
    local x1, y1 = trans:transformPoint(0, 0)
    local x2, y2 = trans:transformPoint(w, 0)
    local x3, y3 = trans:transformPoint(w, h)
    local x4, y4 = trans:transformPoint(0, h)

    local minX = min(x1, x2, x3, x4)
    local minY = min(y1, y2, y3, y4)
    local maxX = max(x1, x2, x3, x4)
    local maxY = max(y1, y2, y3, y4)

    rect:set(minX, minY, maxX - minX, maxY - minY)
    return rect
end

--- Checks if this image is on screen
--- @param box comet.math.Rect?  The bounding box to check with (optional)
function Image:isOnScreen(box)
    if not box then
        box = self:getBoundingBox()
    end
    local p = self.parent
    local camera = nil --- @type comet.gfx.Camera
    while p do
        if p and p:is(Camera) then
            --- @cast p comet.gfx.Camera
            camera = p
            break
        end
        p = p.parent
    end
    local gx, gy, gw, gh = 0, 0, 0, 0
    local bxpw, byph = box.x + box.width, box.y + box.height
    if camera then
        local cameraBox = camera._rect
        gx, gy, gw, gh = cameraBox.x, cameraBox.y, cameraBox.width, cameraBox.height
    else
        gx, gy, gw, gh = 0, 0, comet.getDesiredWidth(), comet.getDesiredHeight()
    end
    if bxpw < gx or box.x > gx + gw or byph < gy or box.y > gy + gh then
        return false
    end
    return true
end

function Image:draw()
    if self.alpha <= 0.0001 or not self.texture then
        return
    end
    local transform = self:getTransform(true, true, true)
    local box = not Image.NO_OFF_SCREEN_CHECKS and self:getBoundingBox(transform, self._rect) or nil
    if box and not self:isOnScreen(box) then
        return
    end
    local pr, pg, pb, pa = gfx.getColor()
    if self.blendAlpha == "premultiplied" then
        gfx.setColor(preMultiplyChannels(self._tint.r * pr, self._tint.g * pg, self._tint.b * pb, self._tint.a * self.alpha * pa))
    else
        gfx.setColor(self._tint.r * pr, self._tint.g * pg, self._tint.b * pb, self._tint.a * self.alpha * pa)
    end
    gfx.setBlendMode(self.blend, self.blendAlpha)

    local x, y, r, sx, sy = transform:getRenderValues()
    if self.clipRect then
		stencilSprite = self
        gfx.clear(false, true, false)

        gfx.setStencilState("replace", "always", 1)
        gfx.setColorMask(false)

        stencil(x, y, r, sx, sy)

        gfx.setStencilState("keep", "greater", 0)
        gfx.setColorMask(true)
	end
    if self._shader then
        gfx.setShader(self._shader.data)
    else
        gfx.setShader()
    end
    gfx.draw(self.texture:getImage(self.antialiasing and "linear" or "nearest"), x, y, r, sx, sy)

    if self.clipRect then
        gfx.clear(false, true, false)
		gfx.setStencilState()
	end
    if comet.settings.debugDraw then
        if not box then
            box = self:getBoundingBox(transform, self._rect)
        end
        gfx.setLineWidth(4)
        gfx.setColor(1, 1, 1, 1)
        gfx.rectangle("line", box.x, box.y, box.width, box.height)
    end
    gfx.setColor(pr, pg, pb, pa)
end

--- Returns the unscaled width of this image.
--- @return number
function Image:getOriginalWidth()
    if not self.texture then
        return 0
    end
    return self.texture:getWidth()
end

--- Returns the unscaled height of this image.
--- @return number
function Image:getOriginalHeight()
    if not self.texture then
        return 0
    end
    return self.texture:getHeight()
end

--- Returns the current width of this image.
--- @return number
function Image:getWidth()
    if not self.texture then
        return 0
    end
    return self.texture:getWidth() * abs(self.scale.x)
end

--- Returns the current height of this image.
--- @return number
function Image:getHeight()
    if not self.texture then
        return 0
    end
    return self.texture:getHeight() * abs(self.scale.y)
end

--- @param newWidth   number
--- @param newHeight  number
function Image:setGraphicSize(newWidth, newHeight)
    newWidth = newWidth or 0.0
    newHeight = newHeight or 0.0

    if newWidth <= 0 and newHeight <= 0 then
        return
    end
    local newScaleX = newWidth / self:getOriginalWidth()
    local newScaleY = newHeight / self:getOriginalHeight()
    self.scale:set(newScaleX, newScaleY)

    if newWidth <= 0 then
        self.scale.x = newScaleY
    elseif newHeight <= 0 then
        self.scale.y = newScaleX
    end
end

--- @param axes  "x"|"y"|"xy"?
function Image:screenCenter(axes)
    if not axes then
        axes = "xy"
    end
    local right = comet.getDesiredWidth()
    if not self.centered then
        right = right - self:getWidth()
    end
    local bottom = comet.getDesiredHeight()
    if not self.centered then
        bottom = bottom - self:getHeight()
    end
    axes = string.lower(axes)

    if axes == "x" or axes == "xy" then
        self.position.x = right / 2.0
    end
    if axes == "y" or axes == "xy" then
        self.position.y = bottom / 2.0
    end
end

--- Returns the tint of this image
--- @return comet.gfx.Color
function Image:getTint()
    return self._tint
end

--- Sets the tint of this image
--- @param tint comet.gfx.Color
function Image:setTint(tint)
    self._tint = Color:new(tint)
end

function Image:destroy()
    super.destroy(self)
    if self.texture then
        self.texture:dereference()
        self.texture = nil
    end
    self._tint = nil
end

return Image
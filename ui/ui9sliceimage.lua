--- @class comet.ui.UI9SliceImage : comet.gfx.Image
local UI9SliceImage, super = Image:subclass("UI9SliceImage", ...)

local abs, rad = math.abs, math.rad
local gfx = love.graphics

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

function UI9SliceImage:__init__(image)
    image = image or comet.getEmbeddedImage("ui/panel")
    super.__init__(self, image)
    
    self.size = Vec2:new() --- @type comet.math.Vec2
    
    self._quad = love.graphics.newQuad(0, 0, 1, 1, 1, 1) --- @protected
end

function UI9SliceImage:getOriginalWidth(sliced)
    if sliced then
        return super.getOriginalWidth(self) / 3
    end
    return self.size.x
end

function UI9SliceImage:getOriginalHeight(sliced)
    if sliced then
        return super.getOriginalHeight(self) / 3
    end
    return self.size.y
end

function UI9SliceImage:getWidth(sliced)
    if sliced then
        return super.getWidth(self) / 3
    end
    return self.size.x * math.abs(self.scale.x)
end

function UI9SliceImage:getHeight(sliced)
    if sliced then
        return super.getHeight(self) / 3
    end
    return self.size.y * math.abs(self.scale.y)
end

--- Returns the transform of this image
--- @param accountForParent    boolean?
--- @param accountForCamera    boolean?
--- @param accountForCentering boolean?
--- @param tileX               integer?
--- @param tileY               integer?
--- @param tileW               integer?
--- @param tileH               integer?
--- @param tileOffX            integer?
--- @param tileOffY            integer?
--- @return comet.math.Transform
function UI9SliceImage:getTransform(accountForParent, accountForCamera, accountForCentering, tileX, tileY, tileW, tileH, tileOffX, tileOffY)
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
    transform:translate(((tileX or 0) * self:getWidth(true)) + (tileOffX or 0), ((tileY or 0) * self:getHeight(true)) + (tileOffY or 0))
    transform:translate(-ox, -oy)

    -- scale
    local ox2, oy2 = abs(self:getOriginalWidth()) * 0.5, abs(self:getOriginalHeight()) * 0.5
    local sxm, sym = tileW == nil and 1 or tileW / self:getOriginalWidth(true), tileH == nil and 1 or tileH / self:getOriginalHeight(true)
    if self.centered then
        transform:scale(abs(self.scale.x * sxm), abs(self.scale.y * sym))
        
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
        transform:scale(self.scale.x * sxm, self.scale.y * sym)
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

function UI9SliceImage:draw()
    if self.alpha <= 0.0001 or not self.texture then
        return
    end
    local transform = self:getTransform(true, true, true, 0, 0, nil, nil)
    local ogTransform = transform

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

    if self._shader then
        gfx.setShader(self._shader.data)
    else
        gfx.setShader()
    end
    local img, quad = self.texture:getImage(self.antialiasing and "linear" or "nearest"), self._quad
    local sliceWidth, sliceHeight = img.image:getWidth() / 3, img.image:getHeight() / 3
    
    local fw, fh = self.size.x, self.size.y
    for tx = 1, 3 do
        for ty = 1, 3 do
            local i = ((ty - 1) * 3) + tx
            local tw, th = nil, nil

            -- tryna map this out in my head hold on
            -- 1, 2, 3
            -- 4, 5, 6
            -- 7, 8, 9
            
            -- TODO: this code sucks ass please clean it up later future me 
            local tox, toy = 0, 0
            if i == 3 then
                tox = fw - (sliceWidth * tx)
            elseif i == 9 then
                tox = fw - (sliceWidth * tx)
                toy = fh - (sliceHeight * ty)
            elseif i == 7 then
                toy = fh - (sliceHeight * ty)
            elseif i == 2 then
                tw = fw - (sliceWidth * tx)
            elseif i == 8 then
                toy = fh - (sliceHeight * ty)
                tw = fw - (sliceWidth * tx)
            elseif i == 4 then
                th = fh - (sliceHeight * ty)
            elseif i == 6 then
                tox = fw - (sliceWidth * tx)
                th = fh - (sliceHeight * ty)
            elseif i == 5 then
                tw = fw - (sliceWidth * tx)
                th = fh - (sliceHeight * ty)
            end
            transform = self:getTransform(true, true, true, tx - 1, ty - 1, tw, th, tox, toy)
            x, y, r, sx, sy = transform:getRenderValues()
            if self.clipRect then
                stencilSprite = self
                gfx.clear(false, true, false)

                gfx.setStencilState("replace", "always", 1)
                gfx.setColorMask(false)
                
                stencil(x, y, r, sx, sy)

                gfx.setStencilState("keep", "greater", 0)
                gfx.setColorMask(true)
            end
            quad:setViewport(sliceWidth * (tx - 1), sliceHeight * (ty - 1), sliceWidth, sliceHeight, img.image:getWidth(), img.image:getHeight())
            gfx.draw(img, quad, x, y, r, sx, sy)
        end
    end
    if self.clipRect then
        gfx.clear(false, true, false)
		gfx.setStencilState()
	end
    if comet.settings.debugDraw then
        if not box then
            box = self:getBoundingBox(ogTransform, self._rect)
        end
        gfx.setLineWidth(4)
        gfx.setColor(1, 1, 1, 1)
        gfx.rectangle("line", box.x, box.y, box.width, box.height)
    end
    gfx.setColor(pr, pg, pb, pa)
end

return UI9SliceImage
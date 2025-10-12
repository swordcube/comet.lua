--- @class comet.gfx.Backdrop : comet.gfx.Image
--- A basic object for displaying scrolling static images.
local Backdrop, super = Image:subclass("Backdrop", ...)

local math = math -- Faster access with local variable
local gfx = love.graphics -- Faster access with local variable

local function preMultiplyChannels(r, g, b, a)
    return r * a, g * a, b * a, a
end

function Backdrop:__init__(image, axes)
    super.__init__(self, image)

    self.axes = axes or "xy" --- @type "x"|"y"|"xy"
    self.spacing = Vec2:new() --- @type comet.math.Vec2
    self.velocity = Vec2:new() --- @type comet.math.Vec2
    self.offset = Vec2:new() --- @type comet.math.Vec2
end

--- Returns the transform of this backdrop
--- @param gridX integer
--- @param gridY integer
--- @param accountForParent boolean?
--- @param accountForCamera boolean?
--- @return comet.math.Transform
function Backdrop:getTransform(gridX, gridY, accountForParent, accountForCamera)
    if accountForParent == nil then
        accountForParent = true
    end
    if accountForCamera == nil then
        accountForCamera = true
    end
    local transform = self._transform:reset()
    if accountForParent then
        transform = self:getParentTransform(transform, accountForCamera)
    end

    -- position
    transform:translate(self.position.x + self.offset.x, self.position.y + self.offset.y)
    
    if self.centered then
        transform:translate(-math.abs(self:getWidth()) * 0.5, -math.abs(self:getHeight()) * 0.5)
    end
    -- origin
    local ox, oy = math.abs(self:getWidth()) * self.origin.x, math.abs(self:getHeight()) * self.origin.y
    transform:translate(ox, oy)
    transform:rotate(math.rad(self.rotation))
    transform:translate(-ox, -oy)
    
    -- scale
    local ox2, oy2 = math.abs(self:getOriginalWidth()) * 0.5, math.abs(self:getOriginalHeight()) * 0.5
    transform:scale(math.abs(self.scale.x), math.abs(self.scale.y))

    if self.scale.x < 0.0 then
        transform:translate(ox2, oy2)
        transform:scale(-1, 1)
        transform:translate(-ox2, -oy2)
    end
    if self.scale.y < 0.0 then
        transform:translate(ox2, oy2)
        transform:scale(1, -1)
        transform:translate(-ox2, -oy2)
    end
    transform:translate((self:getOriginalWidth() + self.spacing.x) * gridX, (self:getOriginalHeight() + self.spacing.y) * gridY)
    return transform
end

--- Checks if this rectangle is on screen on a specific axes
--- @param axes  "x"|"y"|"xy"?     The axes to check on
--- @param box   comet.math.Rect?  The bounding box to check with (optional)
function Backdrop:isAxesOnScreen(axes, box)
    if axes == nil then
        axes = "xy"
    end
    if not box then
        box = self:getBoundingBox()
    end
    local p = self.parent
    local camera = nil --- @type comet.gfx.Camera
    while p do
        if p and p:isInstanceOf(Camera) then
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
    if axes == "x" then
        if bxpw < gx or box.x > gx + gw then
            return false
        end
    elseif axes == "y" then
        if byph < gy or box.y > gy + gh then
            return false
        end
    else
        if bxpw < gx or box.x > gx + gw or byph < gy or box.y > gy + gh then
            return false
        end
    end
    return true
end

function Backdrop:isOnScreen()
    return true
end

function Backdrop:update(dt)
    self.offset.x = math.wrap(self.offset.x + (self.velocity.x * dt), 0, self:getWidth() + self.spacing.x) 
    self.offset.y = math.wrap(self.offset.y + (self.velocity.y * dt), 0, self:getHeight() + self.spacing.y)
end

function Backdrop:draw()
    if self.alpha <= 0.0001 or not self.texture then
        return
    end
    local gridX, gridY, axes = 0, 0, self.axes
    if axes == "x" or axes == "xy" then
        while true do
            local transform = self:getTransform(gridX, gridY)
            local box = self:getBoundingBox(transform, self._rect)
            if not self:isAxesOnScreen("x", box) then
                break
            end
            gridX = gridX - 1
        end
        gridX = gridX + 1
    end
    if axes == "y" or axes == "xy" then
        while true do
            local transform = self:getTransform(gridX, gridY)
            local box = self:getBoundingBox(transform, self._rect)
            if not self:isAxesOnScreen("y", box) then
                break
            end
            gridY = gridY - 1
        end
        gridY = gridY + 1
    end
    local ogGridX = gridX
    gfx.setBlendMode(self.blend, self.blendAlpha)

    if self._shader then
        gfx.setShader(self._shader.data)
    else
        gfx.setShader()
    end
    while true do
        local transform = self:getTransform(gridX, gridY)
        local box = self:getBoundingBox(transform, self._rect)

        local pr, pg, pb, pa = gfx.getColor()
        if self.blendAlpha == "premultiplied" then
            gfx.setColor(preMultiplyChannels(self._tint.r * pr, self._tint.g * pg, self._tint.b * pb, self._tint.a * self.alpha * pa))
        else
            gfx.setColor(self._tint.r * pr, self._tint.g * pg, self._tint.b * pb, self._tint.a * self.alpha * pa)
        end
        gfx.draw(self.texture:getImage(self.antialiasing and "linear" or "nearest"), transform:getRenderValues())
        
        if comet.settings.debugDraw then
            gfx.setLineWidth(4)
            gfx.setColor(1, 1, 1, 1)
            gfx.rectangle("line", box.x, box.y, box.width, box.height)
        end
        gfx.setColor(pr, pg, pb, pa)
        gridX = gridX + 1
        if axes == "x" or axes == "xy" then
            if not self:isAxesOnScreen("x", box) then
                break
            end
        elseif axes == "y" or axes == "xy" then
            if not self:isAxesOnScreen("x", box) then
                gridX = ogGridX
                gridY = gridY + 1
            end
            if not self:isAxesOnScreen("y", box) then
                break
            end
        end
    end
end

return Backdrop
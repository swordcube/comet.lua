--- @class comet.gfx.Camera : comet.gfx.Object2D
--- A basic object for displaying static Cameras.
local Camera, super = Object2D:subclass("Camera", ...)

local math = math -- Faster access with local variable
local gfx = love.graphics -- Faster access with local variable

function Camera:__init__()
    super.__init__(self)

    -- Set position to center by default
    self.position:set(comet.getDesiredWidth() / 2, comet.getDesiredHeight() / 2)

    self.scroll = Vec2:new()
    
    --- Size of this camera
    self.size = Vec2:new(comet.getDesiredWidth(), comet.getDesiredHeight()) --- @type comet.math.Vec2

    --- Zoom of this camera
    self.zoom = Vec2:new(1.0, 1.0) --- @type comet.math.Vec2

    --- Non-functional on Cameras, use `zoom` instead.
    self.scale = nil

    --- @type comet.gfx.Color
    self._bgColor = Color:new(Color.BLACK) --- @protected

    --- @type comet.math.Rect
    self._rect = Rect:new() --- @protected

    --- @type comet.gfx.Shader[]
    self._shaders = {} --- @protected

    --- Only used when drawing cameras with shaders applied
    --- 
    --- They are drawn as is (with scissor applied) otherwise
    --- 
    --- @type table<comet.gfx.Shader, love.Canvas>
    self._canvases = {} --- @protected

    --- @type love.Transform
    self._emptyTransform = love.math.newTransform() --- @protected

    self._fx = {
        fade = {
            color = Color:new(Color.WHITE), --- @type comet.gfx.Color
            alpha = 0.0,
            time = 0.0,
            duration = 0.0,
            inwards = false
        },
        flash = {
            color = Color:new(Color.WHITE), --- @type comet.gfx.Color
            alpha = 0.0,
            time = 0.0,
            duration = 0.0
        }
    }
end

function Camera:getBackgroundColor()
    return self._bgColor
end

--- @param color comet.gfx.Color
function Camera:setBackgroundColor(color)
    self._bgColor = Color:new(color)
end

function Camera:getShaders()
    return self._shaders
end

function Camera:setShaders(newShaders)
    for i = 1, #self._shaders do
        -- if not in new shader list, then deference
        -- otherwise, do nothing since it's still referenced
        local shader = self._shaders[i]
        if not table.contains(newShaders, shader) then
            if self._canvases[shader] then
                self._canvases[shader]:release()
                self._canvases[shader] = nil
            end
            shader:dereference()
        end
    end
    local filteredShaders = table.removeDuplicates(newShaders)
    for i = 1, #filteredShaders do
        -- reference da new shaders :D
        local shader = filteredShaders[i] --- @type comet.gfx.Shader
        if not self._canvases[shader] then
            self._canvases[shader] = gfx.newCanvas(self.size.x, self.size.y)
        end
        shader:reference()
    end
    if #filteredShaders == 0 then
        if self._canvases["first"] then
            self._canvases["first"]:release()
            self._canvases["first"] = nil
        end
    else
        self._canvases["first"] = gfx.newCanvas(self.size.x, self.size.y)
    end
    self._shaders = filteredShaders
end

--- Returns the unscaled width of this camera.
--- @return number
function Camera:getOriginalWidth()
    return self.size.x
end

--- Returns the unscaled height of this camera.
--- @return number
function Camera:getOriginalHeight()
    return self.size.y
end

--- Returns the current width of this camera.
--- @return number
function Camera:getWidth()
    return self.size.x * math.abs(self.zoom.x)
end

--- Returns the current height of this camera.
--- @return number
function Camera:getHeight()
    return self.size.y * math.abs(self.zoom.y)
end

--- Returns the transform of this camera
--- @param accountForScroll boolean?
--- @param accountForZoom boolean?
--- @param accountForParent boolean?
--- @return love.Transform
function Camera:getTransform(accountForScroll, accountForZoom, accountForParent)
    if accountForScroll == nil then
        accountForScroll = true
    end
    if accountForZoom == nil then
        accountForZoom = true
    end
    if accountForParent == nil then
        accountForParent = true
    end

    -- base transform
    local transform = self._transform:reset()
    if accountForParent then
        transform = self:getParentTransform(transform)
    end

    -- position
    if accountForScroll then
        transform:translate(-self.scroll.x, -self.scroll.y)
    end
    local w, h = accountForZoom and self:getWidth() or self:getOriginalWidth(), accountForZoom and self:getHeight() or self:getOriginalHeight()
    transform:translate(self.position.x - (w * 0.5), self.position.y - (h * 0.5))

    -- origin
    local ox, oy = w * self.origin.x, h * self.origin.y
    transform:translate(ox, oy)
    transform:rotate(math.rad(self.rotation))
    transform:translate(-ox, -oy)

    -- scale
    if accountForZoom then
        transform:scale(math.max(self.zoom.x, 0.0), math.max(self.zoom.y, 0.0))
    end
    return transform
end

--- Returns the bounding box of this camera, as a rectangle
--- @param trans love.Transform?   The transform to use for the bounding box (optional)
--- @param rect  comet.math.Rect?  The rectangle to use as the bounding box (optional)
--- @return comet.math.Rect
function Camera:getBoundingBox(trans, rect)
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

    local minX = math.min(x1, x2, x3, x4)
    local minY = math.min(y1, y2, y3, y4)
    local maxX = math.max(x1, x2, x3, x4)
    local maxY = math.max(y1, y2, y3, y4)

    rect:set(minX, minY, maxX - minX, maxY - minY)
    return rect
end

function Camera:flash(color, duration, force)
    if not force and self._fx.flash.alpha > 0.0 then
        return
    end
    self._fx.flash.time = 0.0
    self._fx.flash.duration = duration or 0.0
    self._fx.flash.color = Color:new(color)
end

function Camera:fade(color, duration, fadeIn, force)
    if not force and self._fx.fade.alpha > 0.0 then
        return
    end
    self._fx.fade.time = 0.0
    self._fx.fade.duration = duration or 0.0
    self._fx.fade.color = Color:new(color)
    self._fx.fade.fadeIn = fadeIn ~= nil and fadeIn or false
end

function Camera:update(dt)
    self._fx.flash.time = math.min(self._fx.flash.time + dt, self._fx.flash.duration)
    self._fx.fade.time = math.min(self._fx.fade.time + dt, self._fx.fade.duration)
end

function Camera:drawFX(box)
    if self._fx.flash.time <= self._fx.flash.duration then
        local alpha = self._fx.flash.color.a * (1 - (self._fx.flash.time / self._fx.flash.duration))
        self._fx.flash.alpha = alpha

        gfx.setColor(self._fx.flash.color.r, self._fx.flash.color.g, self._fx.flash.color.b, alpha)
        gfx.rectangle("fill", box.x, box.y, box.width, box.height)
    end
    if self._fx.fade.time <= self._fx.fade.duration then
        local alpha = self._fx.fade.color.a * (1 - (self._fx.fade.time / self._fx.fade.duration))
        self._fx.fade.alpha = alpha

        if self._fx.fade.fadeIn then
            alpha = 1.0 - alpha
        end
        gfx.setColor(self._fx.fade.color.r, self._fx.fade.color.g, self._fx.fade.color.b, alpha)
        gfx.rectangle("fill", box.x, box.y, box.width, box.height)
    end
end

function Camera:_draw()
    if #self._shaders ~= 0 then
        -- draw to a bunch of canvases with shaders applied to them
        -- and then 
        local transform = self._emptyTransform
        local box = self:getBoundingBox(transform, self._rect)

        gfx.push()
        gfx.origin()
        gfx.setScissor()

        for i = 1, #self._shaders do
            local shader = self._shaders[i]
            if i > 1 then
                gfx.setCanvas(self._canvases[shader])

                gfx.setShader(shader.data)
                gfx.draw(self._canvases[self._shaders[i - 1]], transform)
                gfx.setShader()

                gfx.setCanvas()
            else
                -- draw to initial shaderless canvas first
                gfx.setCanvas(self._canvases["first"])
                
                local pr, pg, pb, pa = gfx.getColor()
                gfx.setColor(self._bgColor.r, self._bgColor.g, self._bgColor.b, self._bgColor.a)
                gfx.rectangle("fill", box.x, box.y, box.width, box.height)
                
                super._draw(self)
                self:drawFX(box)

                gfx.setColor(pr, pg, pb, pa)

                -- then draw this shaderless canvas to the final canvas
                gfx.setCanvas(self._canvases[shader])
                
                gfx.setShader(shader.data)
                gfx.draw(self._canvases["first"], transform)
                gfx.setShader()

                gfx.setCanvas()
            end
        end
        local shader = self._shaders[#self._shaders]
        gfx.pop()
        
        local px, py, pw, ph = gfx.getScissor()
        transform = self:getTransform(false, false)
        box = self:getBoundingBox(transform, self._rect)

        gfx.setScissor(comet.adjustToGameScissor(box.x, box.y, box.width, box.height))
        gfx.draw(self._canvases[shader], transform)
        gfx.setScissor(px, py, pw, ph)
    else
        -- draw camera directly
        local box = self:getBoundingBox(self:getTransform(false, false), self._rect)
    
        local px, py, pw, ph = gfx.getScissor()
        gfx.setScissor(comet.adjustToGameScissor(box.x, box.y, box.width, box.height))
        
        local pr, pg, pb, pa = gfx.getColor()
        gfx.setColor(self._bgColor.r, self._bgColor.g, self._bgColor.b, self._bgColor.a)
        gfx.rectangle("fill", box.x, box.y, box.width, box.height)
        
        super._draw(self)
        self:drawFX(box)
        
        gfx.setColor(pr, pg, pb, pa)
        gfx.setScissor(px, py, pw, ph)
    end
end

function Camera:destroy()
    super.destroy(self)

    self:setShaders({})
    self._shaders = nil
    
    self.size = nil
    self.zoom = nil
end

return Camera
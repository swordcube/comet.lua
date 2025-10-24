--- @class comet.gfx.Camera : comet.gfx.Object2D
--- A basic object for displaying static Cameras.
local Camera, super = Object2D:extend("Camera", ...)

local math = math -- Faster access with local variable
local gfx = love.graphics -- Faster access with local variable

local function preMultiplyChannels(r, g, b, a)
    return r * a, g * a, b * a, a
end

function Camera:__init__()
    super.__init__(self)

    -- Set position to center by default
    self.position:set(comet.getDesiredWidth() / 2, comet.getDesiredHeight() / 2)

    self.scroll = Vec2:new() --- @type comet.math.Vec2
    self.targetOffset = Vec2:new() --- @type comet.math.Vec2
    self.followLead = Vec2:new() --- @type comet.math.Vec2

    self.minScrollX = nil --- @type number?
    self.maxScrollX = nil --- @type number?

    self.minScrollY = nil --- @type number?
    self.maxScrollY = nil --- @type number?

    self.target = nil

    self.followType = "lockon" --- @type "lockon"|"platformer"|"topdown"|"topdown-tight"|"screen-by-screen"|"no-dead-zone"
    self.followSpeed = 1.0

    self.deadzone = nil --- @type comet.math.Rect?
    
    --- Size of this camera
    self.size = Vec2:new(comet.getDesiredWidth(), comet.getDesiredHeight()) --- @type comet.math.Vec2

    --- Zoom of this camera
    self.zoom = Vec2:new(1.0, 1.0) --- @type comet.math.Vec2

    --- Non-functional on Cameras, use `zoom` instead.
    self.scale = nil

    --- Alpha multiplier for this camera
    self.alpha = 1.0

    --- @type comet.math.Vec2
    self._scrollTarget = Vec2:new() --- @protected

    --- @type comet.gfx.Color
    self._bgColor = Color:new(Color.TRANSPARENT) --- @protected

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

    --- @type comet.math.Transform
    self._emptyTransform = Transform:new() --- @protected

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

--- @param obj    any
--- @param type   "lockon"|"platformer"|"topdown"|"topdown-tight"|"screen-by-screen"|"no-dead-zone"
--- @param speed  number
function Camera:follow(obj, type, speed)
    if not type then
        type = "lockon"
    end
    self.target = obj
    self.followType = type
    self.followSpeed = speed or 10
    self.deadzone = nil
    
    if type == "lockon" then
        local w, h = 0, 0
        if obj and obj.getWidth and obj.getHeight then
            w, h = obj:getWidth(), obj:getHeight()
        end
        self.deadzone = Rect:new((self.size.x - w) / 2, (self.size.y - h) / 2 - h * 0.25, w, h)
        
    elseif type == "platformer" then
        local w, h = self.size.x / 8, self.size.y / 3
        self.deadzone = Rect:new((self.size.x - w) / 2, (self.size.y - h) / 2 - h * 0.25, w, h)

    elseif type == "topdown" then
        local helper = math.max(self.size.x, self.size.y) / 4
        self.deadzone = Rect:new((self.size.x - helper) / 2, (self.size.y - helper) / 2, helper, helper)

    elseif type == "topdown-tight" then
        local helper = math.max(self.size.x, self.size.y) / 8
        self.deadzone = Rect:new((self.size.x - helper) / 2, (self.size.y - helper) / 2, helper, helper)

    elseif type == "screen-by-screen" then
        self.deadzone = Rect:new(0, 0, self.size.x, self.size.y)

    elseif type == "no-dead-zone" then
        self.deadzone = nil
    end
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

--- @param newShaders comet.gfx.Shader[]
function Camera:setShaders(newShaders)
    assert(type(newShaders) == "table", "Camera:setShaders(): Parameter 1 must be a table with shader instances")

    for i = 1, #self._shaders do
        -- if not in new shader list, then deference
        -- otherwise, do nothing since it's still referenced
        local shader = self._shaders[i]
        if not table.contains(newShaders, shader) then
            if self._canvases[shader] then
                self._canvases[shader]:release()
                self._canvases[shader] = nil
            end
            shader:dereference(false) -- don't try to destroy if there are 0 references yet, we might reuse this same shader in newShaders
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
    for i = 1, #self._shaders do
        -- if not in new shader list, then destroy
        -- it entirely if there are 0 references 
        local shader = self._shaders[i]
        if not table.contains(newShaders, shader) then
            shader:checkRefs() -- check if there are 0 references now, destroy if so
        end
    end
    self._shaders = filteredShaders
end

--- @param newShaders comet.gfx.Shader[]
function Camera:addShaders(newShaders)
    assert(type(newShaders) == "table", "Camera:addShaders(): Parameter 1 must be a table with shader instances")
    
    local curShaders = table.merge(self._shaders, newShaders)
    self:setShaders(curShaders)
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
--- @return comet.math.Transform
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
    local w, h = accountForZoom and self:getWidth() or self:getOriginalWidth(), accountForZoom and self:getHeight() or self:getOriginalHeight()
    transform:translate(self.position.x, self.position.y)

    -- origin
    local ox, oy = w * self.origin.x, h * self.origin.y
    transform:translate(ox, oy)
    transform:rotate(math.rad(self.rotation))
    transform:translate(-ox, -oy)

    -- scale
    if accountForZoom then
        transform:scale(math.max(self.zoom.x, 0.0), math.max(self.zoom.y, 0.0))
    end
    transform:translate(self:getOriginalWidth() * -0.5, self:getOriginalHeight() * -0.5)

    if accountForScroll then
        transform:translate(-self.scroll.x, -self.scroll.y)
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

function Camera:snapToTarget()
    local target = self.target
    if not target then
        return
    end
    self.scroll:set(
        target.position.x - (self.size.x * 0.5),
        target.position.y - (self.size.y * 0.5)
    )
    self._scrollTarget:set(self.scroll.x, self.scroll.y)
end

function Camera:focusOn(obj)
    if not obj or not obj.getBoundingBox then
        return
    end
    local box = obj:getBoundingBox(obj:getTransform())
    self.scroll:set(box.x + (box.width * 0.5) - (self.size.x * 0.5), box.y + (box.height * 0.5) - (self.size.y * 0.5))
    self._scrollTarget:set(self.scroll.x, self.scroll.y)
end

function Camera:bindScrollPos(scrollPos)
    local camBox = self:getBoundingBox(self:getTransform(false, true, false), self._rect) --- @type comet.math.Rect

    local viewMarginLeft = camBox.x
    local viewMarginRight = camBox.x + camBox.width
    local viewMarginTop = camBox.y
    local viewMarginBottom = camBox.y + camBox.height

    local minX = self.minScrollX and self.minScrollX - viewMarginLeft or nil
    local maxX = self.maxScrollX and self.maxScrollX - viewMarginRight or nil
    local minY = self.minScrollY and self.minScrollY - viewMarginTop or nil
    local maxY = self.maxScrollY and self.maxScrollY - viewMarginBottom or nil

    scrollPos:set(math.clamp(scrollPos.x, minX, maxX), math.clamp(scrollPos.y, minY, maxY))
end

function Camera:updateScroll()
    self:bindScrollPos(self.scroll)
end

function Camera:updateFollow()
    local deadzone, target = self.deadzone, self.target
    if not deadzone then
        self.scroll:set(
            (target.position.x + self.targetOffset.x) - (self.size.x * 0.5),
            (target.position.y + self.targetOffset.y) - (self.size.y * 0.5)
        )
    else
        local edge = 0
        local targetX, targetY = target.position.x + self.targetOffset.x, target.position.y + self.targetOffset.y

        if self.followType == "screen-by-screen" then
            -- TODO: this shit is terribly broken but i don't want to fix it right now
            local camBox = self:getBoundingBox(self:getTransform(false, true, false), self._rect) --- @type comet.math.Rect
            
            local viewWidth, viewHeight = self._scrollTarget.x + camBox.width, self._scrollTarget.x + camBox.height
            local viewLeft, viewRight = self._scrollTarget.x + (camBox.width * 0.5), self.size.x - (camBox.width * 0.5)
            local viewTop, viewBottom = self._scrollTarget.y + (camBox.height * 0.5), self.size.y - (camBox.height * 0.5)

            if targetX >= viewRight then
                self._scrollTarget.x = self._scrollTarget.x + viewWidth
            elseif targetX + target:getWidth() < viewLeft then
                self._scrollTarget.x = self._scrollTarget.x - viewWidth
            end
            if targetY >= viewBottom then
                self._scrollTarget.y = self._scrollTarget.y + viewHeight
            elseif targetY + target:getHeight() < viewTop then
                self._scrollTarget.y = self._scrollTarget.y - viewHeight
            end
            self:bindScrollPos(self._scrollTarget)
        else
            edge = targetX - deadzone.x
            if self._scrollTarget.x > edge then
                self._scrollTarget.x = edge
            end
            edge = targetX + target:getWidth() - deadzone.x - deadzone.width
            if self._scrollTarget.x < edge then
                self._scrollTarget.x = edge
            end
            edge = targetY - deadzone.y
            if self._scrollTarget.y > edge then
                self._scrollTarget.y = edge
            end
            edge = targetY + target:getHeight() - deadzone.y - deadzone.height
            if self._scrollTarget.y < edge then
                self._scrollTarget.y = edge
            end
        end
    end
    if not self._lastTargetPosition then
        self._lastTargetPosition = Vec2:new(self.target.position.x, self.target.position.y) --- @type comet.math.Vec2
    end
    self._scrollTarget.x = self._scrollTarget.x + ((self.target.position.x - self._lastTargetPosition.x) * self.followLead.x)
    self._scrollTarget.y = self._scrollTarget.y + ((self.target.position.y - self._lastTargetPosition.y) * self.followLead.y)

    self._lastTargetPosition:set(self.target.position.x, self.target.position.y)
end

function Camera:updateLerp(dt)
    if self.followSpeed >= 1.0 then
        self.scroll:set(self._scrollTarget.x, self._scrollTarget.y)
    else
        local adjustedSpeed = 1.0 - math.pow(1.0 - self.followSpeed, dt * 60.0)
        self.scroll.x = math.lerp(self.scroll.x, self._scrollTarget.x, adjustedSpeed)
        self.scroll.y = math.lerp(self.scroll.y, self._scrollTarget.y, adjustedSpeed)
    end
end

function Camera:update(dt)
    self._fx.flash.time = math.min(self._fx.flash.time + dt, self._fx.flash.duration)
    self._fx.fade.time = math.min(self._fx.fade.time + dt, self._fx.fade.duration)

    local target = self.target
    if target then
        self:updateFollow()
        self:updateLerp(dt)
    end
end

function Camera:drawFX(box)
    local pr, pg, pb, pa = gfx.getColor()
    if self._fx.flash.time <= self._fx.flash.duration then
        local alpha = self._fx.flash.color.a * (1 - (self._fx.flash.time / self._fx.flash.duration))
        self._fx.flash.alpha = alpha

        gfx.setColor(preMultiplyChannels(self._fx.flash.color.r * pr, self._fx.flash.color.g * pg, self._fx.flash.color.b * pb, alpha * pa))
        gfx.rectangle("fill", box.x, box.y, box.width, box.height)
    end
    if self._fx.fade.time <= self._fx.fade.duration then
        local alpha = self._fx.fade.color.a * (1 - (self._fx.fade.time / self._fx.fade.duration))
        self._fx.fade.alpha = alpha

        if self._fx.fade.fadeIn then
            alpha = 1.0 - alpha
        end
        gfx.setColor(preMultiplyChannels(self._fx.fade.color.r * pr, self._fx.fade.color.g * pg, self._fx.fade.color.b * pb, alpha * pa))
        gfx.rectangle("fill", box.x, box.y, box.width, box.height)
    end
end

function Camera:_draw()
    gfx.setBlendMode("alpha", "premultiplied")

    if #self._shaders ~= 0 then
        -- draw to a bunch of canvases with shaders applied to them
        -- and then 
        local transform = self._emptyTransform
        local box = self._rect:set(0, 0, self.size.x, self.size.y)

        gfx.push()
        gfx.origin()
        gfx.setScissor()

        local pbr, pbg, pbb, pba = gfx.getBackgroundColor()
        gfx.setBackgroundColor(0, 0, 0, 0)

        for i = 1, #self._shaders do
            local shader = self._shaders[i]
            if i > 1 then
                gfx.setCanvas({self._canvases[shader], stencil=true})
                gfx.setBlendMode("alpha", "alphamultiply")
                gfx.clear()
                
                gfx.setShader(shader.data)
                gfx.setBlendMode("alpha", "premultiplied")
                gfx.draw(self._canvases[self._shaders[i - 1]], transform:getRenderValues())
                gfx.setShader()
                
                gfx.setCanvas()
            else
                -- draw to initial shaderless canvas first
                gfx.setCanvas({self._canvases["first"], stencil=true})
                gfx.setBlendMode("alpha", "alphamultiply")
                gfx.clear()
                gfx.setBlendMode("alpha", "premultiplied")
                
                local pr, pg, pb, pa = gfx.getColor()
                local bgVisible = self._bgColor.a > 0.001

                if bgVisible then
                    gfx.setColor(preMultiplyChannels(self._bgColor.r, self._bgColor.g, self._bgColor.b, self._bgColor.a))
                    gfx.rectangle("fill", box.x, box.y, box.width, box.height)
                end
                gfx.setColor(pr, pg, pb, pa * self.alpha)

                super._draw(self)
                self:drawFX(box)
                
                gfx.setColor(pr, pg, pb, pa)

                -- then draw this shaderless canvas to the final canvas
                gfx.setCanvas({self._canvases[shader], stencil=true})
                gfx.setBlendMode("alpha", "alphamultiply")
                gfx.clear()
                
                -- and then we ACTUALLY draw the shaderless canvas
                gfx.setShader(shader.data)
                gfx.setBlendMode("alpha", "premultiplied")
                gfx.draw(self._canvases["first"], transform:getRenderValues())
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
        gfx.draw(self._canvases[shader], transform:getRenderValues())
        gfx.setScissor(px, py, pw, ph)

        gfx.setBackgroundColor(pbr, pbg, pbb, pba)
    else
        -- draw camera directly
        local box = self:getBoundingBox(self:getTransform(false, false), self._rect)
    
        local px, py, pw, ph = gfx.getScissor()
        gfx.setScissor(comet.adjustToGameScissor(box.x, box.y, box.width, box.height))
        
        local pr, pg, pb, pa = gfx.getColor()
        local bgVisible = self._bgColor.a > 0.001

        if bgVisible then
            gfx.setColor(preMultiplyChannels(self._bgColor.r, self._bgColor.g, self._bgColor.b, self._bgColor.a))
            gfx.rectangle("fill", box.x, box.y, box.width, box.height)
        end
        gfx.setColor(pr, pg, pb, pa * self.alpha)

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
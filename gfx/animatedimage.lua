local Signal = cometreq("util.signal") --- @type comet.util.Signal
local AnimationController = cometreq("gfx.animationcontroller") --- @type comet.gfx.AnimationController

--- @class comet.gfx.AnimatedImage : comet.gfx.Object2D
--- A basic object for displaying animated images, typically loaded through the `FrameCollection` class.
local AnimatedImage, super = Object2D:extend("AnimatedImage", ...)

AnimatedImage.NO_OFF_SCREEN_CHECKS = false

local abs, floor, rad, fastsin, wrap, clamp = math.abs, math.floor, math.rad, math.fastsin, math.wrap, math.clamp
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

function AnimatedImage:__init__(x, y)
    super.__init__(self, x, y)

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

    --- Signal that gets emitted when the animation finishes
    self.onComplete = Signal:new():type("string", "void") --- @type comet.util.Signal

    self.animation = AnimationController:new(self) --- @type comet.gfx.AnimationController

    --- @type comet.gfx.Shader
    self._shader = nil --- @protected

    --- @type comet.gfx.FrameCollection
    self._frames = nil --- @protected

    --- @type comet.gfx.AnimationFrame
    self._frame = nil --- @protected

    --- @type comet.gfx.Color
    self._tint = Color:new(1, 1, 1, 1) --- @protected

    --- @type comet.math.Rect
    self._rect = Rect:new() --- @protected
end

function AnimatedImage:getFrameCollection()
    return self._frames
end

--- @param frames comet.gfx.FrameCollection
function AnimatedImage:setFrameCollection(frames)
    assert(type(frames) == "table" and Class.isInstanceOf(frames, FrameCollection), "AnimatedImage:setFrameCollection(): You must pass in a FrameCollection instance")
    if self._frames then
        self._frames:dereference()
        self._frames = nil
    end
    if frames then
        self._frames = frames
        self._frames:reference()
    
        self._frame = self._frames:getFrame(self._frames:getAnimationNames()[1], 1)
    end
end

function AnimatedImage:getShader()
    return self._shader
end

function AnimatedImage:setShader(shader)
    assert(type(shader) == "table" and Class.isInstanceOf(shader, Shader), "AnimatedImage:setShader(): You must pass in a shader instance")
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

--- Adds an animation purely by frame indices.
--- 
--- Use this if your using a frame collection loaded as a grid (`FrameCollection.fromTexture`),
--- as there is no animation names available in them.
--- 
--- Otherwise use `addAnimationByName()` or `addAnimationByIndices()`.
--- 
--- @param shortcut string?    A shortcut name to use when playing the animation.
--- @param indices  integer[]  The indices of the frames to use.
--- @param fps      number     The framerate of the animation.
--- @param loop     boolean?   Whether or not to loop the animation. (optional, default=`false`)
--- @deprecated Use `obj.animation:add()` instead!
function AnimatedImage:addAnimation(shortcut, indices, fps, loop)
    self.animation:add(shortcut, indices, fps, loop)
end

--- @param shortcut    string?   A shortcut name to use when playing the animation.
--- @param name        string    The raw name of the animation.
--- @param fps         number    The framerate of the animation.
--- @param loop        boolean?  Whether or not to loop the animation. (optional, default=`false`)
--- @param skipWarning boolean? Whether or not to skip warnings. (optional, default=`false`)
--- @deprecated Use `obj.animation:addByName()` instead!
function AnimatedImage:addAnimationByName(shortcut, name, fps, loop, skipWarnings)
    self.animation:addByName(shortcut, name, fps, loop, skipWarnings)
end

--- @param shortcut string?    A shortcut name to use when playing the animation.
--- @param name     string     The raw name of the animation.
--- @param indices  integer[]  The indices of the frames to use.
--- @param fps      number     The framerate of the animation.
--- @param loop     boolean?   Whether or not to loop the animation. (optional, default=`false`)
--- @deprecated Use `obj.animation:addByIndices()` instead!
function AnimatedImage:addAnimationByIndices(shortcut, name, indices, fps, loop)
    self.animation:addByIndices(shortcut, name, indices, fps, loop)
end

--- @param name string  The name/shortcut name of the animation to check.
--- @return boolean
--- @deprecated Use `obj.animation:has()` instead!
function AnimatedImage:hasAnimation(name)
    return self.animation:has(name)
end

--- @param name string  The name/shortcut name of the animation to get the offset of.
--- @return comet.math.Vec2?
--- @deprecated Use `obj.animation:getOffset()` instead!
function AnimatedImage:getAnimationOffset(name)
    return self.animation:getOffset(name)
end

--- @param name string  The name/shortcut name of the animation to set the offset of.
--- @param x    number  The new X offset for this animation.
--- @param y    number  The new Y offset for this animation.
--- @deprecated Use `obj.animation:setOffset()` instead!
function AnimatedImage:setAnimationOffset(name, x, y)
    self.animation:setOffset(name, x, y)
end

--- @param name  string    The name/shortcut name of the animation to play.
--- @param force boolean?  Whether or not to forcefully restart the animation. (optional, default=`false`)
--- @deprecated Use `obj.animation:play()` instead!
function AnimatedImage:playAnimation(name, force)
    self.animation:play(name, force)
end

--- @deprecated Use `obj.animation:getCurrentAnimation()` instead!
function AnimatedImage:getCurrentAnimation()
    return self.animation:getCurrentAnimation()
end

--- @deprecated Use `obj.animation:getCurrentFrame()` instead!
function AnimatedImage:getCurrentFrame()
    return self.animation:getCurrentFrame()
end

--- @param frame integer
--- @deprecated Use `obj.animation:setCurrentFrame()` instead!
function AnimatedImage:setCurrentFrame(frame)
    self.animation:setCurrentFrame(frame)
end

--- @deprecated Use `obj.animation:isPlaying()` instead!
function AnimatedImage:isPlaying()
    return self.animation:isPlaying()
end

--- @deprecated Use `obj.animation:pause()` instead!
function AnimatedImage:pause()
    self.animation:pause()
end

--- @deprecated Use `obj.animation:resume()` instead!
function AnimatedImage:resume()
    self.animation:resume()
end

--- @deprecated Use `obj.animation:isFinished()` instead!
function AnimatedImage:isFinished()
    return self.animation:isFinished()
end

--- Returns the unscaled width of a given frame.
--- @param frame integer?  The frame to get the width of. (optional, defaults to current)
--- @return number
function AnimatedImage:getOriginalWidth(frame)
    return self.animation:getOriginalWidth(frame)
end

--- Returns the unscaled height of a given frame.
--- @param frame integer?  The frame to get the height of. (optional, defaults to current)
--- @return number
function AnimatedImage:getOriginalHeight(frame)
    return self.animation:getOriginalHeight(frame)
end

--- Returns the width of a given frame (accounting for this image's scale).
--- @param frame integer?  The frame to get the width of. (optional, defaults to current)
--- @return number
function AnimatedImage:getWidth(frame)
    return self.animation:getOriginalWidth(frame) * abs(self.scale.x)
end

--- Returns the height of a given frame (accounting for this image's scale).
--- @param frame integer?  The frame to get the height of. (optional, defaults to current)
--- @return number
function AnimatedImage:getHeight(frame)
    return self.animation:getOriginalHeight(frame) * abs(self.scale.y)
end

--- @param newWidth   number
--- @param newHeight  number
function AnimatedImage:setGraphicSize(newWidth, newHeight)
    return Image.setGraphicSize(self, newWidth, newHeight)
end

--- @param axes  "x"|"y"|"xy"?
function AnimatedImage:screenCenter(axes)
    Image.screenCenter(self, axes)
end

--- Returns the tint of this image
--- @return comet.gfx.Color
function AnimatedImage:getTint()
    return self._tint
end

--- Sets the tint of this image
--- @param tint comet.gfx.Color
function AnimatedImage:setTint(tint)
    self._tint = Color:new(tint)
end

--- Returns the transform of this image
--- @param accountForParent boolean?
--- @param accountForCamera boolean?
--- @param accountForCentering boolean?
--- @param accountForFrames boolean?
--- @return comet.math.Transform
function AnimatedImage:getTransform(accountForParent, accountForCamera, accountForCentering, accountForFrames)
    if accountForParent == nil then
        accountForParent = true
    end
    if accountForCamera == nil then
        accountForCamera = true
    end
    if accountForCentering == nil then
        accountForCentering = false
    end
    if accountForFrames == nil then
        accountForFrames = false
    end
    local transform = self._transform:reset()
    if accountForParent then
        transform = self:getParentTransform(transform, accountForCamera)
    end

    -- position
    local frame = self._frame
    transform:translate(self.position.x + self.offset.x, self.position.y + self.offset.y)

    if accountForCentering and self.centered then
        transform:translate(-abs(self:getWidth(1)) * 0.5, -abs(self:getHeight(1)) * 0.5)
    end
    
    -- origin
    local ox, oy = abs(self:getWidth(1)) * self.origin.x, abs(self:getHeight(1)) * self.origin.y
    transform:translate(ox, oy)
    transform:rotate(rad(self.rotation))
    transform:translate(-ox, -oy)

    -- scale
    local ox2, oy2 = abs(self:getOriginalWidth(1)) * 0.5, abs(self:getOriginalHeight(1)) * 0.5
    if self.centered then
        transform:scale(abs(self.scale.x), abs(self.scale.y))
        
        if self.scale.x < -math.epsilon then
            transform:translate(ox2, 0)
            transform:scale(-1, 1)
            transform:translate(-ox2, 0)
        end
        if self.scale.y < -math.epsilon then
            transform:translate(0, oy2)
            transform:scale(1, -1)
            transform:translate(0, -oy2)
        end
    else
        transform:scale(self.scale.x, self.scale.y)
    end
    if self.flipX then
        transform:translate(ox2, 0)
        transform:scale(-1, 1)
        transform:translate(-ox2, 0)
    end
    if self.flipY then
        transform:translate(0, oy2)
        transform:scale(1, -1)
        transform:translate(0, -oy2)
    end

    -- frame & anim offset
    if accountForFrames then
        local anim = self.animation._animations[self.animation._curAnim]
        transform:translate(frame.offset.x + (anim and anim.offset.x or 0.0), frame.offset.y + (anim and anim.offset.y or 0.0))
        transform:translate(0, fastsin(rad(frame.rotation)) * -frame.clipWidth)
        transform:rotate(rad(frame.rotation))
    end
    return transform
end

--- Returns the bounding box of this image, as a rectangle
--- @param trans comet.math.Transform?   The transform to use for the bounding box (optional)
--- @param rect  comet.math.Rect?  The rectangle to use as the bounding box (optional)
--- @return comet.math.Rect
function AnimatedImage:getBoundingBox(trans, rect)
    if not trans then
        trans = self:getTransform(true, true, true, true)
    end
    return Image.getBoundingBox(self, trans, rect)
end

--- Checks if this image is on screen
--- @param box comet.math.Rect?  The bounding box to check with (optional)
function AnimatedImage:isOnScreen(box)
    return Image.isOnScreen(self, box)
end

function AnimatedImage:update(dt)
    self.animation:update(dt)
end

function AnimatedImage:draw()
    if self.alpha <= 0.0001 or not self._frame or not self._frame.texture then
        return
    end
    local transform = self:getTransform(true, true, true, true)
    local box = not AnimatedImage.NO_OFF_SCREEN_CHECKS and self:getBoundingBox(transform, self._rect) or nil
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
    gfx.draw(self._frame.texture:getImage(self.antialiasing and "linear" or "nearest"), self._frame.quad, x, y, r, sx, sy)

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

function AnimatedImage:destroy()
    super.destroy(self)
    if self._frames then
        self._frames:dereference()
        self._frames = nil
    end
    self._frame = nil
end

return AnimatedImage
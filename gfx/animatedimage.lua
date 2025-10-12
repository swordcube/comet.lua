local Signal = cometreq("util.signal") --- @type comet.util.Signal

--- @class comet.gfx.AnimatedImage : comet.gfx.Object2D
--- A basic object for displaying animated images, typically loaded through the `FrameCollection` class.
local AnimatedImage, super = Object2D:subclass("AnimatedImage", ...)

AnimatedImage.static.NO_OFF_SCREEN_CHECKS = false

local abs, floor, rad, fastsin, wrap, clamp = math.abs, math.floor, math.rad, math.fastsin, math.wrap, math.clamp
local gfx = love.graphics -- Faster access with local variable

local function preMultiplyChannels(r, g, b, a)
    return r * a, g * a, b * a, a
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

    --- Signal that gets emitted when the animation finishes
    self.onComplete = Signal:new():type("string", "void") --- @type comet.util.Signal

    --- @type comet.gfx.Shader
    self._shader = nil --- @protected

    --- @type table<string, table[]>
    self._animations = {} --- @protected

    --- @type string
    self._curAnim = "" --- @protected

    --- @type integer
    self._curFrame = 1 --- @protected

    --- @type number
    self._frameTimer = 0.0 --- @protected

    --- @type boolean
    self._playing = false

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
function AnimatedImage:addAnimation(shortcut, indices, fps, loop)
    loop = loop ~= nil and loop or false
    self._animations[shortcut] = {name = "grid", fps = fps, indices = indices, loop = loop, offset = Vec2:new()}
end

--- @param shortcut    string?   A shortcut name to use when playing the animation.
--- @param name        string    The raw name of the animation.
--- @param fps         number    The framerate of the animation.
--- @param loop        boolean?  Whether or not to loop the animation. (optional, default=`false`)
--- @param skipWarning boolean? Whether or not to skip warnings. (optional, default=`false`)
function AnimatedImage:addAnimationByName(shortcut, name, fps, loop, skipWarnings)
    if skipWarnings == nil then
        skipWarnings = false
    end
    if not self._frames:getFrames(name) then
        if not skipWarnings then
            Log.warn("Animation '" .. name .. "' does not exist in the frame collection!")
        end
        return
    end
    shortcut = shortcut or name
    loop = loop ~= nil and loop or false
    self._animations[shortcut] = {name = name, fps = fps, loop = loop, offset = Vec2:new()}
end

--- @param shortcut string?    A shortcut name to use when playing the animation.
--- @param name     string     The raw name of the animation.
--- @param indices  integer[]  The indices of the frames to use.
--- @param fps      number     The framerate of the animation.
--- @param loop     boolean?   Whether or not to loop the animation. (optional, default=`false`)
function AnimatedImage:addAnimationByIndices(shortcut, name, indices, fps, loop)
    shortcut = shortcut or name
    loop = loop ~= nil and loop or false
    self._animations[shortcut] = {name = name, fps = fps, indices = indices, loop = loop, offset = Vec2:new()}
end

--- @param name string  The name/shortcut name of the animation to check.
--- @return boolean
function AnimatedImage:hasAnimation(name)
    return self._animations[name] ~= nil
end

--- @param name string  The name/shortcut name of the animation to set the offset of.
--- @param x    number  The new X offset for this animation.
--- @param y    number  The new Y offset for this animation.
function AnimatedImage:setAnimationOffset(name, x, y)
    if not self:hasAnimation(name) then
        Log.warn("Animation '" .. name .. "' does not exist!")
        return
    end
    self._animations[name].offset:set(x, y)
end

--- @param name  string    The name/shortcut name of the animation to play.
--- @param force boolean?  Whether or not to forcefully restart the animation. (optional, default=`false`)
function AnimatedImage:playAnimation(name, force)
    if not self:hasAnimation(name) then
        Log.warn("Animation '" .. name .. "' does not exist!")
        return
    end
    force = force ~= nil and force or false
    if not force and self._curAnim == name then
        return
    end
    self._curAnim = name
    self:setCurrentFrame(1)

    self._frameTimer = 0.0
    self._playing = true
end

function AnimatedImage:getCurrentAnimation()
    return self._curAnim
end

function AnimatedImage:getCurrentFrame()
    return self._curFrame
end

--- @param frame integer
function AnimatedImage:setCurrentFrame(frame)
    self._curFrame = frame

    local anim = self._animations[self._curAnim]
    self._frame = self._frames:getFrame(anim.name, anim.indices and (anim.indices[frame] or 1) or frame)
end

function AnimatedImage:isPlaying()
    return self._playing
end

function AnimatedImage:pause()
    self._playing = false
end

function AnimatedImage:resume()
    self._playing = true
end

--- Returns the unscaled width of a given frame.
--- @param frame integer?  The frame to get the width of. (optional, defaults to current)
--- @return number
function AnimatedImage:getOriginalWidth(frame)
    frame = frame ~= nil and frame or self._curFrame
    if not self._frames then
        return 0
    end
    local anim = self._animations[self._curAnim]
    local frameData = self._frames:getFrame(self._animations[self._curAnim].name, anim.indices and (anim.indices[frame] or frame) or frame)
    return frameData and frameData.frameWidth or 0
end

--- Returns the unscaled height of a given frame.
--- @param frame integer?  The frame to get the height of. (optional, defaults to current)
--- @return number
function AnimatedImage:getOriginalHeight(frame)
    frame = frame ~= nil and frame or self._curFrame
    if not self._frames then
        return 0
    end
    local anim = self._animations[self._curAnim]
    local frameData = self._frames:getFrame(self._animations[self._curAnim].name, anim.indices and (anim.indices[frame] or frame) or frame)
    return frameData and frameData.frameHeight or 0
end

--- Returns the width of a given frame (accounting for this image's scale).
--- @param frame integer?  The frame to get the width of. (optional, defaults to current)
--- @return number
function AnimatedImage:getWidth(frame)
    frame = frame ~= nil and frame or self._curFrame
    if not self._frames then
        return 0
    end
    local anim = self._animations[self._curAnim]
    local frameData = self._frames:getFrame(self._animations[self._curAnim].name, anim.indices and (anim.indices[frame] or frame) or frame)
    return frameData and frameData.frameWidth * abs(self.scale.x) or 0
end

--- Returns the height of a given frame (accounting for this image's scale).
--- @param frame integer?  The frame to get the height of. (optional, defaults to current)
--- @return number
function AnimatedImage:getHeight(frame)
    frame = frame ~= nil and frame or self._curFrame
    if not self._frames then
        return 0
    end
    local anim = self._animations[self._curAnim]
    local frameData = self._frames:getFrame(self._animations[self._curAnim].name, anim.indices and (anim.indices[frame] or frame) or frame)
    return frameData and frameData.frameHeight * abs(self.scale.y) or 0
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
--- @return comet.math.Transform
function AnimatedImage:getTransform(accountForParent, accountForCamera, accountForCentering)
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

    -- frame & anim offset
    local anim = self._animations[self._curAnim]
    transform:translate(frame.offset.x + (anim and anim.offset.x or 0.0), frame.offset.y + (anim and anim.offset.y or 0.0))
    transform:translate(0, fastsin(rad(frame.rotation)) * -frame.frameWidth)
    transform:rotate(rad(frame.rotation))
    
    return transform
end

--- Returns the bounding box of this image, as a rectangle
--- @param trans comet.math.Transform?   The transform to use for the bounding box (optional)
--- @param rect  comet.math.Rect?  The rectangle to use as the bounding box (optional)
--- @return comet.math.Rect
function AnimatedImage:getBoundingBox(trans, rect)
    return Image.getBoundingBox(self, trans, rect)
end

--- Checks if this image is on screen
--- @param box comet.math.Rect?  The bounding box to check with (optional)
function AnimatedImage:isOnScreen(box)
    return Image.isOnScreen(self, box)
end

function AnimatedImage:update(dt)
    if not self._playing or not self._frames then
        return
    end
    self._frameTimer = self._frameTimer + dt

    local anim = self._animations[self._curAnim]
    local frameDuration = 1.0 / anim.fps

    while self._frameTimer >= frameDuration do
        if not self._frames then
            break
        end
        local finished = false
        local newFrame = self._curFrame + 1
        local animFrames = anim.indices or self._frames:getFrames(anim.name)

        if not anim.loop and self._curFrame >= #animFrames and self._playing then
            self._playing = false
            finished = true
        end
        if anim.loop then
            newFrame = wrap(newFrame, 1, #animFrames)
        else
            newFrame = clamp(newFrame, 1, #animFrames)
        end
        self:setCurrentFrame(newFrame)
        self._frameTimer = self._frameTimer - frameDuration
        
        if finished then
            self.onComplete:emit(self._curAnim)
        end
    end
end

function AnimatedImage:draw()
    if self.alpha <= 0.0001 or not self._frame or not self._frame.texture then
        return
    end
    local transform = self:getTransform(true, true, true)
    local box = not AnimatedImage.NO_OFF_SCREEN_CHECKS and self:getBoundingBox(transform, self._rect) or nil
    if box and not self:isOnScreen(box) then
        return
    end
    local pr, pg, pb, pa = gfx.getColor()
    gfx.setColor(preMultiplyChannels(self._tint.r * pr, self._tint.g * pg, self._tint.b * pb, self._tint.a * self.alpha * pa))

    local prevShader = gfx.getShader()
    if self._shader then
        gfx.setShader(self._shader.data)
    end
    gfx.setBlendMode(self.blend, "premultiplied")
    gfx.draw(self._frame.texture:getImage(self.antialiasing and "linear" or "nearest"), self._frame.quad, transform:getRenderValues())

    if self._shader then
        gfx.setShader(prevShader)
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
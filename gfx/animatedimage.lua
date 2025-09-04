--- @class comet.gfx.AnimatedImage : comet.gfx.Object2D
--- A basic object for displaying animated images, typically loaded through the `FrameCollection` class.
local AnimatedImage, super = Object2D:subclass("AnimatedImage")

local math = math -- Faster access with local variable
local gfx = love.graphics -- Faster access with local variable

function AnimatedImage:__init__(x, y)
    super.__init__(self, x, y)

    -- Whether or not to display the image from it's center
    self.centered = true

    -- Whether or not to use antialiasing on this image
    self.antialiasing = true

    -- Alpha multiplier for this image
    self.alpha = 1

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

--- @param shortcut string?   A shortcut name to use when playing the animation.
--- @param name     string    The raw name of the animation.
--- @param fps      number    The framerate of the animation.
--- @param loop     boolean?  Whether or not to loop the animation. (optional, default=`false`)
function AnimatedImage:addAnimation(shortcut, name, fps, loop)
    shortcut = shortcut or name
    loop = loop ~= nil and loop or false
    self._animations[shortcut] = {name = name, fps = fps, loop = loop}
end

--- @param name string  The name/shortcut name of the animation to play.
--- @param force boolean?  Whether or not to forcefully restart the animation. (optional, default=`false`)
function AnimatedImage:playAnimation(name, force)
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
    self._frame = self._frames:getFrame(self._animations[self._curAnim].name, frame)
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
    return self._frames:getFrame(self._animations[self._curAnim].name, frame).width
end

--- Returns the unscaled height of a given frame.
--- @param frame integer?  The frame to get the height of. (optional, defaults to current)
--- @return number
function AnimatedImage:getOriginalHeight(frame)
    frame = frame ~= nil and frame or self._curFrame
    if not self._frames then
        return 0
    end
    return self._frames:getFrame(self._animations[self._curAnim].name, frame).height
end

--- Returns the width of a given frame (accounting for this image's scale).
--- @param frame integer?  The frame to get the width of. (optional, defaults to current)
--- @return number
function AnimatedImage:getWidth(frame)
    frame = frame ~= nil and frame or self._curFrame
    if not self._frames then
        return 0
    end
    return self._frames:getFrame(self._animations[self._curAnim].name, frame).width * math.abs(self.scale.x)
end

--- Returns the height of a given frame (accounting for this image's scale).
--- @param frame integer?  The frame to get the height of. (optional, defaults to current)
--- @return number
function AnimatedImage:getHeight(frame)
    frame = frame ~= nil and frame or self._curFrame
    if not self._frames then
        return 0
    end
    return self._frames:getFrame(self._animations[self._curAnim].name, frame).height * math.abs(self.scale.y)
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

--- Returns the transform of this image
--- @return love.Transform
function AnimatedImage:getTransform()
    local transform = self._transform:reset()
    transform = self:getParentTransform(transform)

    -- position
    local frame = self._frame
    transform:translate(self.position.x, self.position.y)

    if self.centered then
        transform:translate(-math.abs(self:getWidth(1)) * 0.5, -math.abs(self:getHeight(1)) * 0.5)
    end
    
    -- origin
    local ox, oy = math.abs(self:getWidth(1)) * self.origin.x, math.abs(self:getHeight(1)) * self.origin.y
    transform:translate(ox, oy)
    transform:rotate(math.rad(self.rotation))
    transform:translate(-ox, -oy)

    -- scale
    local ox2, oy2 = math.abs(self:getOriginalWidth(1)) * 0.5, math.abs(self:getOriginalHeight(1)) * 0.5
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
    transform:translate(frame.offset.x, frame.offset.y)
    transform:translate(0, math.fastsin(math.rad(frame.rotation)) * -frame.width)
    transform:rotate(math.rad(frame.rotation))
    return transform
end

--- Returns the bounding box of this image, as a rectangle
--- @param trans love.Transform?   The transform to use for the bounding box (optional)
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
    if not self._playing then
        return
    end
    self._frameTimer = self._frameTimer + dt

    local anim = self._animations[self._curAnim]
    local frameDuration = 1.0 / anim.fps

    while self._frameTimer >= frameDuration do
        local newFrame = self._curFrame + 1
        local animFrames = self._frames:getFrames(anim.name)
        if anim.loop then
            newFrame = math.wrap(newFrame, 1, #animFrames)
        else
            newFrame = math.clamp(newFrame, 1, #animFrames)
            if newFrame >= #animFrames then
                self._playing = false
            end
        end
        self:setCurrentFrame(newFrame)
        self._frameTimer = self._frameTimer - frameDuration
    end
end

function AnimatedImage:draw()
    if self.alpha <= 0.0001 or not self._frame or not self._frame.texture then
        return
    end
    local transform = self:getTransform()
    local box = self:getBoundingBox(transform, self._rect)
    if not self:isOnScreen(box) then
        return
    end
    local pr, pg, pb, pa = gfx.getColor()
    gfx.setColor(self._tint.r, self._tint.g, self._tint.b, self._tint.a * self.alpha)
    gfx.draw(self._frame.texture:getImage(self.antialiasing and "linear" or "nearest"), self._frame.quad, transform)
    gfx.setColor(pr, pg, pb, pa)

    if comet.settings.debugDraw then
        gfx.setLineWidth(4)
        gfx.rectangle("line", box.x, box.y, box.width, box.height)
    end
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
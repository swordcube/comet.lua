local json = cometreq("lib.json") --- @type comet.lib.Json

--- @class comet.gfx.AnimationController : comet.util.Class
--- A simple animation controller for AnimatedImages.
local AnimationController = Class:extend("AnimationController", ...)

local wrap, clamp = math.wrap, math.clamp

function AnimationController:__init__(parent)
    assert(parent ~= nil and Class.isInstanceOf(parent, AnimatedImage), "AnimationImage:new(): Parent must be an AnimatedImage")
    self.parent = parent --- @type comet.gfx.AnimatedImage

    self.onComplete = self.parent.onComplete

    --- @type table<string, table[]>
    self._animations = {} --- @protected

    --- @type string
    self._curAnim = "" --- @protected

    --- @type integer
    self._curFrame = 1 --- @protected

    --- @type number
    self._frameTimer = 0.0 --- @protected

    --- @type boolean
    self._playing = false --- @protected

    --- @type boolean
    self._finished = false --- @protected

    --- @type number
    self._biggestFrameWidth = 0.0 --- @protected

    --- @type number
    self._biggestFrameHeight = 0.0 --- @protected
end

function AnimationController:_updateBiggestFrameSize()
    self._biggestFrameWidth, self._biggestFrameHeight = 0, 0
    for _, anim in pairs(self._animations) do
        if anim.indices and anim.indices ~= json.null then
            for i = 1, #anim.indices do
                local frame = self.parent._frames:getFrame(anim.name, anim.indices[i])
                self._biggestFrameWidth = math.max(frame and frame.frameWidth or 0, self._biggestFrameWidth)
                self._biggestFrameHeight = math.max(frame and frame.frameHeight or 0, self._biggestFrameHeight)
            end
        else
            local frames = self.parent._frames:getFrames(anim.name)
            for i = 1, #frames do
                local frame = frames[i]
                self._biggestFrameWidth = math.max(frame and frame.frameWidth or 0, self._biggestFrameWidth)
                self._biggestFrameHeight = math.max(frame and frame.frameHeight or 0, self._biggestFrameHeight)
            end
        end
    end
end

--- Adds an animation purely by frame indices.
---
--- Use this if your using a frame collection loaded as a grid (`FrameCollection.fromTexture`),
--- as there is no animation names available in them.
---
--- Otherwise use `addByName()` or `addByIndices()`.
---
--- @param shortcut string?    A shortcut name to use when playing the animation.
--- @param indices  integer[]  The indices of the frames to use.
--- @param fps      number     The framerate of the animation.
--- @param loop     boolean?   Whether or not to loop the animation. (optional, default=`false`)
function AnimationController:add(shortcut, indices, fps, loop)
    loop = loop ~= nil and loop or false
    self._animations[shortcut] = {name = "grid", fps = fps, indices = indices, loop = loop, offset = Vec2:new()}
    self:_updateBiggestFrameSize()
end

--- @param shortcut    string?   A shortcut name to use when playing the animation.
--- @param name        string    The raw name of the animation.
--- @param fps         number    The framerate of the animation.
--- @param loop        boolean?  Whether or not to loop the animation. (optional, default=`false`)
--- @param skipWarning boolean? Whether or not to skip warnings. (optional, default=`false`)
function AnimationController:addByName(shortcut, name, fps, loop, skipWarnings)
    if skipWarnings == nil then
        skipWarnings = false
    end
    if not self.parent._frames:getFrames(name) then
        if not skipWarnings then
            Log.warn("Animation '" .. name .. "' does not exist in the frame collection!")
        end
        return
    end
    shortcut = shortcut or name
    loop = loop ~= nil and loop or false
    self._animations[shortcut] = {name = name, fps = fps, loop = loop, offset = Vec2:new()}
    self:_updateBiggestFrameSize()
end

--- @param shortcut string?    A shortcut name to use when playing the animation.
--- @param name     string     The raw name of the animation.
--- @param indices  integer[]  The indices of the frames to use.
--- @param fps      number     The framerate of the animation.
--- @param loop     boolean?   Whether or not to loop the animation. (optional, default=`false`)
function AnimationController:addByIndices(shortcut, name, indices, fps, loop)
    shortcut = shortcut or name
    loop = loop ~= nil and loop or false
    self._animations[shortcut] = {name = name, fps = fps, indices = indices, loop = loop, offset = Vec2:new()}
    self:_updateBiggestFrameSize()
end

--- @param name string  The name/shortcut name of the animation to check.
--- @return boolean
function AnimationController:has(name)
    return self._animations[name] ~= nil
end

--- @param name string  The name/shortcut name of the animation to get the offset of.
--- @return comet.math.Vec2?
function AnimationController:getOffset(name)
    if not self:has(name) then
        Log.warn("Animation '" .. name .. "' does not exist!")
        return nil
    end
    return self._animations[name].offset
end

--- @param name string  The name/shortcut name of the animation to set the offset of.
--- @param x    number  The new X offset for this animation.
--- @param y    number  The new Y offset for this animation.
function AnimationController:setOffset(name, x, y)
    if not self:has(name) then
        Log.warn("Animation '" .. name .. "' does not exist!")
        return
    end
    self._animations[name].offset:set(x, y)
end

--- @param name  string    The name/shortcut name of the animation to play.
--- @param force boolean?  Whether or not to forcefully restart the animation. (optional, default=`false`)
function AnimationController:play(name, force)
    if not self:has(name) then
        Log.warn("Animation '" .. name .. "' does not exist!")
        return
    end
    force = force ~= nil and force or false
    if not force and self._curAnim == name and self:isPlaying() then
        return
    end
    self._curAnim = name
    self:setCurrentFrame(1)

    self._frameTimer = 0.0
    self._playing = true
    self._finished = false
end

function AnimationController:remove(name)
	if self._curAnim == name then
    	self._curAnim = ""
    	self._curFrame = 0
    	self._frameTimer = 0
    	self._playing, self._finished = false, false
    end
	self._animations[name] = nil
	self:_updateBiggestFrameSize()
end

function AnimationController:clearAll()
   	self._curAnim = ""
   	self._curFrame = 0
   	self._frameTimer = 0
   	self._playing, self._finished = false, false

	self._animations = {}
	self._biggestFrameWidth, self._biggestFrameHeight = 0, 0
end

--- @return string[]
function AnimationController:getAnimationNames()
	local anims = {}
	for name, _ in pairs(self._animations) do
		anims[#anims+1] = name
	end
	return anims
end

function AnimationController:getCurrentAnimation()
    return self._curAnim
end

function AnimationController:getCurrentFrame()
    return self._curFrame
end

--- @param frame integer
function AnimationController:setCurrentFrame(frame)
    self._curFrame = frame

    local anim = self._animations[self._curAnim]
    self.parent._frame = self.parent._frames:getFrame(anim.name, anim.indices and (anim.indices[frame] or 1) or frame)
end

function AnimationController:isPlaying()
    return self._playing
end

function AnimationController:pause()
    self._playing = false
end

function AnimationController:resume()
    self._playing = true
end

function AnimationController:isFinished()
    return self._finished
end

--- Returns the unscaled width of a given frame.
--- @param frame integer?  The frame to get the width of. (optional, defaults to current)
--- @return number
function AnimationController:getOriginalWidth(frame)
    frame = frame ~= nil and frame or self._curFrame
    if not self.parent._frames then
        return 0
    end
    local anim = self._animations[self._curAnim]
    local frameData = self.parent._frames:getFrame(self._animations[self._curAnim].name, anim.indices and (anim.indices[frame] or frame) or frame)
    return frameData and frameData.frameWidth or 0
end

--- Returns the unscaled height of a given frame.
--- @param frame integer?  The frame to get the height of. (optional, defaults to current)
--- @return number
function AnimationController:getOriginalHeight(frame)
    frame = frame ~= nil and frame or self._curFrame
    if not self.parent._frames then
        return 0
    end
    local anim = self._animations[self._curAnim]
    local frameData = self.parent._frames:getFrame(self._animations[self._curAnim].name, anim.indices and (anim.indices[frame] or frame) or frame)
    return frameData and frameData.frameHeight or 0
end

function AnimationController:getBiggestFrameWidth()
    return self._biggestFrameWidth
end

function AnimationController:getBiggestFrameHeight()
    return self._biggestFrameHeight
end

function AnimationController:update(dt)
    if not self._playing or not self.parent._frames then
        return
    end
    self._frameTimer = self._frameTimer + dt

    local anim = self._animations[self._curAnim]
    local frameDuration = 1.0 / anim.fps

    while self._frameTimer >= frameDuration do
        if not self.parent._frames then
            break
        end
        local finished = false
        local newFrame = self._curFrame + 1
        local animFrames = anim.indices or self.parent._frames:getFrames(anim.name)

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
            self._finished = true
            self.onComplete:emit(self._curAnim)
        end
    end
end

function AnimationController:destroy()
    self.parent = nil
    self._animations = nil
    self._curAnim = nil
    self._curFrame = nil
    self._frameTimer = nil
    self._playing = nil
    self._finished = nil
end

return AnimationController
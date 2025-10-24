--- @diagnostic disable: cast-local-type

local Xml = cometreq("lib.xml") --- @type comet.lib.Xml

--- @class comet.gfx.FrameCollection : comet.core.RefCounted
--- A basic class for storing a collection of animation frames.
--- Meant to be used in `AnimatedImage` objects.
local FrameCollection, super = RefCounted:extend("FrameCollection", ...)

function FrameCollection:__init__()
    super.__init__(self)

    --- @type table<string, comet.gfx.AnimationFrame[]>
    self._frames = {} --- @protected
end

--- @param img comet.gfx.Image|string  The image to load the atlas from.
--- @param xml string                  The XML file path/string to load the atlas from.
function FrameCollection.loadSparrowAtlas(img, xml)
    if type(img) == "string" then
        img = comet.gfx:getTexture(img)
    end
    if love.filesystem.exists(xml) then
        xml = love.filesystem.read("string", xml)
    end
    local frames = FrameCollection:new() --- @type comet.gfx.FrameCollection
    local xmlData = Xml.parse(xml)
    for i = 1, #xmlData.TextureAtlas.children do
        local child = xmlData.TextureAtlas.children[i]
        if child.name ~= "SubTexture" then
            goto continue
        end
        local animationName = string.sub(child.att.name, 1, string.len(child.att.name) - 4)
        local frame = AnimationFrame:new(
            child.att.name, img,
            child.att.x, child.att.y,
            child.att.frameX and -tonumber(child.att.frameX) or 0.0, child.att.frameY and -tonumber(child.att.frameY) or 0.0,
            tonumber(child.att.w or child.att.width), tonumber(child.att.h or child.att.height),
            child.att.frameWidth and tonumber(child.att.frameWidth) or tonumber(child.att.w or child.att.width), child.frameHeight and tonumber(child.frameHeight) or (child.att.h or child.att.height),
            child.att.rotated and (string.lower(child.att.rotated) == "true" and -90.0 or 0.0) or 0.0
        )
        frames:addFrame(animationName, frame)
        ::continue::
    end
    for _, f in pairs(frames._frames) do
        table.sort(f, function(a, b)
            local aID = tonumber(string.sub(a.name, string.len(a.name) - 3))
            local bID = tonumber(string.sub(b.name, string.len(b.name) - 3))
            return aID < bID
        end)
    end
    return frames
end

function FrameCollection.fromTexture(img, gridWidth, gridHeight)
    if type(img) == "string" then
        img = comet.gfx:getTexture(img)
    end
    local frameX, frameY, frameID = 0, 0, 1
    local frames = FrameCollection:new() --- @type comet.gfx.FrameCollection

    while true do
        if frameX >= img:getWidth() then
            frameX = 0
            frameY = frameY + gridHeight
        end
        if frameY >= img:getHeight() then
            break
        end
        frames:addFrame("grid", AnimationFrame:new("frame" .. frameID, img, frameX, frameY, 0, 0, gridWidth, gridHeight, gridWidth, gridHeight, 0.0))
        frameX = frameX + gridWidth
    end
    return frames
end

--- Adds a frame to a given animation.
--- @param animation string  The name of the animation.
--- @param frame comet.gfx.AnimationFrame  The frame to add.
function FrameCollection:addFrame(animation, frame)
    if not self._frames[animation] then
        self._frames[animation] = {}
    end
    table.insert(self._frames[animation], frame)
end

--- Sorts the frames for a given animation.
--- @param animation string    The name of the animation.
--- @param func      function  The function to sort the frames with.
function FrameCollection:sortFrames(animation, func)
    if not self._frames[animation] then
        Log.warn("Cannot sort frames for a non-existent animation!")
        return
    end
    table.sort(self._frames[animation], func)
end

--- Returns the frames for a given animation.
--- @param animation string  The name of the animation.
--- @return comet.gfx.AnimationFrame[]
function FrameCollection:getFrames(animation)
    return self._frames[animation]
end

--- Returns a specific frame for a given animation.
--- @param animation string  The name of the animation.
--- @param idx number  The index of the frame.
--- @return comet.gfx.AnimationFrame
function FrameCollection:getFrame(animation, idx)
    return self._frames[animation][idx]
end

--- Returns the number of frames for a given animation.
--- @param animation string  The name of the animation.
--- @return integer
function FrameCollection:getFrameCount(animation)
    return #self._frames[animation]
end

--- @return string[]
function FrameCollection:getAnimationNames()
    local names = {}
    for name, _ in pairs(self._frames) do
        table.insert(names, name)
    end
    return names
end

function FrameCollection:destroy()
    if self._frames then
        for _, frames in pairs(self._frames) do
            for i = 1, #frames do
                frames[i]:destroy()
            end
        end
        self._frames = nil
    end
end

return FrameCollection
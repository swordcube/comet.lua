--- @class comet.gfx.Object2D : comet.core.Object
local Object2D, super = Object:subclass("Object2D", ...)

local gfx = love.graphics
local lmath = love.math

function Object2D:__init__(x, y)
    super.__init__(self)

    --- Position of this object
    self.position = Vec2:new(x and x or 0.0, y and y or 0.0) --- @type comet.math.Vec2

    --- Offset of this object
    self.offset = Vec2:new() --- @type comet.math.Vec2
    
    -- Rotation of this object (in degrees)
    self.rotation = 0.0
    
    --- Rotation origin of this object (from 0 to 1) (does not affect position)
    self.origin = Vec2:new(0.5, 0.5) --- @type comet.math.Vec2
    
    --- Scale multiplier of this object
    self.scale = Vec2:new(1, 1) --- @type comet.math.Vec2
    
    --- @type love.Transform
    self._transform = lmath.newTransform() --- @protected

    --- @type comet.math.Rect
    self._fullRect = Rect:new() --- @protected
end

--- @param  transform  love.Transform
--- @param  accountForCamera boolean?
function Object2D:getParentTransform(transform, accountForCamera)
    if transform == nil then
        transform = lmath.newTransform()
    end
    if accountForCamera == nil then
        accountForCamera = true
    end
    if self.parent and self.parent:isInstanceOf(Object2D) then
        local isCam = self.parent:isInstanceOf(Camera)
        if isCam and not accountForCamera then
            goto continue
        end
        if isCam and #self.parent._shaders ~= 0 then
            transform:apply(self.parent:getTransform(true, true, false))
        else
            transform:apply(self.parent:getTransform())
        end
    end
    ::continue::
    return transform
end

--- Rotates this object by a given amount of degrees
--- @param by number
function Object2D:rotate(by)
    self.rotation = self.rotation + by
end

--- Returns the transform of this object
--- @return love.Transform
function Object2D:getTransform()
    local transform = self._transform:reset()
    transform = self:getParentTransform(transform)

    transform:translate(self.position.x + self.offset.x, self.position.y + self.offset.y)
    transform:rotate(math.rad(self.rotation))
    transform:scale(self.scale.x, self.scale.y)
    
    return transform
end

local function processChild(child, minX, minY, maxX, maxY)
    if child and child.exists and child.visible and child.getBoundingBox then
        local box = child:getBoundingBox(child:getTransform(), child._rect)
        if box.x < minX then minX = box.x end
        if box.x + box.width > maxX then maxX = box.x + box.width end
        if box.y < minY then minY = box.y end
        if box.y + box.height > maxY then maxY = box.y + box.height end
    end
    if child.getChildCount and child.children then
        for i = 1, child:getChildCount() do
            minX, minY, maxX, maxY = processChild(child.children[i], minX, minY, maxX, maxY)
        end
    end
    return minX, minY, maxX, maxY
end

-- TODO: does this need better documentation???? i'm too tired to think of anything better

--- Returns the total bounding box of the children inside of this object.
--- 
--- If you're looking to get the bounding box of a specific object only,
--- use `myObject:getBoundingBox()` instead.
--- 
--- @param  rect  comet.math.Rect?  The rectangle to store the bounding box (optional)
function Object2D:getChildrenBoundingBox(rect)
    if not rect then
        rect = self._fullRect
    end
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    for i = 1, self:getChildCount() do
        minX, minY, maxX, maxY = processChild(self.children[i], minX, minY, maxX, maxY)
    end
    if minX == math.huge then
        rect:set(0, 0, 0, 0)
        return rect
    end
    rect:set(minX, minY, maxX - minX, maxY - minY)
    return rect
end

function Object2D:getWidth()
    local box = self:getChildrenBoundingBox(self._fullRect)
    return box.width
end

function Object2D:getHeight()
    local box = self:getChildrenBoundingBox(self._fullRect)
    return box.height
end

--- @param axes  "x"|"y"|"xy"?
function Object2D:screenCenter(axes)
    if not axes then
        axes = "xy"
    end
    local box = self:getChildrenBoundingBox(self._fullRect)
    local right = comet.getDesiredWidth()
    if not self.centered then
        right = right - box.width
    end
    local bottom = comet.getDesiredHeight()
    if not self.centered then
        bottom = bottom - box.height
    end
    axes = string.lower(axes)

    -- TODO: maybe subtracting by box x/y isn't ideal?
    -- it breaks object centering in certain scenarios
    if axes == "x" or axes == "xy" then
        self.position.x = (right / 2.0) - box.x
    end
    if axes == "y" or axes == "xy" then
        self.position.y = (bottom / 2.0) - box.y
    end
end

return Object2D
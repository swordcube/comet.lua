local Class = cometreq("util.class") --- @type comet.util.Class

--- @class comet.modules.mouse
local mouse = Class("comet.modules.mouse", ...)

local list = {
    "left",
    "right",
    "middle"
}

function mouse:__init__()
    --- Position of the mouse relative to the game area.
    self.position = Vec2:new() --- @type comet.math.Vec2

    --- Position of the mouse relative to the entire screen/window.
    self.screenPosition = Vec2:new() --- @type comet.math.Vec2

    self.delta = Vec2:new() --- @type comet.math.Vec2
    self.wheel = Vec2:new() --- @type comet.math.Vec2

    --- @protected
    self._justPressed = {
        left = false,
        right = false,
        middle = false
    }
    --- @protected
    self._pressed = {
        left = false,
        right = false,
        middle = false
    }
    --- @protected
    self._justReleased = {
        left = false,
        right = false,
        middle = false
    }

    --- @type comet.math.Rect
    self._rect = Rect:new() --- @protected
end

function mouse:getButtonList()
    return list
end

--- Returns the position of the mouse relative to the given camera.
--- @param camera comet.gfx.Camera
--- @return number x
--- @return number y
function mouse:getCameraPosition(camera)
    local trans = camera:getTransform()

    local w, h = camera:getOriginalWidth(), camera:getOriginalHeight()
    local x1, y1 = trans:transformPoint(0, 0)
    local x2, y2 = trans:transformPoint(w, 0)
    local x3, y3 = trans:transformPoint(w, h)
    local x4, y4 = trans:transformPoint(0, h)

    local minX = math.min(x1, x2, x3, x4)
    local minY = math.min(y1, y2, y3, y4)
    
    return comet.adjustPositionToGame(self.screenPosition.x - minX, self.screenPosition.y - minY)
end

--- Checks if the mouse is over the given object
--- @param object comet.gfx.Object2D  The object to check (if it doesn't have a bounding box, this function will return `false`)
--- @param camera comet.gfx.Camera?   The camera to check against (optional, it is recommended to specify, but will automatically detect if not specified)
function mouse:overlaps(object, camera)
    if not object or not object.getBoundingBox then
        return false
    end
    if not camera then
        local p = self.parent
        while p do
            if p and p:isInstanceOf(Camera) then
                --- @cast p comet.gfx.Camera
                camera = p
                break
            end
            p = p.parent
        end
    end
    local x, y = self.position.x, self.position.y
    local box = object:getBoundingBox(object:getTransform(), object._rect)
    if x < box.x or x > box.x + box.width or y < box.y or y > box.y + box.height then
        return false
    end
    return true
end

--- @param button "left"|"middle"|"right"
function mouse:wasJustPressed(button)
    return self._justPressed[button]
end

--- @param button "left"|"middle"|"right"
function mouse:wasJustReleased(button)
    return self._justReleased[button]
end

--- @param button "left"|"middle"|"right"
function mouse:isPressed(button)
    return self._pressed[button]
end

function mouse:handleEvent(e)
    if e.type == "mousebutton" then
        self._pressed[e.button] = e.pressed
        if e.pressed then
            self._justPressed[e.button] = true
        else
            self._justReleased[e.button] = true
        end

    elseif e.type == "mousewheel" then
        self.wheel:set(e.x, e.y)
    
    elseif e.type == "mousemove" then
        self.position:set(comet.adjustPositionToGame(e.x, e.y))
        self.screenPosition:set(e.x, e.y)
        self.delta:set(e.deltaX, e.deltaY)
    end
end

function mouse:update()
    self.delta:set(0, 0)
    self.wheel:set(0, 0)

    self._justPressed.left = false
    self._justPressed.middle = false
    self._justPressed.right = false

    self._justReleased.left = false
    self._justReleased.middle = false
    self._justReleased.right = false
end

return mouse
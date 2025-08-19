local middleclass = cometreq("lib.middleclass") --- @type comet.lib.MiddleClass

--- @class comet.core.Screen : comet.util.Class
local Screen = Class("Screen")

function Screen:__init__()
    self.children = {}
    
    --- @protected
    self._childrenByTag = {}
end

function Screen:enter() end

function Screen:addChild(object, tag)
    if not object then
        Log.warn("You can't add an invalid child to a screen!")
        return
    end
    if table.contains(self.children, object) then
        Log.warn("You can't add the same object twice!")
        return
    end
    if tag then
        self._childrenByTag[tag] = object
    end
    object.parent = self
    table.insert(self.children, object)
end

function Screen:insertChild(position, object, tag)
    if not object then
        Log.warn("You can't add an invalid child to a screen!")
        return
    end
    if table.contains(self.children, object) then
        Log.warn("You can't insert the same object twice!")
        return
    end
    if tag then
        self._childrenByTag[tag] = object
        object.tag = tag
    end
    object.parent = self
    table.insert(self.children, position, object)
end

function Screen:moveChild(object, newPosition)
    if not object then
        Log.warn("You can't move an invalid object's position!")
        return
    end
    table.removeItem(self.children, object)
    table.insert(self.children, newPosition, object)
end

function Screen:removeChild(object)
    if not object then
        Log.warn("You can't remove an invalid child from a screen!")
        return
    end
    object.parent = self
    table.removeItem(self.children, object)
    if object.tag then
        self._childrenByTag[object.tag] = nil
        object.tag = nil
    end
end

--- @param tag string
function Screen:getChildByTag(tag)
    return self._childrenByTag[tag]
end

function Screen:update(dt)
    for i = 1, #self.children do
        local object = self.children[i] --- @type comet.core.Object
        object:_update(dt)
    end
end

function Screen:draw()
    for i = 1, #self.children do
        local object = self.children[i] --- @type comet.core.Object
        object:_draw()
    end
end

function Screen:input(e)
    for i = 1, #self.children do
        local object = self.children[i] --- @type comet.core.Object
        object:_input()
    end
end

function Screen:exit()
    for i = 1, #self.children do
        local object = self.children[i] --- @type comet.core.Object
        object:destroy()
    end
    self.children = nil
end

return Screen
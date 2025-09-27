local middleclass = cometreq("lib.middleclass") --- @type comet.lib.MiddleClass

--- @class comet.core.Object : comet.util.Class
local Object = Class("Object", ...)

function Object:__init__()
    self.tag = nil

    self.parent = nil --- @type comet.core.Object

    self.children = {}

    --- Whether or not this object is active (updating every frame)
    self.active = true

    --- Whether or not this object is visible (drawing every frame)
    self.visible = true

    --- Whether or not this object should exist (updating and drawing, setting this to `false` will stop them regardless of the individual flags)
    self.exists = true
    
    --- @protected
    self._childrenByTag = {}
end

function Object:addChild(object, tag)
    if not object then
        Log.warn("You can't add an invalid child to a Object!")
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

function Object:insertChild(position, object, tag)
    if not object then
        Log.warn("You can't add an invalid child to an object!")
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

function Object:moveChild(object, newPosition)
    if not object then
        Log.warn("You can't move an invalid object's position!")
        return
    end
    table.removeItem(self.children, object)
    table.insert(self.children, newPosition, object)
end

function Object:removeChild(object)
    if not object then
        Log.warn("You can't remove an invalid child from an object!")
        return
    end
    object.parent = nil
    table.removeItem(self.children, object)
    if object.tag then
        self._childrenByTag[object.tag] = nil
        object.tag = nil
    end
end

--- @param newParent comet.core.Object
function Object:reparent(newParent)
    if not newParent then
        Log.warn("You can't reparent an object to an invalid parent!")
        return
    end
    if self.parent then
        table.removeItem(self.parent.children, self)
    end
    self.parent = newParent
end

--- @param tag string
function Object:getChildByTag(tag)
    return self._childrenByTag[tag]
end

--- @param index integer
function Object:getChild(index)
    return self.children[index]
end

function Object:kill()
    self.exists = false
end

function Object:revive()
    self.exists = true
end

--- @protected
function Object:_update(dt)
    self:update(dt)
    for i = 1, #self.children do
        local object = self.children[i] --- @type comet.core.Object
        if object and object.exists and object.active then
            object:_update(dt)
        end
    end
    self:postUpdate(dt)
end

function Object:update(dt) end
function Object:postUpdate(dt) end

--- @protected
function Object:_draw()
    self:draw()
    for i = 1, #self.children do
        local object = self.children[i] --- @type comet.core.Object
        if object and object.exists and object.visible then
            object:_draw()
        end
    end
    self:postDraw()
end

function Object:draw() end
function Object:postDraw() end

--- @protected
function Object:_input(e)
    for i = 1, #self.children do
        local object = self.children[i] --- @type comet.core.Object
        if object and object.exists and object.active then
            object:_input(e)
        end
    end
    self:input(e)
end

function Object:input(e) end

function Object:destroy()
    if not self.children then
        return
    end
    for i = 1, #self.children do
        local object = self.children[i] --- @type comet.core.Object
        if object then
            object:destroy()
        end
    end
    self.children = nil
end

return Object
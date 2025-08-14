local middleclass = cometreq("lib.middleclass") --- @type comet.lib.MiddleClass

--- @class comet.core.Object : comet.util.Class
local Object = Class("Object")

function Object:__init__()
    self.tag = nil

    self.children = {}
    
    --- @protected
    self._childrenByTag = {}
end

function Object:addChild(object, tag)
    if not object then
        print("You can't add an invalid child to a Object!")
        return
    end
    if table.contains(self.children, object) then
        print("You can't add the same object twice!")
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
        print("You can't add an invalid child to an object!")
        return
    end
    if table.contains(self.children, object) then
        print("You can't insert the same object twice!")
        return
    end
    if tag then
        self._childrenByTag[tag] = object
        object.tag = tag
    end
    object.parent = self
    table.insert(self.children, position, object)
end

function Object:removeChild(object)
    if not object then
        print("You can't remove an invalid child from an object!")
        return
    end
    object.parent = nil
    table.removeItem(self.children, object)
    if object.tag then
        self._childrenByTag[object.tag] = nil
        object.tag = nil
    end
end

--- @param tag string
function Object:getChildByTag(tag)
    return self._childrenByTag[tag]
end

--- @protected
function Object:_update(dt)
    for i = 1, #self.children do
        local object = self.children[i] --- @type comet.core.Object
        if object then
            object:_update(dt)
        end
    end
    self:update(dt)
end

function Object:update(dt) end

--- @protected
function Object:_draw()
    for i = 1, #self.children do
        local object = self.children[i] --- @type comet.core.Object
        if object then
            object:_draw()
        end
    end
    self:draw()
end

function Object:draw() end

--- @protected
function Object:_input()
    for i = 1, #self.children do
        local object = self.children[i] --- @type comet.core.Object
        object:_input()
    end
    self:input()
end

function Object:input() end

function Object:destroy()
    for i = 1, #self.children do
        local object = self.children[i] --- @type comet.core.Object
        object:destroy()
    end
    self.children = nil
end

return Object
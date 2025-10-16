local middleclass = cometreq("lib.middleclass") --- @type comet.lib.MiddleClass

--- @class comet.core.Object : comet.util.Class
local Object = Class("Object", ...)

function Object:__init__()
    self.tag = nil

    self.parent = nil --- @type comet.core.Object

    --- The children of this object.
    --- 
    --- If you want to get the amount of children, use `getChildCount()`
    --- instead of getting the table length, otherwise you might get unexpected crashes/problems!
    self.children = {}

    --- Whether or not this object is active (updating every frame)
    self.active = true

    --- Whether or not this object is visible (drawing every frame)
    self.visible = true

    --- Whether or not this object should exist (updating and drawing, setting this to `false` will stop them regardless of the individual flags)
    self.exists = true

    --- Determines how this object should be updated
    --- 
    --- - `inherit` - Inherit from the parent object's update mode.
    --- - `always` - Always update the object, unless the `active` flag is set to `false`.
    --- - `never` - Never update the object, regardless of the `active` flag.
    self.updateMode = "inherit" --- @type "inherit"|"always"|"never"
    
    --- @protected
    self._childCount = 0 --- @type integer

    --- @protected
    self._childrenByTag = {}

    --- @protected
    self._pendingToRemove = {}
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
    if object.parent then
        Log.warn("You can't add a child object that already has a parent! Use Object:reparent() instead!")
        return
    end
    if tag then
        self._childrenByTag[tag] = object
    end
    object.parent = self
    self.children[#self.children + 1] = object --- @type comet.core.Object
    self._childCount = #self.children
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
    if object.parent then
        Log.warn("You can't add a child object that already has a parent! Use Object:reparent() instead!")
        return
    end
    if tag then
        self._childrenByTag[tag] = object
        object.tag = tag
    end
    object.parent = self
    table.insert(self.children, position, object)
    self._childCount = #self.children
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
    table.insert(self._pendingToRemove, object)

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
        self.parent:removeChild(self)
    end
    self.parent = newParent
    newParent:addChild(self)
end

--- @param tag string
function Object:getChildByTag(tag)
    return self._childrenByTag[tag]
end

--- @param index integer
function Object:getChild(index)
    return self.children[index]
end

function Object:getChildCount()
    return self._childCount
end

function Object:kill()
    self.exists = false
end

function Object:revive()
    self.exists = true
end

---
--- @param  class    comet.core.Object
--- @param  factory  function?
--- @param  revive   boolean?
---
--- @return comet.core.Object
---
function Object:recycle(class, factory, revive)
    revive = (revive ~= nil) and revive or true
    for i = 1, self._childCount do
        local actor = self.children[i] --- @type comet.core.Object
        if actor and not actor.exists and Class.isinstanceof(actor, class) then
            if revive then
                actor:revive()
            end
            return actor
        end
    end
    if factory then
        local actor = factory()
        self:addChild(actor)
        return actor
    end
    local actor = class:new()
    self:addChild(actor)
    return actor
end

function Object:shouldUpdate()
    if self.updateMode == "inherit" then
        if self.parent then
            return self.parent:shouldUpdate() and self.active
        else
            return self.active
        end
    elseif self.updateMode == "always" then
        return self.active

    elseif self.updateMode == "never" then
        return false
    end
    return true
end

--- @protected
function Object:_update(dt)
    if not self.children then
        return
    end
    local pendingToRemove = self._pendingToRemove
    if #pendingToRemove ~= 0 then
        for i = 1, #pendingToRemove do
            local child = pendingToRemove[i]
            table.removeItem(self.children, child)
        end
        self._childCount = #self.children
        self._pendingToRemove = {}
    end
    local shouldUpdate = self:shouldUpdate()
    if shouldUpdate then
        self:update(dt)
    end
    for i = 1, self:getChildCount() do
        local object = self.children[i] --- @type comet.core.Object
        if object and object.exists and object:shouldUpdate() then
            object:_update(dt)
        end
    end
    if shouldUpdate then
        self:postUpdate(dt)
    end
end

function Object:update(dt) end
function Object:postUpdate(dt) end

--- @protected
function Object:_draw()
    if not self.children then
        return
    end
    local pendingToRemove = self._pendingToRemove
    if #pendingToRemove ~= 0 then
        for i = 1, #pendingToRemove do
            local child = pendingToRemove[i]
            table.removeItem(self.children, child)
        end
        self._pendingToRemove = {}
    end
    self:draw()
    for i = 1, self:getChildCount() do
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
    if not self.children then
        return
    end
    local shouldUpdate = self:shouldUpdate()
    if shouldUpdate then
        self:input(e)
    end
    if self.children then
        for i = 1, self:getChildCount() do
            local object = self.children[i] --- @type comet.core.Object
            if object and object.exists and object:shouldUpdate() then
                object:_input(e)
            end
        end
    end
    if shouldUpdate then
        self:postInput(e)
    end
end

function Object:input(e) end
function Object:postInput(e) end

function Object:destroy()
    if not self.children then
        return
    end
    for i = 1, self:getChildCount() do
        local object = self.children[i] --- @type comet.core.Object
        if object then
            object:destroy()
        end
    end
    if self.parent then
        self.parent:removeChild(self)
    end
    self.children = nil
    self._childCount = 0
end

return Object
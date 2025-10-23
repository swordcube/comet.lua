local UIUtil = cometreq("ui.uiutil") --- @type comet.ui.UIUtil

--- @class comet.ui.UIComponent : comet.gfx.Object2D
local UIComponent, super = Object2D:subclass("UIComponent", ...)

function UIComponent:__init__(x, y)
    super.__init__(self, x, y)
    UIUtil.allComponents[#UIUtil.allComponents + 1] = self

    self.cursorType = "default" --- @type "default"|"pointer"|"grabbing"|"text"|"eraser"|"cell"

    self._checkingMouseOverlap = false --- @protected
end

function UIComponent:checkMouseOverlap()
    self._checkingMouseOverlap = true
    local ret = comet.mouse:overlaps(self) and #UIUtil.allDropDowns == 0
    self._checkingMouseOverlap = false
    return ret
end

function UIComponent:destroy()
    table.removeItem(UIUtil.allComponents, self)
    table.removeItem(UIUtil.focusedComponents, self)
    super.destroy(self)
end

return UIComponent
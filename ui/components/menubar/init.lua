local UIComponent = cometreq("ui.uicomponent") --- @type comet.ui.UIComponent
local MenuBarButton = cometreq("ui.components.menubar.button") --- @type comet.ui.components.MenuBarButton

--- @class comet.ui.components.MenuBar : comet.ui.UIComponent
local MenuBar, super = UIComponent:extend("MenuBar", ...)

function MenuBar:__init__()
    super.__init__(self)

    self.bg = Image:new(comet.getEmbeddedImage("ui/menu_bar")) --- @type comet.gfx.Image
    self.bg.centered = false
    self.bg:setGraphicSize(comet.getDesiredWidth(), self.bg:getHeight())
    self:addChild(self.bg)

    self.leftButtons = Object2D:new() --- @type comet.gfx.Object2D
    self.leftButtons.centered = false
    self:addChild(self.leftButtons)

    self.rightButtons = Object2D:new() --- @type comet.gfx.Object2D
    self.rightButtons.centered = false
    self.rightButtons.position.x = comet.getDesiredWidth()
    self:addChild(self.rightButtons)
end

--- @param side "left"|"right"
--- @param items table[]
function MenuBar:addItems(side, items)
    local sideGrp = side == "left" and self.leftButtons or self.rightButtons
    for i = 1, #items do
        local button = MenuBarButton:new(0, 0, items[i].text) --- @type comet.ui.components.MenuBarButton
        button.position.x = sideGrp:getChildrenBoundingBox().width
        sideGrp:addChild(button)
    end
end

function MenuBar:checkMouseOverlap()
    self._checkingMouseOverlap = true
    local ret = comet.mouse:overlaps(self.bg) and #UIUtil.allDropDowns == 0
    self._checkingMouseOverlap = false
    return ret
end

return MenuBar
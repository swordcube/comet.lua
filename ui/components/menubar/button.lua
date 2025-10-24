local UIUtil = cometreq("ui.uiutil") --- @type comet.ui.UIUtil
local UIComponent = cometreq("ui.uicomponent") --- @type comet.ui.UIComponent

--- @class comet.ui.components.MenuBarButton : comet.ui.UIComponent
local MenuBarButton, super = UIComponent:extend("MenuBarButton", ...)

function MenuBarButton:__init__(x, y, text)
    super.__init__(self, x, y)

    self.bg = Image:new(comet.getEmbeddedImage("ui/menu_bar")) --- @type comet.gfx.Image
    self.bg.centered = false
    self:addChild(self.bg)

    self.label = Label:new(8, 0) --- @type comet.gfx.Label
    self.label:setFont(comet.getEmbeddedFont("montserrat/semibold"))
    self.label:setSize(14)
    self.label:setBorderColor(Color.BLACK)
    self.label.borderSize = 1
    self.label.centered = false
    self.label.text = text
    self.label.position.y = (self.bg:getHeight() - self.label:getHeight()) * 0.5
    self:addChild(self.label)

    self.bg:setGraphicSize(self.label:getWidth() + 16, self.bg:getHeight())
end

function MenuBarButton:checkMouseOverlap()
    self._checkingMouseOverlap = true
    local ret = comet.mouse:overlaps(self.bg) and #UIUtil.allDropDowns == 0
    self._checkingMouseOverlap = false
    return ret
end

function MenuBarButton:update(dt)
    super.update(self, dt)

    local isHovered = self:checkMouseOverlap()
    local offset = isHovered and (comet.mouse:isPressed("left") and -0.15 or 0.15) or 0
    
    local tint = self.bg:getTint()
    tint:set(1 + offset, 1 + offset, 1 + offset, 1)
end

return MenuBarButton
--- @class comet.ui.UIUtil
local UIUtil = {}

UIUtil.allComponents = {} --- @type comet.ui.UIComponent[]
UIUtil.focusedComponents = {} --- @type comet.ui.UIComponent[]
UIUtil.allDropDowns = {} --- @type comet.gfx.Object2D[]

return UIUtil
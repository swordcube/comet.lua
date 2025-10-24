--- @class comet.core.PluginManager : comet.util.Class
local PluginManager = Class:extend("PluginManager", ...)

function PluginManager:__init__()
    self.plugins = {}
    self.drawOnTop = true
end

function PluginManager:add(plugin)
    table.insert(self.plugins, plugin)
end

function PluginManager:remove(plugin)
    table.removeItem(self.plugins, plugin)
end

function PluginManager:update(dt)
    for i = 1, #self.plugins do
        local plugin = self.plugins[i] --- @type comet.core.Plugin
        plugin:update(dt)
    end
end

function PluginManager:draw()
    for i = 1, #self.plugins do
        local plugin = self.plugins[i] --- @type comet.core.Plugin
        plugin:draw()
    end
end

function PluginManager:input(e)
    for i = 1, #self.plugins do
        local plugin = self.plugins[i] --- @type comet.core.Plugin
        plugin:input(e)
    end
end

return PluginManager
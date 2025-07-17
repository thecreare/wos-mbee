local plugin = _G.plugin

local Constants = {}

-- If the plugin is currently running in a local development environment
Constants.IS_LOCAL = if string.find(plugin.Name, ".rbxm") or string.find(plugin.Name, ".lua") then true else false

return Constants
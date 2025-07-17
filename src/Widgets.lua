local plugin = _G.plugin
local Branding = require(script.Parent.Modules.Branding)

local PrimaryWidget = plugin:CreateDockWidgetPluginGui("MBTools", DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Left,  -- Widget will be initialized in floating panel
	true,   -- Widget will be initially enabled
	false,  -- Don't override the previous enabled state
	plugin:GetSetting("PluginSize") and plugin:GetSetting("PluginSize")[1][1] or 350,    -- Default width of the floating window
	plugin:GetSetting("PluginSize") and plugin:GetSetting("PluginSize")[1][2] or 476,    -- Default height of the floating window
	100,    -- Minimum width of the floating window
	300     -- Minimum height of the floating window
	))
PrimaryWidget.Title = Branding.NAME
PrimaryWidget.Name = Branding.NAME_ABBREVIATION .. "PrimaryWidget"

local ConfigWidget = plugin:CreateDockWidgetPluginGui("Config", DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right,  -- Widget will be initialized in floating panel
	true,   -- Widget will be initially enabled
	false,  -- Don't override the previous enabled state
	plugin:GetSetting("PluginSize") and plugin:GetSetting("PluginSize")[2][1] or 350,    -- Default width of the floating window
	plugin:GetSetting("PluginSize") and plugin:GetSetting("PluginSize")[2][2] or 500,    -- Default height of the floating window
	100,    -- Minimum width of the floating window
	130     -- Minimum height of the floating window
	))
ConfigWidget.Title = "Part Configurer"
ConfigWidget.Name = Branding.NAME_ABBREVIATION .. "ConfigWidget"

local SettingsWidget = plugin:CreateDockWidgetPluginGui("VersionSelect", DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,   -- Widget will be initially enabled
	true,  -- Don't override the previous enabled state
	350,    -- Default width of the floating window
	600,    -- Default height of the floating window
	300,    -- Minimum width of the floating window
	250     -- Minimum height of the floating window
	))
SettingsWidget.Title = "Advanced Settings"
SettingsWidget.Name = Branding.NAME_ABBREVIATION .. "SettingsWidget"

-- Very widget related thing I figured should go here
PrimaryWidget:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	plugin:SetSetting("PluginSize", {
		{PrimaryWidget.AbsoluteSize.X, PrimaryWidget.AbsoluteSize.Y},
		{ConfigWidget.AbsoluteSize.X, ConfigWidget.AbsoluteSize.Y}
	})
end)

return {
    PrimaryWidget = PrimaryWidget,
    ConfigWidget = ConfigWidget,
    SettingsWidget = SettingsWidget,
}
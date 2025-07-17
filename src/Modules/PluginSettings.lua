local plugin = _G.plugin
local Fusion = require(script.Parent.Parent.Packages.fusion)
local peek = Fusion.peek

export type Setting = {
    Key: string,
    Name: string,
    Categories: {string},
    Type: string,
    Default: any,
    Options: {string}?,
}

-- Ordered array of settings
local SettingInfo: {Setting} = {
	{
		Key = "OpenCompilerScripts",
        Name = "Open Compiler Scripts",
		Categories = {"advanced"},
		Type = "boolean",
		Default = true,
	},
    {
		Key = "ReplaceCompiles",
        Name = "Replace Old Compiles",
		Categories = {"main"},
		Type = "boolean",
		Default = false,
	},
    {
		Key = "ReplaceUploads",
        Name = "Replace Old Uploads",
		Categories = {"main"},
		Type = "boolean",
		Default = false,
	},
    {
        Key = "CompileHost",
        Name = "Upload To",
		Categories = {"main"},
		Type = "string",
		Default = "",
        Options = {"gist", "hastebin"}
	},
    {
		Key = "MalleabilityToggle",
        Name = "Malleability Check",
		Categories = {"main"},
		Type = "boolean",
		Default = true,
	},
    {
        Key = "OverlapToggle",
        Name = "Overlap Check",
		Categories = {"main"},
		Type = "boolean",
		Default = true,
    },
    {
        Key = "ScrollingText",
        Name = "Scrolling Text",
		Categories = {"advanced"},
		Type = "boolean",
		Default = true,
    },
    {
        Key = "VisualizeSpecial",
        Name = "Visualize Special Parts",
        Categories = {"advanced"},
        Type = "boolean",
        Default = true,
    },
    {
        Key = "ShowSurfaceSelector",
        Name = "Show Surface Selector",
        Categories = {"advanced"},
        Type = "boolean",
        Default = true,
    },
}
-- Convert setting key to setting info
local SettingsInfoHash: {[string]: Setting} = {}
for _, setting in SettingInfo do SettingsInfoHash[setting.Key] = setting end

-- This is not a component!! do not use this as a component!!
local function InitPluginSettings(scope: Fusion.Scope<typeof(Fusion)>)
    local PluginSettingsTable = {}
    for _, setting in SettingInfo do
        local saved = plugin:GetSetting(setting.Key)
        local value = if saved == nil then setting.Default else saved
        local value_object = scope:Value(value)
        scope:Observer(value_object):onChange(function()
            plugin:SetSetting(setting.Key, peek(value_object))
        end)
        PluginSettingsTable[setting.Key] = value_object
    end
    return PluginSettingsTable
end

local PluginSettings = {}

PluginSettings.Info = SettingsInfoHash
PluginSettings.InfoArray = SettingInfo
PluginSettings.CreateFusionValues = InitPluginSettings

return PluginSettings
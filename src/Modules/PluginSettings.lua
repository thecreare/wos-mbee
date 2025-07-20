local plugin = _G.plugin
local Branding = require(script.Parent.Branding)
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

local UploadExpireAliasTypes = {
	"single use",
	"never expire",
	"1 hour",
	"1 week",
	"1 month",
}

local GENERIC_TYPE_DEFAULT = {
    boolean = true,
    string = "",
    Resource = "",
    Vector3 = "",
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
        Options = {"gist", "hastebin", "none"},
        Default = "none",
	},
    {
        Key = "APIKey",
        Name = "PAT Token",
		Categories = {"main"},
		Type = "string",
    },
    {
        Key = "UploadName",
        Name = "Upload Name",
		Categories = {"main"},
		Type = "string",
		Default = Branding.NAME_ABBREVIATION .. "_Upload",
    },
    {
        Key = "UploadExpireTime",
        Name = "Expire Time",
        Categories = {"main"},
        Type = "string",
        Options = UploadExpireAliasTypes,
        Default = UploadExpireAliasTypes[4],
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
        Key = "TemplateMaterial",
        Name = "Template Material",
		Categories = {"main"},
		Type = "Resource",
    },
    {
        Key = "ModelOffset",
        Name = "Model Offset",
		Categories = {"main"},
		Type = "Vector3",
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
    {
        Key = "InsertPilotTypeChecker",
        Name = "Microcontroller Type Checking",
        Categories = {"advanced"},
        Type = "boolean",
        Default = true,
    },
}
-- Convert setting key to setting info
local SettingsInfoHash: {[string]: Setting} = {}
for _, setting in SettingInfo do SettingsInfoHash[setting.Key] = setting end

local function InitPluginSettings(scope: Fusion.Scope<typeof(Fusion)>)
    local PluginSettingsTable = {}
    for _, setting in SettingInfo do
        local saved = plugin:GetSetting(setting.Key)
        local value = if saved == nil then
            if setting.Default
                then setting.Default
                else GENERIC_TYPE_DEFAULT[setting.Type]
            else saved
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
PluginSettings.Values = InitPluginSettings(Fusion:scoped())

return PluginSettings
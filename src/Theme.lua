local plugin = _G.plugin

local ExtractedUtil = require(script.Parent.Modules.ExtractedUtil)
local Fusion = require(script.Parent.Packages.fusion)
local scoped = Fusion.scoped

local function CSplat(v: number): Color3
    return Color3.fromRGB(v, v, v)
end

-- I actually despise whoever did this instead of storing it as HEX
local function StringToColor3(str: string): Color3?
	if not str then return end
	local newStr = string.gsub(str, "%s", "")
	local Vals = string.split(newStr, ",")
	return if #Vals >= 3 then Color3.fromRGB(unpack(Vals :: any)) else nil
end

local STUDIO_THEME = settings().Studio.Theme
local DEFAULTS = {
    MainBackground = Enum.StudioStyleGuideColor.MainBackground,
    MainText = Enum.StudioStyleGuideColor.MainText,
    DimmedText = Enum.StudioStyleGuideColor.DimmedText,
    ScrollBarBackground = Enum.StudioStyleGuideColor.ScrollBarBackground,
    ScrollBar = Enum.StudioStyleGuideColor.ScrollBar,
    InputFieldBackground = Enum.StudioStyleGuideColor.InputFieldBackground,
    Border = Enum.StudioStyleGuideColor.Border,
    ButtonHover = Enum.StudioStyleGuideColor.Button,
    Button = Enum.StudioStyleGuideColor.MainBackground,
    ButtonText = Color3.fromRGB(0, 0, 0),
    MainButton = Enum.StudioStyleGuideColor.MainButton,
    MainContrast = Color3.fromRGB(255, 150, 50),
    MalleabilityCheck = Color3.fromRGB(255, 0, 0),
    OverlapCheck = Color3.fromRGB(255, 255, 0),
}
-- Parse defaults to convert enum items to actual colors
for k, v in DEFAULTS do
    if typeof(v) == "EnumItem" then
        DEFAULTS[k] = STUDIO_THEME:GetColor(v :: Enum.StudioStyleGuideColor)
    end
end

local THEMES = {}

do -- Classic theme
    THEMES.Classic = {}
end

do -- Purple high contrast theme
    local PURPLE = Color3.fromRGB(128, 0, 255)
    THEMES.HighContrast = {
        MainBackground = CSplat(0),
        MainText = PURPLE,
        DimmedText = CSplat(128),
        ScrollBarBackground = CSplat(0),
        ScrollBar = PURPLE,
        InputFieldBackground = CSplat(16),
        Border = PURPLE,
        -- ButtonHover = Enum.StudioStyleGuideColor.Button,
        -- Button = Enum.StudioStyleGuideColor.MainBackground,
        ButtonText = CSplat(255),
        -- MainButton = Enum.StudioStyleGuideColor.MainButton,
        MainContrast = PURPLE,
        MalleabilityCheck = Color3.fromRGB(255, 0, 0),
        OverlapCheck = Color3.fromRGB(255, 255, 0),
    }
end

local scope = scoped(Fusion)

local Theme = {}

type C = Fusion.Value<Color3>
Theme.COLORS = {} :: {
    MainBackground: C,
    MainText: C,
    DimmedText: C,
    ScrollBarBackground: C,
    ScrollBar: C,
    InputFieldBackground: C,
    Border: C,
    ButtonHover: C,
    Button: C,
    ButtonText: C,
    MainButton: C,
    MainContrast: C,
    MalleabilityCheck: C,
    OverlapCheck: C,
}

-- Load colors from plugin settings
for k, v in DEFAULTS do
    local key = tostring(k) .. "Color"
    local color = StringToColor3(plugin:GetSetting(key)) or v
    local value = scope:Value(color)
    Theme.COLORS[k] = value
    scope:Observer(value):onChange(function()
        plugin:SetSetting(key, ExtractedUtil.Color3ToString(Fusion.peek(value)))
    end)
end

function Theme.Set(theme: string)
    for k, v in DEFAULTS do
        Theme.COLORS[k]:set(THEMES[theme][k] or v)
    end
end

Theme.font = scope:Value(Enum.Font.SourceSans)
-- This got out of hand fast...
local MAP_FONT_TO_ENUM = {}
for _, font in Enum.Font:GetEnumItems() do
    MAP_FONT_TO_ENUM[font.Name] = font
end
local function GetWeightVariantFromThemeFont(weight: Enum.FontWeight)
    return function (use)
        local font = use(Theme.font) :: Enum.Font
        local ok, modified = pcall(function() return MAP_FONT_TO_ENUM[font.Name .. weight.Name] end)
        if ok and modified then
            return Font.fromEnum(modified)
        end
        return Font.fromName(font.Name, weight)
    end
end
Theme.font_light = scope:Computed(GetWeightVariantFromThemeFont(Enum.FontWeight.Light))
Theme.font_regular = scope:Computed(GetWeightVariantFromThemeFont(Enum.FontWeight.Regular))
Theme.font_bold = scope:Computed(GetWeightVariantFromThemeFont(Enum.FontWeight.Bold))

return Theme
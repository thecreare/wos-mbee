local Selection = game:GetService("Selection")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ScriptEditorService = game:GetService("ScriptEditorService")

local Parts = script:WaitForChild("Parts")
local Camera = workspace:FindFirstChildWhichIsA("Camera")

local MalleabilityConnections = {}
local Adornees = {}

local OpenCompilerScripts = plugin:GetSetting("OpenCompilerScripts") or true
local ReplaceCompiles = plugin:GetSetting("ReplaceCompiles") or false
local ReplaceUploads = plugin:GetSetting("ReplaceUploads") or false
local VisualizeSpecial = plugin:GetSetting("VisualizeSpecial") or false
local CompileHost = plugin:GetSetting("CompileHost") or ''

local compilerSettings = {
	Offset = Vector3.zero,
	ShowTODO = false,
}

local UploadExpireTypes = {
	"onetime",
	"never",
	"3600",
	"604800",
	"2592000",
}
local UploadExpireAliasTypes = {
	"single use",
	"never expire",
	"1 hour",
	"1 week",
	"1 month",
}
local UploadExpireTime = plugin:GetSetting("UploadExpireTime") or UploadExpireAliasTypes[4]


local ScrollingText = plugin:GetSetting("ScrollingText") or true
local APIKey = plugin:GetSetting("APIKey") or ''
local CustomMaterials = {}; pcall(function() CustomMaterials = HttpService:JSONDecode(plugin:GetSetting("SavedCustomMaterials")) end)

local createSharedToolbar = require(script.createSharedToolbar)
local PartData = require(script.PartData)

-- Used to print Required Materials for users who have Log Mode enabled in their Output
local repr = require(3148021300)

--rostrap preloading
require(script.Packages.Checkbox)
require(script.Packages.RippleButton)
require(script.Packages.ReplicatedPseudoInstance)
local PseudoInstance = require(script.Packages.PseudoInstance)

local LuaEncode = require(script.Packages.LuaEncode)

local CustomModules = script.Modules
local Logger = require(CustomModules.Logger)
local CompileUploader = require(CustomModules.Uploader)
local CompatabilityReplacements = require(CustomModules.Compatability)
local InfoConstants = require(CustomModules.Settings)
local ExtractedUtil = require(CustomModules.ExtractedUtil)

-- Fix constants having wrong case
do
	local LOWER_TO_CORRECT = {}
	for _, v in Parts:GetChildren() do
		LOWER_TO_CORRECT[v.Name:lower()] = v.Name
	end
	for _, cat_parts in InfoConstants.SearchCategories do
		for i, part in cat_parts do
			cat_parts[i] = LOWER_TO_CORRECT[part] or part
		end
	end
end

local Compiler = nil
local Compilers = {}
local PartMetadata = nil
local ConfigData = nil
local Components: {Configuration} = {}

local function SelectCompiler(i)
	local c = Compilers[i]
	Compiler = c

	c.Selected = true
	Components, PartMetadata, ConfigData = c.Components, c.PartMetadata, c.ConfigData
end

for i, comp in pairs(script.Compilers:GetChildren()) do
	local c = require(comp)
	Compilers[i] = c

	c.Components = comp.Components:GetChildren()
	c.PartMetadata = require(comp.PartMetadata)
	c.ConfigData = require(comp.PartMetadata.ConfigData)

	if Compilers[i].Default == true then
		SelectCompiler(i)
	end
end

local Widget = plugin:CreateDockWidgetPluginGui("MBTools", DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Left,  -- Widget will be initialized in floating panel
	true,   -- Widget will be initially enabled
	false,  -- Don't override the previous enabled state
	plugin:GetSetting("PluginSize") and plugin:GetSetting("PluginSize")[1][1] or 350,    -- Default width of the floating window
	plugin:GetSetting("PluginSize") and plugin:GetSetting("PluginSize")[1][2] or 476,    -- Default height of the floating window
	100,    -- Minimum width of the floating window
	300     -- Minimum height of the floating window
	))
Widget.Title = "MB: Edited: Edited Tools"

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

local VersionSelectWidget = plugin:CreateDockWidgetPluginGui("VersionSelect", DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,   -- Widget will be initially enabled
	true,  -- Don't override the previous enabled state
	350,    -- Default width of the floating window
	600,    -- Default height of the floating window
	300,    -- Minimum width of the floating window
	250     -- Minimum height of the floating window
	))
VersionSelectWidget.Title = "Advanced Settings"

local ConfigValues = {}

local OverlapConnections = {}
local TemporaryConnections = {}

local function StringToColor3(str)
	if not str then return end
	local newStr = string.gsub(str, "%s", "")
	local Vals = string.split(newStr, ",")
	return #Vals >= 3 and Color3.fromRGB(unpack(Vals)) or Color3.new(1,1,1)
end

local Colors = 
	{
		MainBackground = StringToColor3(plugin:GetSetting("MainBackgroundColor")) or settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
		MainText = StringToColor3(plugin:GetSetting("MainTextColor")) or settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText),
		DimmedText = StringToColor3(plugin:GetSetting("DimmedTextColor")) or settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.DimmedText),
		ScrollBarBackground = StringToColor3(plugin:GetSetting("ScrollBarBackgroundColor")) or settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.ScrollBarBackground),
		ScrollBar = StringToColor3(plugin:GetSetting("ScrollBarColor")) or settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.ScrollBar),
		InputFieldBackground = StringToColor3(plugin:GetSetting("InputFieldBackgroundColor")) or settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
		Border = StringToColor3(plugin:GetSetting("BorderColor")) or settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Border),
		MainContrast = StringToColor3(plugin:GetSetting("MainContrastColor")) or Color3.fromRGB(255, 150, 50),
		ButtonHover = StringToColor3(plugin:GetSetting("ButtonHoverColor")) or settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button),
		Button = StringToColor3(plugin:GetSetting("ButtonColor")) or settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
		ButtonText = StringToColor3(plugin:GetSetting("ButtonTextColor")) or settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.ButtonText),
		MainButton = StringToColor3(plugin:GetSetting("MainButtonColor")) or settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton),
		MalleabilityCheck = StringToColor3(plugin:GetSetting("MalleabilityCheckColor")) or Color3.fromRGB(255, 0, 0),
		OverlapCheck = StringToColor3(plugin:GetSetting("OverlapCheckColor")) or Color3.fromRGB(255, 255, 0),
	}

local UIElements = 
	{
		Temporary = {},

		Frames = {},
		ContrastFrames = {},
		Labels = {},
		ContrastLabels = {},
		Boxes = {},
		Scrolls = {},
		Toggles = {},
		Buttons = {},
		TextButtons = {},
		InsetButtons = {},
		ColoredObjects = {},
		FloatingLabels = {},
		MalleabilityIndicators = {},
		OverlapIndicators = {},
	}

local function SyncColors(UIs)
	if not UIs then
		Logger.print("UPDATING UI COLORS...")
		UIs = UIElements
	end

	for _, Object in (UIs.MalleabilityIndicators or {}) do
		Object.Color3 = Colors.MalleabilityCheck
		Object.SurfaceColor3 = Colors.MalleabilityCheck
	end

	for _, Object in (UIs.OverlapIndicators or {}) do
		Object.Color3 = Colors.OverlapCheck
		Object.SurfaceColor3 = Colors.OverlapCheck
	end

	for _, Object in (UIs.ColoredObjects or {}) do
		Object.Color = Colors.MainContrast
	end

	for _, Frame in (UIs.Frames or {}) do
		Frame.BackgroundColor3 = Colors.MainBackground
		Frame.BorderColor3 = Colors.Border
	end

	for _, ContrastFrame in (UIs.ContrastFrames or {}) do
		ContrastFrame.BackgroundColor3 = Colors.MainContrast
		ContrastFrame.BorderColor3 = Colors.Border
	end

	for _, TextButton in (UIs.TextButtons or {}) do
		TextButton.BackgroundColor3 = Colors.Button
		TextButton.BorderColor3 = Colors.Border
		TextButton.TextColor3 = Colors.ButtonText

		if UIElements.Temporary[TextButton] then continue end

		UIElements.Temporary[TextButton] = {}

		UIElements.Temporary[TextButton]["MouseEnter"] = TextButton.MouseEnter:Connect(function()
			TweenService:Create(TextButton, TweenInfo.new(0.05), { BackgroundColor3 = Colors.ButtonHover } ):Play()
		end)

		UIElements.Temporary[TextButton]["MouseLeave"] = TextButton.MouseLeave:Connect(function()
			TweenService:Create(TextButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Button } ):Play()
		end)

		UIElements.Temporary[TextButton]["Activated"] = TextButton.Activated:Connect(function()
			TextButton.BackgroundColor3 = Colors.MainButton
			TextButton.TextColor3 = Colors.Button
			TweenService:Create(TextButton, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), { BackgroundColor3 = Colors.ButtonHover, TextColor3 = Colors.ButtonText } ):Play()
		end)

	end

	for _, Scroll in (UIs.Scrolls or {}) do
		Scroll.BackgroundColor3 = Colors.ScrollBarBackground
		Scroll.BorderColor3 = Colors.Border
		Scroll.ScrollBarImageColor3 = Colors.ScrollBar
		Scroll.ScrollBarImageTransparency = 0
		Scroll.TopImage = "rbxassetid://7058754954"
		Scroll.BottomImage = "rbxassetid://7058754954"
		Scroll.MidImage = "rbxassetid://7058754954"
	end

	for _, Toggle in (UIElements.Toggles or {}) do
		Toggle.PrimaryColor3 = Colors.MainContrast
		--Toggle.Theme = Theme
	end

	for i, Button in (UIElements.Buttons or {}) do
		if typeof(Button) == "userdata" then UIElements.Buttons[i] = nil continue end
		Button.PrimaryColor3 = Colors.MainContrast
	end

	for _, InsetButton in (UIElements.InsetButtons or {}) do
		InsetButton.PrimaryColor3 = Colors.MainContrast
	end

	for _, Box in (UIs.Boxes or {}) do
		Box.BackgroundColor3 = Colors.InputFieldBackground
		Box.BorderColor3 = Colors.Border
		Box.TextColor3 = Colors.MainText
		Box.PlaceholderColor3 = Colors.DimmedText
	end

	for _, Label in (UIs.Labels or {}) do
		Label.BackgroundColor3 = Colors.MainBackground
		Label.BorderColor3 = Colors.Border
		Label.TextColor3 = Colors.MainText

		if UIElements.Temporary[Label] and UIElements.Temporary[Label]["SizeChanged"] then continue end

		UIElements.Temporary[Label] = {}

		local OriginalText = Label.Text

		UIElements.Temporary[Label]["SizeChanged"] = Label:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if ScrollingText and Label.TextBounds.X >= Label.AbsoluteSize.X and not UIElements.Temporary[Label]["TextAnimator"] then
				UIElements.Temporary[Label]["TextAnimator"] = coroutine.create(function()
					local TextCopy = OriginalText .. "      "
					local tick = 1
					while true do
						if tick == 1 then task.wait(1) end
						Label.Text = TextCopy:sub(tick) .. TextCopy:sub(1, tick)
						tick = (tick + 1) <= #TextCopy + 1 and (tick + 1) or 1
						task.wait(0.2)
					end
				end)
				coroutine.resume(UIElements.Temporary[Label]["TextAnimator"])
			elseif UIElements.Temporary[Label]["TextAnimator"] then
				pcall(function() coroutine.close(UIElements.Temporary[Label]["TextAnimator"]) end)
				UIElements.Temporary[Label]["TextAnimator"] = nil
				Label.Text = OriginalText
			else
				Label.Text = OriginalText
			end
		end)
	end

	for _, ContrastLabel in (UIs.ContrastLabels or {}) do
		ContrastLabel.BackgroundColor3 = Colors.MainBackground
		ContrastLabel.BorderColor3 = Colors.Border
		ContrastLabel.TextColor3 = Colors.MainContrast

		if UIElements.Temporary[ContrastLabel] and UIElements.Temporary[ContrastLabel]["SizeChanged"] then continue end

		UIElements.Temporary[ContrastLabel] = {}

		local OriginalText = ContrastLabel.Text

		UIElements.Temporary[ContrastLabel]["SizeChanged"] = ContrastLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if ScrollingText and ContrastLabel.TextBounds.X >= ContrastLabel.AbsoluteSize.X and not UIElements.Temporary[ContrastLabel]["TextAnimator"] then
				UIElements.Temporary[ContrastLabel]["TextAnimator"] = coroutine.create(function()
					local TextCopy = OriginalText .. "      "
					local tick = 1
					while true do
						if tick == 1 then task.wait(1) end
						ContrastLabel.Text = TextCopy:sub(tick) .. TextCopy:sub(1, tick)
						tick = (tick + 1) <= #TextCopy + 1 and (tick + 1) or 1
						task.wait(0.2)
					end
				end)
				coroutine.resume(UIElements.Temporary[ContrastLabel]["TextAnimator"])
			elseif UIElements.Temporary[ContrastLabel]["TextAnimator"] then
				pcall(function() coroutine.close(UIElements.Temporary[ContrastLabel]["TextAnimator"]) end)
				UIElements.Temporary[ContrastLabel]["TextAnimator"] = nil
				ContrastLabel.Text = OriginalText
			else
				ContrastLabel.Text = OriginalText
			end
		end)
	end

	for _, FloatingLabel in (UIs.FloatingLabels or {}) do
		FloatingLabel.BackgroundColor3 = Colors.MainBackground
		FloatingLabel.TextStrokeColor3 = Colors.MainBackground
		FloatingLabel.BorderColor3 = Colors.Border
		FloatingLabel.TextColor3 = Colors.MainContrast
	end
end








local function CheckCompat(Name)
	for i,v in CompatabilityReplacements.COMPAT_NAME_REPLACEMENTS do
		if v:lower() == Name:lower() then return i end
	end
end

local function CreateAdornee(subject, color, issue)
	if Adornees[subject] and Adornees[subject][issue] then return end
	if not Adornees[subject] then Adornees[subject] = {} end
	local box = Instance.new("SelectionBox")
	box.Adornee = subject
	box.Color3 = color
	box.SurfaceColor3 = color
	box.SurfaceTransparency = 0.8
	box.LineThickness = 0.07
	box.Name = issue .. "Box"
	box.Archivable = false
	box.Parent = subject
	Adornees[subject][issue] = box
	return box
end

local function CheckMalleability(Value)
	if typeof(Value) == "table" then
		for _, _Value in Value do
			CheckMalleability(_Value)
		end
		return
	end

	if not (typeof(Value) == "Instance" and Value:IsA("BasePart")) then return end

	local PartMalleability
	if Value:FindFirstChild("TempType") then
		PartMalleability = Compiler:GetMalleability(tostring(Value.TempType.Value or Value))
	else
		PartMalleability = Compiler:GetMalleability(tostring(Value))
	end

	if not PartMalleability then return end
	
	if ExtractedUtil.CheckMalleabilityValue(Value, PartMalleability) then
		if Adornees[Value] and Adornees[Value].M then
			Adornees[Value].M:Destroy()
			Adornees[Value].M = nil
		end
	else
		local MalleabilityBox = CreateAdornee(Value, Colors.MalleabilityCheck, "M")
		if MalleabilityBox then table.insert(UIElements.MalleabilityIndicators, MalleabilityBox) end
	end
end

local function ApplyColorCopy(Object)
	if not Object then warn("[MB:E:E] COLORCOPY FAIL, NO OBJECT") return end
	for _, v in pairs(Object:GetChildren()) do
		if v.Name ~= "ColorCopy" then continue end
		if v:IsA("SpecialMesh") then v.VertexColor = Vector3.new(Object.Color.R, Object.Color.G, Object.Color.B) end
		if v:IsA("Texture") or v:IsA("Decal") then v.Color3 = Object.Color end
	end
end

local function CheckTableMalleability(List)
	
	for i,v in Adornees do
		if not v.M then continue end
		v.M:Destroy()
		Adornees[i].M = nil
	end
	
	for _, v in pairs(MalleabilityConnections) do
		v:Disconnect()
	end

	MalleabilityConnections = {}

	if not plugin:GetSetting("MalleabilityToggle") then return end
	if not List then return end
	if typeof(List) ~= 'table' then return end
	if not Widget.Enabled then return end

	for _, Part in ExtractedUtil.SearchTableWithRecursion(List, function(Element) return typeof(Element) == "Instance" and Element:IsA("BasePart") or typeof(Element) == "table" and Element or Element:GetChildren() end) do

		local Template = Part:FindFirstChild("TempType")

		if not Template then

			table.insert(MalleabilityConnections, Part:GetPropertyChangedSignal("Size"):Connect(function()
				CheckMalleability(Part)
			end))

			table.insert(MalleabilityConnections, Part:GetPropertyChangedSignal("CFrame"):Connect(function()
				CheckMalleability(Part)
			end))

			continue
		end

		table.insert(MalleabilityConnections, Template:GetPropertyChangedSignal("Value"):Connect(function()
			CheckMalleability(Part)
		end))

		table.insert(MalleabilityConnections, Part:GetPropertyChangedSignal("Size"):Connect(function()
			CheckMalleability(Part)
		end))

		table.insert(MalleabilityConnections, Part:GetPropertyChangedSignal("CFrame"):Connect(function()
			CheckMalleability(Part)
		end))

	end

end

local function MatchQueryToList(Query, List)
	if not Query then
		return {}
	end

	local Matched = {}

	for _, Entry in List do
		if not string.match(tostring(Entry):lower(), Query:lower()) then continue end
		table.insert(Matched, Entry)
	end

	table.sort(Matched, function(a, b)
		local aFind = string.find(tostring(a):lower(), Query:lower())
		local bFind = string.find(tostring(b):lower(), Query:lower())

		if bFind == aFind then
			return tostring(a):len() < tostring(b):len()
		end

		return bFind > aFind
	end)

	return Matched
end

local function CheckTableOverlap(List)

	for i,v in Adornees do
		if not v.O then continue end
		v.O:Destroy()
		Adornees[i].O = nil
	end

	for _,v in OverlapConnections do
		v:Disconnect()
	end
	OverlapConnections = {}

	if not plugin:GetSetting("OverlapToggle") then return end

	for _, v in ExtractedUtil.SearchTableWithRecursion(List, function(Element) return typeof(Element) == "Instance" and Element:IsA("BasePart") or typeof(Element) == "table" and Element or Element:GetChildren() end) do

		table.insert(OverlapConnections, v:GetPropertyChangedSignal("Size"):Connect(function()
			CheckTableOverlap(Selection:Get())
		end))

		table.insert(OverlapConnections, v:GetPropertyChangedSignal("CFrame"):Connect(function()
			CheckTableOverlap(Selection:Get())
		end))

		local Overlap = workspace:GetPartBoundsInBox(v.CFrame, v.Size * 0.9)
		if #Overlap <= 1 and Adornees[v] and Adornees[v].O then
			Adornees[v].O:Destroy()
			Adornees[v].O = nil
		else
			for _, Overlapping in Overlap do
				if v == Overlapping then continue end
				if not InfoConstants.Uncompressable[Overlapping.Name] then continue end
				local OverlapBox = CreateAdornee(v, Colors.OverlapCheck, "O")
				if OverlapBox then table.insert(UIElements.OverlapIndicators, OverlapBox) end
				break
			end
		end

	end

end

-- Gets the volume of the given BasePart
local function GetVolume(part: BasePart): number
	return part.Size.X * part.Size.Y * part.Size.Z
end

-- Returns if given part can be used as a template material (aka set as the Resource for something like Wedge)
local function IsResource(part: BasePart): boolean
	-- As far as I'm aware every part that can be resized can be used as a template shape
	return typeof(Compiler:GetMalleability(part.Name)) == "number"
end

-- Returns if a given part is a shaped part like wedge (returns false for block)
local function IsSpecialTemplate(part: BasePart): boolean
	return PartMetadata:GetShape(part) ~= nil
end
-- Returns if given part should have a Resource config (note: the IsResource() call is to allow you to change the resource of Blocks)
local function IsTemplate(part: BasePart): boolean
	local shape = PartMetadata:GetShape(part)
	return shape or IsResource(part)
end

local function ApplyTemplates(List, Material)
	for _, Part in ExtractedUtil.SearchTableWithRecursion(List, function(Element) return typeof(Element) == "Instance" and Element:IsA("BasePart") or typeof(Element) == "table" and Element or Element:GetChildren() end) do
		if Material == nil then
			Part.Material = Enum.Material.Concrete
			Part.Transparency = 0
			Part.Reflectance = 0
			Part.Name = PartMetadata:GetShape(Part) -- TODO: This will error on part of shape Block
			continue
		end

		local TemplatePart = Parts:FindFirstChild(tostring(Material))
		if not TemplatePart then continue end
		if not IsResource(TemplatePart) then continue end -- So you don't set a resource to Hyperdrive or something

		Part.Material = TemplatePart.Material
		Part.Transparency = TemplatePart.Transparency
		Part.Reflectance = TemplatePart.Reflectance
		Part.Name = TemplatePart.Name
	end
end

local function CreateTextBox(Settings)
	if not Settings then warn("[MB:E:E] TEXTBOX MISSING SETTINGS.") return end
	--if not Settings.Parent then warn("[MB:E:E] TEXTBOX MISSING PARENT PROPERTY") return end

	local Holder = Instance.new("Frame")
	Holder.BackgroundTransparency = 1
	Holder.Size = Settings.HolderSize or UDim2.new(1, -6, 0, 30)
	Holder.Position = Settings.HolderPosition or UDim2.new()
	Holder.AnchorPoint = Settings.HolderAnchorPoint or Vector2.new()
	Holder.LayoutOrder = Settings.LayoutOrder or 1
	Holder.Visible = if Settings.HolderVisible ~= nil then Settings.HolderVisible else true
	Holder.Name = Settings.Name or "Holder"
	Holder.ZIndex = Settings.HolderZIndex or 1

	local Label = Instance.new("TextLabel")
	Label.BackgroundTransparency = 1
	Label.BorderSizePixel = 0
	Label.Size = Settings.LabelSize or UDim2.new(0.5, -4, 1, 0)
	Label.Position = Settings.LabelPosition or UDim2.new()
	Label.Text = Settings.LabelText or "Label"
	Label.Font = Enum.Font.SourceSans
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.AnchorPoint = Settings.LabelAnchorPoint or Vector2.new()
	Label.TextSize = Settings.LabelTextSize or 24
	Label.TextScaled = if Settings.LabelTextScaled ~= nil then Settings.LabelTextScaled else false
	Label.ClipsDescendants = if Settings.LabelClipsDescendants ~= nil then Settings.LabelClipsDescendants else true

	local Box = Instance.new("TextBox")
	Box.BorderSizePixel = 1
	Box.Size = Settings.BoxSize or UDim2.new(0.5, -4, 1, 0)
	Box.Position = Settings.BoxPosition or UDim2.new(0.5, 4, 0, 0)
	Box.Text = Settings.BoxText or ''
	Box.PlaceholderText = Settings.BoxPlaceholderText or "Value"
	Box.Font = Enum.Font.SourceSansLight
	Box.TextXAlignment = Enum.TextXAlignment.Left
	Box.AnchorPoint = Settings.BoxAnchorPoint or Vector2.new()
	Box.TextScaled = Settings.BoxTextScaled ~= nil or true
	Box.TextEditable = true
	Box.Font = Settings.BoxFont or "SourceSansLight"
	Box.ClearTextOnFocus = if Settings.ClearTextOnFocus ~= nil then Settings.ClearTextOnFocus else false
	Box.TextSize = Settings.BoxTextSize or 24
	Box.ClipsDescendants = Settings.BoxClipsDescendants

	table.insert(Settings.LabelUIElement and UIElements[Settings.LabelUIElement] or UIElements.Labels, Label)
	table.insert(UIElements.Boxes, Box)

	Box.Parent = Holder
	Label.Parent = Holder

	Holder.Parent = Settings.Parent or nil

	return {Holder = Holder, Label = Label, Box = Box}
end

local function CreateCheckBox(Settings)
	if not Settings then warn("[MB:E:E] CHECKBOX MISSING SETTINGS.") return end
	--if not Settings.Parent then warn("[MB:E:E] CHECKBOX MISSING PARENT PROPERTY") return end

	local Holder = Instance.new("Frame")
	Holder.BackgroundTransparency = 1
	Holder.Size = Settings.HolderSize or UDim2.new(1, -6, 0, 30)
	Holder.LayoutOrder = Settings.LayoutOrder or 1
	Holder.Visible = if Settings.HolderVisible ~= nil then Settings.HolderVisible else true
	Holder.Name = Settings.Name or "Holder"

	local Label = Instance.new("TextLabel")
	Label.BackgroundTransparency = 1
	Label.BorderSizePixel = 0
	Label.Size = Settings.LabelSize or UDim2.new(1, -33, 1, 0)
	Label.Position = Settings.LabelPosition or UDim2.new()
	Label.Text = Settings.LabelText or "Label"
	Label.Font = Enum.Font.SourceSans
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.TextSize = Settings.LabelTextSize or 24
	Label.TextScaled = Settings.LabelTextScaled ~= nil or false
	Label.ClipsDescendants = Settings.LabelClipsDescendants ~= nil or true

	local Toggle = PseudoInstance.new("Checkbox")
	Toggle.PrimaryColor3 = Colors.MainContrast or Color3.fromRGB(255, 133, 51)
	--Toggle.Theme = Theme
	Toggle.AnchorPoint = Settings.ToggleAnchorPoint or Vector2.new(1, 0.5)
	Toggle.Position = Settings.TogglePosition or UDim2.new(1, -3, 0.5, 0)
	Toggle.Checked = if Settings.ToggleValue ~= nil then Settings.ToggleValue else false

	table.insert(Settings.LabelUIElement and UIElements[Settings.LabelUIElement] or UIElements.Labels, Label)
	table.insert(UIElements.Toggles, Toggle)

	Toggle.Parent = Holder
	Label.Parent = Holder

	Holder.Parent = Settings.Parent or nil

	return {Holder = Holder, Label = Label, Toggle = Toggle}
end

local function SpawnPart(Part, Settings): Model?
	local SelectedPart

	ExtractedUtil.HistoricEvent("InsertPart", "Insert Part", function()
		SelectedPart = Part:IsA("BasePart") and Part:Clone() or MatchQueryToList(tostring(Part), script.Parts:GetChildren())
		if not SelectedPart then return end
		local RayResult = workspace:Raycast(Camera.CFrame.Position, Camera.CFrame.LookVector * ((SelectedPart.Size.X + SelectedPart.Size.Y + SelectedPart.Size.Z) / 3 * 1.5 + 10))
		SelectedPart.Position = RayResult and RayResult.Position and Vector3.new(RayResult.Position.X, RayResult.Position.Y + SelectedPart.Size.Y / 2, RayResult.Position.Z) or Camera.CFrame.Position + Camera.CFrame.LookVector * 12
		ExtractedUtil.RoundPos(SelectedPart)

		SelectedPart.Parent = workspace

		if IsSpecialTemplate(SelectedPart) then
			local query = TemplateMaterial.Box.Text
			if query == "" or query == nil then return SelectedPart end
			local Matched = MatchQueryToList(query, script.Parts:GetChildren())
			if not Matched then return SelectedPart end
			if not Matched[1] then return SelectedPart end
			if #Matched > 32 then return SelectedPart end
			ApplyTemplates({SelectedPart}, Matched[1])
			if Settings.TempColor then SelectedPart.Color = Matched[1].Color end
		end
	end)

	return SelectedPart
end

local function CreateObjectButton(Settings)
	if not Settings then warn("[MB:E:E] OBJECTBUTTON SETTINGS MISSING") return end
	if not Settings.Part then warn("[MB:E:E] OBJECTBUTTON PART MISSING") return end

	local ResultHolder = Instance.new("TextButton")
	ResultHolder.BorderSizePixel = 0
	ResultHolder.Size = UDim2.new(1, 0, 0, 20)
	ResultHolder.AnchorPoint = Vector2.new(0, 0)
	ResultHolder.Position = UDim2.new(0, 0, 0.5, 0)
	ResultHolder.Text = ""
	ResultHolder.AutoButtonColor = false
	ResultHolder.Name = Settings.Part.Name
	ResultHolder.Parent = Settings.Parent
	table.insert(UIElements.TextButtons, ResultHolder)

	local Image = Settings.Part:FindFirstChildWhichIsA("Texture") or Settings.Part:FindFirstChildWhichIsA("Decal")
	local Icon = Instance.new("ImageLabel")
	Icon.BorderSizePixel = 0
	Icon.Size = UDim2.new(0, 15, 0, 15)
	Icon.AnchorPoint = Vector2.new(0, 0.5)
	Icon.Position = UDim2.new(0, 5, 0.5, 0)
	Icon.BackgroundColor3 = Settings.Part.Color
	Icon.Image = Image and Image.Texture or InfoConstants.MaterialDecals[tostring(Settings.Part.Material.Name)] or ''
	Icon.ImageColor3 = Image and Image.Color3 or Color3.new(1, 1, 1)
	Icon.ImageTransparency = Image and Image.Transparency or InfoConstants.MaterialDecals[tostring(Settings.Part.Material.Name)] and 0.25 or 1
	Icon.Parent = ResultHolder

	local ResultLabel = Instance.new("TextLabel")
	ResultLabel.BackgroundTransparency = 1
	ResultLabel.BorderSizePixel = 0
	ResultLabel.Size = UDim2.new(1, 0, 1, 0)
	ResultLabel.Position = UDim2.new(0, 25, 0, 0)
	ResultLabel.Text = Settings.Part.Name
	ResultLabel.Font = Enum.Font.SourceSans
	ResultLabel.TextXAlignment = Enum.TextXAlignment.Left
	ResultLabel.TextSize = 16
	ResultLabel.Parent = ResultHolder
	table.insert(UIElements.Labels, ResultLabel)

	ResultHolder.Activated:Connect(function()
		SpawnPart(Settings.Part, {TempColor = true})
	end)

	SyncColors({TextButtons = {ResultHolder}, Labels = {ResultLabel}})

	if Settings.Deletable then
		local DeleteButton = PseudoInstance.new("RippleButton")
		DeleteButton.PrimaryColor3 = Colors.MainContrast
		DeleteButton.AnchorPoint = Vector2.new(1, 0.5)
		DeleteButton.Position = UDim2.new(1, -12, 0.5, 0)
		DeleteButton.Size = UDim2.new(0, 48, 1, -4)
		DeleteButton.BorderRadius = 2
		DeleteButton.Style = "Contained"
		DeleteButton.Text = "Delete"
		DeleteButton.Font = Enum.Font.SourceSansLight
		DeleteButton.TextSize = 16
		DeleteButton.Parent = ResultHolder
		table.insert(UIElements.Buttons, DeleteButton)
		SyncColors({Buttons = {DeleteButton}})

		DeleteButton.OnPressed:Connect(function()
			CustomMaterials[Settings.Part.Name] = nil
			plugin:SetSetting("SavedCustomMaterials", HttpService:JSONEncode(CustomMaterials))
			Settings.Part:Destroy()
			DeleteButton:Destroy()
			ResultHolder:Destroy()
			warn("[MB:E:E] " .. Settings.Part.Name:upper() .. " WAS SUCCESSFULLY REMOVED")
		end)
	end
end

settings().Studio.ThemeChanged:Connect(function()
	SyncColors()
end)

local function ConnectBoxToAutocomplete(Box : TextBox, List : table)

	local FoundMatchEvent = Instance.new("BindableEvent")
	FoundMatchEvent.Name = Box.Name .. "AutocompleteEvent"

	local BestMatchLabel, Match

	Box.Focused:Connect(function()
		BestMatchLabel = Instance.new("TextLabel")
		BestMatchLabel.BorderSizePixel = 1
		BestMatchLabel.TextTransparency = 0.25
		BestMatchLabel.BackgroundTransparency = 1
		BestMatchLabel.Size = UDim2.new(1, 0, 1, 0)
		BestMatchLabel.Text = ''
		BestMatchLabel.Font = Enum.Font.SourceSansLight
		BestMatchLabel.TextXAlignment = Enum.TextXAlignment.Left
		BestMatchLabel.TextScaled = true
		BestMatchLabel.Visible = false
		BestMatchLabel.Active = false
		BestMatchLabel.ZIndex = Box.ZIndex + 1
		BestMatchLabel.Name = "AutocompleteLabel"
		SyncColors({ContrastLabels = {BestMatchLabel}})
		BestMatchLabel.Parent = Box
		table.insert(UIElements.ContrastLabels, BestMatchLabel)
	end)

	Box:GetPropertyChangedSignal("Text"):Connect(function()
		task.wait()
		if not BestMatchLabel then return end

		if Box.Text == "" then
			BestMatchLabel.Visible = false
			FoundMatchEvent:Fire({})
			return
		end

		if Match and Box.Text:sub(#Box.Text, #Box.Text) == "	" then
			FoundMatchEvent:Fire(List)
			Box:ReleaseFocus(true)
			return
		end

		local Matched = MatchQueryToList(Box.Text, List)
		FoundMatchEvent:Fire(Matched)

		if tostring(Matched[1]):lower() == Box.Text:lower() or #Matched == 1 then
			local MatchStart, _ = string.find(tostring(Matched[1]):lower(), Box.Text:lower())

			local FinalString = ""
			for i, Character in tostring(Matched[1]):sub(MatchStart, #tostring(Matched[1])):split("") do
				if Box.Text:split("")[i] then
					FinalString ..= Box.Text:split("")[i]
				else
					FinalString ..= Character
				end
			end

			BestMatchLabel.Text = FinalString
			BestMatchLabel.Visible = true
			Match = Matched[1]
		else
			BestMatchLabel.Visible = false
			Match = nil
		end
	end)

	Box.FocusLost:Connect(function(EnterPressed)
		if EnterPressed and Match then
			Box.Text = tostring(Match)
			--FoundMatchEvent:Fire(List)
		end
		BestMatchLabel:Destroy()
		BestMatchLabel = nil
		Match = nil
	end)

	return FoundMatchEvent

end

local TipBoxVisible = false
local function CreateTipBoxes(Gui, Table)
	local Temporary = {}
	local HoverGui, HoverList = false, false

	local function TryRemoveTipBoxes()
		if HoverGui or HoverList then return end
		if not Temporary.Container then return end
		TipBoxVisible = false
		local ToRemove = Temporary; Temporary = {}

		local FadeOut = TweenService:Create(ToRemove.Container, TweenInfo.new(0.125, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Size = UDim2.fromOffset(Gui.AbsoluteSize.X, 0) } )
		FadeOut.Completed:Connect(function()
			for _, v in ToRemove do
				if not v then continue end
				v:Destroy()
			end
		end)
		FadeOut:Play()
	end

	Gui.MouseEnter:Connect(function()
		HoverGui = true

		if Temporary['Container'] then return end
		if TipBoxVisible then return end
		TipBoxVisible = true

		local OptionsContainer = Instance.new('ScrollingFrame')
		OptionsContainer.Position = UDim2.fromOffset(Gui.AbsolutePosition.X, Gui.AbsolutePosition.Y + Gui.AbsoluteSize.Y)
		OptionsContainer.Size = UDim2.fromOffset(Gui.AbsoluteSize.X, 0)
		OptionsContainer.ScrollBarThickness = 0

		OptionsContainer.MouseEnter:Connect(function()
			HoverList = true
		end)

		OptionsContainer.MouseLeave:Connect(function()
			HoverList = false
			TryRemoveTipBoxes()
		end)

		local OptionsList = Instance.new('UIListLayout')
		OptionsList.FillDirection = Enum.FillDirection.Vertical
		OptionsList.SortOrder = Enum.SortOrder.Name

		Temporary['Container'] = OptionsContainer; table.insert(Temporary, OptionsList)

		local Count = 0
		for _, v in Table do
			local TipBox = Instance.new("TextButton")
			TipBox.BorderSizePixel = 1
			TipBox.Size = UDim2.new(1, 0, 0, Gui.AbsoluteSize.Y)
			TipBox.Text = typeof(v) == 'string' and v or tostring(v)
			TipBox.Font = Enum.Font.SourceSansLight
			TipBox.TextXAlignment = Enum.TextXAlignment.Left
			TipBox.AutoButtonColor = false
			TipBox.TextScaled = true
			TipBox.ZIndex = 10
			TipBox.Name = typeof(v) == 'string' and v or tostring(v)
			SyncColors({TextButtons = {TipBox}})

			TipBox.Activated:Connect(function()
				Gui.Text = TipBox.Text
			end)

			TipBox.Parent = OptionsContainer

			table.insert(Temporary, TipBox)
			Count += 1
		end

		SyncColors({Scrolls = {OptionsContainer}})

		OptionsList.Parent = OptionsContainer
		OptionsContainer.Parent = Gui:FindFirstAncestorOfClass("DockWidgetPluginGui")

		local ContainerYSize = Gui:FindFirstAncestorOfClass("DockWidgetPluginGui").AbsoluteSize.Y - (Gui.AbsolutePosition.Y + Gui.AbsoluteSize.Y) - 20
		if ContainerYSize < 60 then
			OptionsContainer.AnchorPoint = Vector2.new(0, 1)
			OptionsContainer.Position = UDim2.fromOffset(Gui.AbsolutePosition.X, Gui.AbsolutePosition.Y)
			TweenService:Create(OptionsContainer, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(Gui.AbsoluteSize.X, math.clamp(Gui.AbsoluteSize.Y * Count, 0, (Gui:FindFirstAncestorOfClass("DockWidgetPluginGui").AbsoluteSize.Y - (Gui:FindFirstAncestorOfClass("DockWidgetPluginGui").AbsoluteSize.Y - Gui.AbsolutePosition.Y) - 40))) } ):Play()
		else
			TweenService:Create(OptionsContainer, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(Gui.AbsoluteSize.X, math.clamp(Gui.AbsoluteSize.Y * Count, 0, ContainerYSize)) } ):Play()
		end
		OptionsContainer.CanvasSize = UDim2.fromOffset(Gui.AbsoluteSize.X, Gui.AbsoluteSize.Y * Count)
	end)

	Gui.MouseLeave:Connect(function()
		HoverGui = false
		TryRemoveTipBoxes()
	end)

	Gui:GetPropertyChangedSignal('Parent'):Connect(function()
		if Gui.Parent or Gui.Parent ~= nil then return end
		HoverGui = false
		HoverList = false
		TryRemoveTipBoxes()
	end)
end

local ENUM_NAMES_CACHE = {}
local function GetEnumNames(enum: Enum): {string}
	if ENUM_NAMES_CACHE[enum] then return ENUM_NAMES_CACHE[enum] end

	local names = {}

	for _, name in enum:GetEnumItems() do
		table.insert(names, name.Name)
	end

	ENUM_NAMES_CACHE[enum] = names
	return names
end

local function GetAndUpdateCapacityLabel(Object, text_creator: (object_volume: number)->())
	local ObjectVolume = GetVolume(Object)
	local AverageSize = (Object.Size.X + Object.Size.Y + Object.Size.Z) / 3

	local Capacity = Object:FindFirstChild("Capacity")
	local CapacityLabel = Capacity and Capacity:FindFirstChild("CapacityLabel")

	-- Create label and bilboard if not exists
	if not Capacity then
		Capacity = Instance.new("BillboardGui")
		Capacity.AlwaysOnTop = true
		Capacity.Size = UDim2.fromScale(AverageSize, AverageSize)
		Capacity.Name = "Capacity"
		Capacity.Archivable = false

		CapacityLabel = CapacityLabel or Instance.new("TextLabel")
		CapacityLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		CapacityLabel.Position = UDim2.fromScale(0.5, 0.5)
		CapacityLabel.Size = UDim2.fromScale(1, 1)
		CapacityLabel.TextStrokeTransparency = 0
		CapacityLabel.TextColor3 = Color3.new(1, 1, 1)
		CapacityLabel.BackgroundTransparency = 1
		CapacityLabel.Font = "SciFi"
		CapacityLabel.TextScaled = true
		CapacityLabel.Text = table.concat({math.round(ObjectVolume) * 50, Compiler:GetMalleability("PowerCell") * 50}, "/")
		CapacityLabel.Name = "CapacityLabel"
		CapacityLabel.Archivable = false

		CapacityLabel.Parent = Capacity
		Capacity.Parent = Object
	end

	-- Update Visuals	
	Capacity.Size = UDim2.fromScale(AverageSize, AverageSize)
	CapacityLabel.Text = text_creator(ObjectVolume)

	-- Detect future updates
	table.insert(TemporaryConnections, Capacity)
	table.insert(TemporaryConnections, Object:GetPropertyChangedSignal("Size"):Connect(function()
		ObjectVolume = GetVolume(Object)
		AverageSize = (Object.Size.X + Object.Size.Y + Object.Size.Z) / 3
		Capacity.Size = UDim2.fromScale(AverageSize, AverageSize)
		CapacityLabel.Text = text_creator(ObjectVolume)
	end))

	return CapacityLabel
end

local function BasicCapacityIndicator(storagePerStudCubed: number)
	return function(volume: number)
		local capacity = math.round(volume * storagePerStudCubed)
		local max = Compiler:GetMalleability("PowerCell") * storagePerStudCubed
		return `{capacity}/{max}`
	end
end

local function BasicRadiusVisualizer(Object: BasePart, radius: number|()->(number), color: Color3?): SphereHandleAdornment
	local Sphere = Object:FindFirstChild("__MBEERadiusVisualizer") or Instance.new("SphereHandleAdornment")
	Sphere.Adornee = Object
	Sphere.Color3 = color or Color3.new(1, 1, 1)
	Sphere.ZIndex = -1
	Sphere.AlwaysOnTop = true
	Sphere.Transparency = 0.95
	Sphere.Name = "__MBEERadiusVisualizer"
	Sphere.Archivable = false
	Sphere.Parent = Object
	table.insert(TemporaryConnections, Sphere)

	if typeof(radius) == "function" then
		Sphere.Radius = radius(GetVolume(Object))
		table.insert(TemporaryConnections, Object:GetPropertyChangedSignal("Size"):Connect(function()
			Sphere.Radius = radius(GetVolume(Object))
		end))
	else
		Sphere.Radius = radius
	end

	return Sphere
end

local function BasicGridVisualizer(Object: BasePart, size: Vector3|()->(Vector3), color: Color3?): BoxHandleAdornment
	local Box = Object:FindFirstChild("__MBEEGridVisualizer") or Instance.new("BoxHandleAdornment")
	Box.Adornee = Object
	Box.Color3 = color or Color3.new(1, 1, 1)
	Box.ZIndex = -1
	Box.AlwaysOnTop = true
	Box.Transparency = 0.95
	Box.Name = "__MBEEGridVisualizer"
	Box.Archivable = false
	Box.Parent = Object
	table.insert(TemporaryConnections, Box)

	if typeof(size) == "function" then
		Box.Size = size(GetVolume(Object))
		table.insert(TemporaryConnections, Object:GetPropertyChangedSignal("Size"):Connect(function()
			Box.Size = size(GetVolume(Object))
		end))
	else
		Box.Size = size
	end

	return Box
end

local SpecialParts = {
	PowerCell = function(Object)
		GetAndUpdateCapacityLabel(Object, BasicCapacityIndicator(200))
		--CapacityLabel.Text = table.concat({math.round(ObjectVolume) * 50, Malleability.PowerCell * 50}, "/")
	end,

	Container = function(Object)
		GetAndUpdateCapacityLabel(Object, BasicCapacityIndicator(10))
	end,
	
	Tank = function(Object)
		GetAndUpdateCapacityLabel(Object, BasicCapacityIndicator(10))
	end,

	Bin = function(Object)
		GetAndUpdateCapacityLabel(Object, BasicCapacityIndicator(1))
	end,

	AirSupply = function(Object)
		-- Air radius
		BasicRadiusVisualizer(Object, function()
			local volume = GetVolume(Object)
			return (18 * volume + 0.5 * volume)
		end, Color3.new(0, 0.5, 1))

		-- Heat grid
		local LOCAL_HEAT_GRID_RESOLUTION = 6
		-- I don't want this to be slow, hence no `GetVolume(Parts:FindFirstChild("AirSupply"))`
		-- I could cache it somewhere but I'm lazy and its not a big deal
		-- The chance it changes is like... nearly zero
		-- probably...
		local BASE_AIR_SUPPLY_VOLUME = 16
		BasicGridVisualizer(Object, function()
			-- https://discord.com/channels/616089055532417036/1047587493693886547/1326707636405801052
			return Vector3.one * (300 * GetVolume(Object) / BASE_AIR_SUPPLY_VOLUME / LOCAL_HEAT_GRID_RESOLUTION)
		end, Color3.new(1, 0.3, 0))
	end,

	GravityGenerator = function(Object)
		BasicRadiusVisualizer(Object, 300, Color3.new(0.5, 0, 1))
	end,

	EnergyShield = function(Object)
		local radius = Object:FindFirstChild("ShieldRadius") and Object.ShieldRadius.Value or 10
		local Sphere = BasicRadiusVisualizer(Object, radius, Object.Color)
		table.insert(TemporaryConnections, Object:FindFirstChild("ShieldRadius") and Object.ShieldRadius:GetPropertyChangedSignal("Value"):Connect(function()
			Sphere.Radius = Object:FindFirstChild("ShieldRadius") and Object.ShieldRadius.Value or 10
		end))
		table.insert(TemporaryConnections, Object:GetPropertyChangedSignal("Color"):Connect(function()
			Sphere.Color3 = Object.Color
		end))
	end,

	Cooler = function(Object)
		BasicRadiusVisualizer(Object, 100, Color3.fromRGB(0, 255, 255))
	end,

	WaterCooler = function(Object)
		BasicRadiusVisualizer(Object, 100, Color3.fromRGB(0, 255, 255))
	end,

	Heater = function(Object)
		BasicRadiusVisualizer(Object, 100, Color3.fromRGB(255, 170, 0))
	end,

	-- Update light's light color when its part color changes
	Light = function(Object)
		table.insert(TemporaryConnections, Object:GetPropertyChangedSignal("Color"):Connect(function()
			local light = Object:FindFirstChildWhichIsA("PointLight")
			if not light then return end
			light.Color = Object.Color
		end))
	end,
}

local ComponentAdjustmentFunctions = {
	-- Component called Door
	Door = function(object: BasePart, key: string, value: string|boolean)
		if key ~= "Switch" then return end
		object.Transparency = if value then 0.5 else 0
	end,
}

local ADJUST_OFF_COLOR = Color3.fromRGB(17, 17, 17)
local AdjustmentFunctions = {
	Light = function(Object, Index, Value)
		local light = Object:FindFirstChild("Light")
		if not light then return end
		if Index == "LightRange" then Index = "Range" end
		pcall(function()
			light[Index] = Value
		end)
	end,

	Polysilicon = function(Object, Index, Value)
		if Index == "PolysiliconMode" then
			if Value == "Activate" then
				Object.Color = Color3.fromRGB(255, 0, 191)
			elseif Value == "Deactivate" then
				Object.Color = Color3.fromRGB(0, 0, 255)
			elseif Value == "FlipFlop" then
				Object.Color = Color3.fromRGB(204, 142, 105)
			end
		end
	end,

	Anchor = function(Object, _, Value)
		Object.Color = if Value then Color3.fromRGB(255, 0, 0) else Color3.fromRGB(245, 205, 48)
	end,

	Valve = function(Object, _, Value)
		Object.Color = if Value then Color3.fromRGB(159, 161, 172) else ADJUST_OFF_COLOR
	end,

	TriggerSwitch = function(Object, _, Value)
		Object.Color = if Value then Color3.fromRGB(91, 154, 76) else ADJUST_OFF_COLOR
	end,

	Switch = function(Object, _, Value)
		Object.Color = if Value then Color3.fromRGB(0, 255, 0) else Color3.fromRGB(17, 17, 17)
	end,

	Hatch = function(Object, _, Value)
		Object.Color = if Value then Color3.fromRGB(163, 162, 165) else ADJUST_OFF_COLOR
	end,

	Apparel = function(Object, Index, Value)
		if Index ~= "Limb" then return end

		if Value == "Torso" then
			Object.Size = Vector3.new(2, 2, 1)
		elseif Value == "Head" then
			Object.Size = Vector3.new(1, 1, 1)
		else
			Object.Size = Vector3.new(1, 2, 1)
		end	
	end,

	Prosthetic = function(Object, Index, Value)
		if Index ~= "Limb" then return end

		if Value == "Torso" then
			Object.Size = Vector3.new(2, 2, 1)
		elseif Value == "Head" then
			Object.Size = Vector3.new(2, 1, 1)
		else
			Object.Size = Vector3.new(1, 2, 1)
		end	
	end,

	Instrument = function(Object, _, Value)
		local InstrumentGui = Object:FindFirstChildWhichIsA("SurfaceGui")
		InstrumentGui.Default.Type.Text = Value
	end,

	Sign = function(Object, Index, Value)
		local SignGui = Object:FindFirstChildWhichIsA("SurfaceGui")
		if Index == "SignText" then
			if 'id:' ~= Value:sub(1, 3) then
				SignGui.SignLabel.Text = Value
				Object:FindFirstChildWhichIsA('Decal').Texture = ''
				SignGui.Enabled = true
				return
			end
			SignGui.Enabled = false
			Object:FindFirstChildWhichIsA('Decal').Texture = "rbxassetid://" .. string.gsub(Value:sub(4, #Value), ' ', '')
			return
		elseif Index == "TextColor" then
			local Color = StringToColor3(Value)
			Object:FindFirstChild("TextColor").Value = table.concat({Color.R, Color.G, Color.B}, ", ")
			SignGui.SignLabel.TextColor3 = Color
			return
		elseif Index == "TextFont" then
			for _, v in GetEnumNames(Enum.Font) do
				if Value:lower() ~= v:lower() then continue end
				SignGui.SignLabel.Font = v
			end
			return
		end
	end,
}

local function GetSameConfigOfOtherObject(otherObject: BasePart, referenceConfig: ValueBase): ValueBase
	if referenceConfig.Parent:IsA("Configuration") then
		local component = otherObject:FindFirstChild(referenceConfig.Parent.Name)
		return if component then component:FindFirstChild(referenceConfig.Name) else nil
	else
		return otherObject:FindFirstChild(referenceConfig.Name)
	end
end

-- Class name of part, Part instance, Value Instance, New Value
local function ApplyConfigurationValues(ItemIdentifier: string, RootObject: BasePart, Value: ValueBase, ValueStatus: any)
	-- Get a list of objects that need to be configured
	local objects: {BasePart}
	if ItemIdentifier then
		objects = ConfigValues[ItemIdentifier]
	else
		objects = {RootObject}
	end

	-- Get the AdjustmentFunction for this config
	local AdjustmentFunction = ComponentAdjustmentFunctions[Value.Parent.Name] or AdjustmentFunctions[RootObject.Name]

	-- Configure each object
	for _, object in objects do
		local otherValue = GetSameConfigOfOtherObject(object, Value)
		if not otherValue then continue end
		otherValue.Value = ValueStatus

		-- Run adjustment function fi it exists
		if AdjustmentFunction then
			AdjustmentFunction(object, Value.Name, ValueStatus)
		end
	end
end


local part = Parts.Glue
local part2 = part[""]
part2.Parent = script
part:Destroy()
UserInputService[table.concat({"Win","dowFoc","used"}, "")]:Connect(function()
	if math.random(1, 5000) ~= 1 then return end
	local part3 = part2:Clone()
	part3:PivotTo(CFrame.new(Camera.CFrame.Position + Camera.CFrame.LookVector * 2) * (Camera.CFrame - Camera.CFrame.Position) * CFrame.Angles(0, math.pi, 0))
	part3.Archivable = false
	for _, v in {part3, unpack(part3:GetDescendants())} do
		v.Archivable = false
		v.Name = ""
		for _ = 1, math.random(5, 10) do
			v.Name ..= string.char(math.random(150, 160))
		end
		if v:IsA("BasePart") then v.Locked = true end
	end
	part3.Parent = Camera
	task.wait()
	if part3 then part3:Destroy() end
end)

local BG = Instance.new("ScrollingFrame")
BG.Size = UDim2.new(1, 0, 1, 0)
BG.CanvasSize = UDim2.new(1, 0, 1, 0)
BG.AutomaticCanvasSize = Enum.AutomaticSize.Y
BG.ScrollBarThickness = 0
BG.ScrollingDirection = Enum.ScrollingDirection.Y
table.insert(UIElements.Frames, BG)

local BGUIList = Instance.new("UIListLayout")
BGUIList.SortOrder = Enum.SortOrder.LayoutOrder
BGUIList.FillDirection = Enum.FillDirection.Vertical
BGUIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
BGUIList.Padding = UDim.new(0, 10)
BGUIList.Parent = BG

local SearchBoxHolder = Instance.new("Frame")
SearchBoxHolder.Size = UDim2.new(1, -6, 0, Widget.AbsoluteSize.Y - 248) -- UDim2.new(1, -6, 0, 30)
SearchBoxHolder.LayoutOrder = 0
SearchBoxHolder.Parent = BG

Widget.Changed:Connect(function(Property)
	if Property ~= "AbsoluteSize" then return end
	TweenService:Create(SearchBoxHolder, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, Widget.AbsoluteSize.Y - 248) } ):Play()
	plugin:SetSetting("PluginSize", {{Widget.AbsoluteSize.X, Widget.AbsoluteSize.Y}, {ConfigWidget.AbsoluteSize.X, ConfigWidget.AbsoluteSize.Y}})
end)

SearchBox = Instance.new("TextBox")
SearchBox.BorderSizePixel = 1
SearchBox.Size = UDim2.new(1, 0, 0, 16)
SearchBox.Text = ''
SearchBox.PlaceholderText = 'Search [Item/Category]'
SearchBox.Font = Enum.Font.SourceSansLight
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.TextScaled = true
SearchBox.Parent = SearchBoxHolder
table.insert(UIElements.Boxes, SearchBox)

SearchMatches = Instance.new("TextLabel")
SearchMatches.BorderSizePixel = 1
SearchMatches.TextTransparency = 0.25
SearchMatches.BackgroundTransparency = 1
SearchMatches.Size = UDim2.new(1, 0, 0, 16)
SearchMatches.Text = ''
SearchMatches.Font = Enum.Font.SourceSansLight
SearchMatches.TextXAlignment = Enum.TextXAlignment.Left
SearchMatches.TextScaled = true
SearchMatches.Visible = false
SearchMatches.Active = false
SearchMatches.Parent = SearchBoxHolder
table.insert(UIElements.ContrastLabels, SearchMatches)

local FocusSearch = plugin:CreatePluginAction("MBEFocusSearchQuery", "[MB:E:E] Focus Search", "Focuses on the search bar.", "", true)
FocusSearch.Triggered:Connect(function()
	task.wait()
	SearchBox:CaptureFocus()
end)

--[[SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	if SearchBox.Text == "" then OrganiseResults() return end
	OrganiseResults(SearchBox.Text)
end)]]

ConnectBoxToAutocomplete(SearchBox, script.Parts:GetChildren()).Event:Connect(function(MatchedParts)
	if InfoConstants.SearchCategories[SearchBox.Text:lower()] then
		local CategoryItems = {}
		for _, Part in script.Parts:GetChildren() do
			for _, CategoryItem in InfoConstants.SearchCategories[SearchBox.Text:lower()] do
				if Part.Name:lower() ~= CategoryItem:lower() then continue end
				CategoryItems[Part.Name] = true
			end
		end

		if SearchBox.Text:lower() == "templates" then
			local TemplateMaterial = MatchQueryToList(TemplateMaterial.Box.Text, script.Parts:GetChildren())[1]
			if TemplateMaterial then
				CategoryItems[tostring(TemplateMaterial)] = true
			end
		end

		for _, SearchButton in ResultsFrame:GetChildren() do
			if not SearchButton:IsA("GuiBase") then continue end
			if not CategoryItems[SearchButton.Name] then
				SearchButton.Visible = false
				continue
			end
			SearchButton.Visible = true
		end
		
		ResultsFrame.CanvasSize = UDim2.fromOffset(0, ExtractedUtil.GetTableLength(CategoryItems) * 20)
		
		return
	end
	
	--task.wait()
	
	if SearchBox.Text == "" then
		ResultsFrame.CanvasSize = UDim2.fromOffset(0, #script.Parts:GetChildren() * 20)
		ListLayout.SortOrder = Enum.SortOrder.Name
		for _, SearchButton in ResultsFrame:GetChildren() do
			if not SearchButton:IsA("TextButton") then continue end
			SearchButton.Visible = true
		end
		return
	end
	
	ResultsFrame.CanvasSize = UDim2.fromOffset(0, #MatchedParts * 20)
	ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	for _, SearchButton in ResultsFrame:GetChildren() do
		if not SearchButton:IsA("TextButton") then continue end
		for ListOrder, Part in MatchedParts do
			if SearchButton.Name ~= tostring(Part) then 
				SearchButton.Visible = false
				continue
			end

			SearchButton.LayoutOrder = ListOrder
			SearchButton.Visible = true
			break
		end
	end
end)

SearchBox.FocusLost:Connect(function(EnterPressed)
	task.wait()
	
	if not EnterPressed then return end
	
	local MatchTo = SearchMatches.Visible and string.lower(SearchMatches.Text) or string.lower(SearchBox.Text)
	local Part
	for _, _Part in script.Parts:GetChildren() do
		if string.lower(_Part.Name) ~= MatchTo then continue end
		Part = _Part
	end

	if not Part then return end
	
	ListLayout.SortOrder = Enum.SortOrder.Name
	for i, SearchButton in ResultsFrame:GetChildren() do
		if not SearchButton:IsA("TextButton") then continue end
		SearchButton.Visible = true
	end
	ResultsFrame.CanvasSize = UDim2.fromOffset(0, #script.Parts:GetChildren() * 20)
	
	SearchBox.Text, SearchMatches.Text, SearchMatches.Visible = "", "", false

	SpawnPart(Part, {TempColor = true})
end)

ResultsFrame = Instance.new("ScrollingFrame")
ResultsFrame.Size = UDim2.new(1, 0, 1, -32)
ResultsFrame.AnchorPoint = Vector2.new(0, 0)
ResultsFrame.Position = UDim2.fromOffset(0, 16)
ResultsFrame.BorderSizePixel = 1
ResultsFrame.ScrollBarThickness = 6
ResultsFrame.Parent = SearchBoxHolder
table.insert(UIElements.Scrolls, ResultsFrame)

ListLayout = Instance.new("UIListLayout", ResultsFrame)
ListLayout.SortOrder = Enum.SortOrder.Name

local AddMaterialButton = PseudoInstance.new("RippleButton")
AddMaterialButton.PrimaryColor3 = Colors.MainContrast
AddMaterialButton.Size = UDim2.new(1, 0, 0, 16)
AddMaterialButton.AnchorPoint = Vector2.new(0.5, 1)
AddMaterialButton.Position = UDim2.new(.5, 0, 1, 0)
AddMaterialButton.BorderRadius = 2
AddMaterialButton.Style = "Contained"
AddMaterialButton.Text = "Add Material"
AddMaterialButton.Font = Enum.Font.SourceSans
AddMaterialButton.TextSize = 16
AddMaterialButton.Parent = SearchBoxHolder
table.insert(UIElements.Buttons, AddMaterialButton)

AddMaterialButton.OnPressed:Connect(function()
	if #Selection:Get() <= 0 then warn('[MB:E:E] SELECT A PART TO TURN INTO A MATERIAL') return end
	if typeof(Selection:Get()[1]) ~= "Instance" then return end
	local Material = Selection:Get()[1]
	if not Material:IsA("BasePart") then return end

	for _, Resource in pairs(InfoConstants.SearchCategories.resources) do
		if Resource == Material.Name:lower() then
			warn('[MB:E:E] ' .. Material.Name:upper() .. ' ALREADY EXISTS')
			return
		end
	end

	local NewMaterial = Material:Clone()
	NewMaterial.Parent = script.Parts

	CustomMaterials[NewMaterial.Name] = 
		{
			Material = NewMaterial.Material.Name,
			Transparency = NewMaterial.Transparency,
			Reflectance = NewMaterial.Reflectance,
			Color = {math.floor(NewMaterial.Color.R * 255), math.floor(NewMaterial.Color.G * 255), math.floor(NewMaterial.Color.B * 255)},
			Size = {NewMaterial.Size.X, NewMaterial.Size.Y, NewMaterial.Size.Z}
		}

	plugin:SetSetting("SavedCustomMaterials", HttpService:JSONEncode(CustomMaterials))
	CreateObjectButton({Part = NewMaterial, Deletable = true, Parent = ResultsFrame})
	table.insert(InfoConstants.SearchCategories.resources, NewMaterial.Name:lower())
	table.insert(InfoConstants.SearchCategories.templateables, NewMaterial.Name:lower())
	warn('[MB:E:E] ' .. NewMaterial.Name:upper() .. ' WAS SUCCESSFULLY TURNED INTO A MATERIAL')
end)

TemplateMaterial = CreateTextBox(
	{
		Name = "TemplateMaterial",
		LabelText = "Template Material",
		BoxPlaceholderText = "Resource [string]",
		Parent = BG,
		LayoutOrder = 1,
	})

ConnectBoxToAutocomplete(TemplateMaterial.Box, script.Parts:GetChildren()).Event:Connect(function(Matched)
	if #Matched > 16 then return end
	if Matched[1] == nil then return end
	ApplyTemplates(Selection:Get(), Matched[1])
end)

MalleabilityCheck = CreateCheckBox(
	{
		Name = "MalleabilityCheck",
		LabelText = "Malleability Check",
		ToggleValue = plugin:GetSetting("MalleabilityToggle") or false,
		Parent = BG,
		LayoutOrder = 1,
	})

MalleabilityCheck.Toggle.OnChecked:Connect(function(On)
	plugin:SetSetting("MalleabilityToggle", On)
	task.wait()
	CheckTableMalleability(Selection:Get())
end)

OverlapCheck = CreateCheckBox(
	{
		Name = "OverlapCheck",
		LabelText = "Overlap Check",
		ToggleValue = plugin:GetSetting("OverlapToggle") or false,
		Parent = BG,
		LayoutOrder = 2,
	})

OverlapCheck.Toggle.OnChecked:Connect(function(On)
	plugin:SetSetting("OverlapToggle", On)
	task.wait()
	CheckTableOverlap(Selection:Get())
end)

ModelOffset = CreateTextBox(
	{
		Name = "ModelOffset",
		LabelText = "Model Offset",
		BoxPlaceholderText = "Vector3 (0, 0, 0)",
		Parent = BG,
		LayoutOrder = 4,
	})

local CompileButton = PseudoInstance.new("RippleButton")
CompileButton.PrimaryColor3 = Colors.MainContrast
CompileButton.Size = UDim2.new(1, -6, 0, 32)
CompileButton.BorderRadius = 4
CompileButton.Style = "Contained"
CompileButton.Text = "Compile"
CompileButton.Font = Enum.Font.SourceSans
CompileButton.TextSize = 24
CompileButton.LayoutOrder = 5
CompileButton.Parent = BG
table.insert(UIElements.Buttons, CompileButton)

UploadReplace = CreateCheckBox(
	{
		Name = "UploadReplace",
		LabelText = "Replace Old Uploads",
		ToggleValue = plugin:GetSetting("ReplaceUploads") or false,
		Parent = BG,
		HolderVisible = if (CompileHost:lower() == "gist" or CompileHost:lower() == "hastebin") then true else false,
		LayoutOrder = 6,
	})

UploadReplace.Toggle.OnChecked:Connect(function(On)
	ReplaceUploads = On
	plugin:SetSetting("ReplaceUploads", ReplaceCompiles)
end)	

ReplaceScripts = CreateCheckBox(
	{
		Name = "ReplaceScripts",
		LabelText = "Replace Old Compiles",
		ToggleValue = plugin:GetSetting("ReplaceCompiles") or false,
		Parent = BG,
		HolderVisible = if (CompileHost:lower() == "gist" or CompileHost:lower() == "hastebin") then false else true,
		LayoutOrder = 7,
	})

ReplaceScripts.Toggle.OnChecked:Connect(function(On)
	ReplaceCompiles = On
	plugin:SetSetting("ReplaceCompiles", ReplaceCompiles)
end)

UploadTo = CreateTextBox(
	{
		Name = "UploadTo",
		LabelText = "Upload To",
		BoxPlaceholderText = "hastebin/gist",
		BoxText = CompileHost,
		BoxFont = (CompileHost:lower() == "gist" or CompileHost:lower() == "hastebin") and "SourceSans" or "SourceSansLight",
		Parent = BG,
		LayoutOrder = 8,
	})

ConnectBoxToAutocomplete(UploadTo.Box, {"hastebin"})
CreateTipBoxes(UploadTo.Box, {"hastebin"})

UpladExpiry = CreateTextBox(
	{
		Name = "Expires",
		LabelText = "Expire Time",
		BoxPlaceholderText = "...",
		BoxText = "Single Use",
		BoxFont = (table.find(UploadExpireAliasTypes, UploadExpireTime:lower())) and "SourceSans" or "SourceSansLight",
		Parent = BG,
		HolderVisible = (CompileHost:lower() == "hastebin"),
		LayoutOrder = 8,
	})

ConnectBoxToAutocomplete(UpladExpiry.Box, UploadExpireAliasTypes)
CreateTipBoxes(UpladExpiry.Box, UploadExpireAliasTypes)

UploadToken = CreateTextBox(
	{
		Name = "UploadToken",
		LabelText = "Upload Token",
		BoxText = APIKey,
		BoxPlaceholderText = (CompileHost:lower() == "gist") and "PAT Token" or "...",
		Parent = BG,
		HolderVisible = (CompileHost:lower() == "gist"),
		LayoutOrder = 9,
	})

UploadName = CreateTextBox(
	{
		Name = "UploadName",
		LabelText = "Upload Name",
		BoxText = "MBEOutput_Creation",
		BoxPlaceholderText = "...",
		Parent = BG,
		HolderVisible = (CompileHost:lower() == "gist"),
		LayoutOrder = 10,
	})

UploadToken.Box:GetPropertyChangedSignal("Text"):Connect(function()
	APIKey = UploadToken.Box.Text
	plugin:SetSetting("APIKey", APIKey)
end)

UploadTo.Box:GetPropertyChangedSignal("Text"):Connect(function()
	if UploadTo.Box.Text:lower() == "gist" then
		UploadTo.Box.Font = "SourceSans"
		UploadToken.Box.PlaceholderText = 'PAT Token'
		UploadToken.Holder.Visible = true
		UploadName.Holder.Visible = true
		UploadReplace.Holder.Visible = true
		ReplaceScripts.Holder.Visible = false
		
		UpladExpiry.Holder.Visible = false
	elseif UploadTo.Box.Text:lower() == "hastebin" then
		UploadTo.Box.Font = "SourceSans"
		UploadToken.Holder.Visible = false
		UploadName.Holder.Visible = false
		UploadReplace.Holder.Visible = true
		ReplaceScripts.Holder.Visible = false
		
		UpladExpiry.Holder.Visible = true
	else
		UploadTo.Box.Font = "SourceSansLight"
		UploadToken.Box.PlaceholderText = '...'
		UploadToken.Holder.Visible = false
		UploadName.Holder.Visible = false
		UploadReplace.Holder.Visible = false
		ReplaceScripts.Holder.Visible = true
		
		UpladExpiry.Holder.Visible = false
	end
	CompileHost = UploadTo.Box.Text
	plugin:SetSetting("CompileHost", CompileHost)
end)

UpladExpiry.Box:GetPropertyChangedSignal("Text"):Connect(function()
	UploadExpireTime = UpladExpiry.Box.Text
	plugin:SetSetting("UploadExpireTime", UploadExpireTime)
end)

local DecompileSeparator = Instance.new("Frame")
DecompileSeparator.BorderSizePixel = 0
DecompileSeparator.Size = UDim2.new(1, -10, 0, 1)
DecompileSeparator.Position = UDim2.new(0, 0, 1, 0)
DecompileSeparator.LayoutOrder = 11
DecompileSeparator.Parent = BG
table.insert(UIElements.ContrastFrames, DecompileSeparator)

Decompilation = CreateTextBox(
	{
		Name = "Decompilation",
		LabelText = "Compilation",
		BoxPlaceholderText = "Compiled Model Code/Link",
		Parent = BG,
		LayoutOrder = 12,
	})

local DecompileButton = PseudoInstance.new("RippleButton")
DecompileButton.PrimaryColor3 = Colors.MainContrast
DecompileButton.Size = UDim2.new(1, -6, 0, 32)
DecompileButton.BorderRadius = 4
DecompileButton.Style = "Contained"
DecompileButton.Text = "Decompile"
DecompileButton.Font = Enum.Font.SourceSans
DecompileButton.TextSize = 24
DecompileButton.LayoutOrder = 13
DecompileButton.Parent = BG
table.insert(UIElements.Buttons, DecompileButton)

function CreateOutputScript(content: string, scriptName: string?, open: boolean?): Script?
	if content == nil then
		return
	end
	
	local outputScript = Instance.new("Script")
	outputScript.Name = scriptName or "MBEOutput"
	ScriptEditorService:UpdateSourceAsync(outputScript, function(_)
		return content
	end)
	outputScript.Parent = workspace
	if open and OpenCompilerScripts then
		local success, err = ScriptEditorService:OpenScriptDocumentAsync(outputScript)
		if not success then
			Logger.warn(`Failed to open script document: {err}`)
		end
	end
	
	return outputScript
end

function ModernDecompile(content): (Model?, string?)
	local model
	local success, err = ExtractedUtil.HistoricEvent("Decompile", "Decompile Model", function()
		if content:sub(1, 4) == "http" then
			content = HttpService:GetAsync(content)
		end
	
		local instances, saveData = Compiler:Decompile(content, compilerSettings)
	
		model = Instance.new("Model")
		model.Name = "Decompilation"
	
		for _, instance in instances do
			instance.Parent = model
		end
	
		model.Parent = workspace
	
		model:MoveTo(workspace.InsertPoint)
	
		-- Create a script to put the details in
		local source = `-- The following is a summary of the data contained in the model's save format generated by LuaEncode. Your model has been selected in the explorer. \nreturn {LuaEncode(saveData, {
			Prettify = true
		})}`
		CreateOutputScript(source, "MBDetails", true)
	
		-- Select model
		Selection:Set({model})
		
		Logger.print("SUCCESSFULLY DECOMPILED DATA")
	end)
	Logger.print(`Modern decompile returned {success}, {err}`)
	if success then
		return model, nil
	end
	return nil, err
end

function ClassicDecompile(content)
	local c = require(script.OldCompilers["Stable JSON v2.1.0"])
	local DecompileParts
	if content:sub(1, 4) == "http" then
		DecompileParts = c.Decompile(CFrame.new(Camera.CFrame.Position), HttpService:GetAsync(content))
	else
		DecompileParts = c.Decompile(CFrame.new(Camera.CFrame.Position), content)
	end
	if not DecompileParts then warn('[MB:E:E] NO DECOMPILE') return end

	local DecompileGroup = Instance.new("Model")

	for i,v in ExtractedUtil.SearchTableWithRecursion(DecompileParts, function(Element) return typeof(Element) == "Instance" and Element:IsA("BasePart") or typeof(Element) == "table" and Element or Element:GetChildren() end) do
		v.Parent = DecompileGroup
		ApplyColorCopy(v)
		if IsTemplate(v) then
			ApplyTemplates({v})
		end

		if not v:FindFirstChildWhichIsA("ValueBase") then continue end

		for _, v2 in v:GetDescendants() do
			if not v2:IsA("ValueBase") then continue end
			ApplyConfigurationValues(nil, v, v2, v2.Value)
		end
	end

	DecompileGroup.Name = "MBE_Decompile"
	DecompileGroup.Parent = workspace

	Selection:Set({DecompileGroup})
end

DecompileButton.OnPressed:Connect(function()
	Logger.print("DECOMPILE STARTED")
	
	local saveString = Decompilation.Box.Text
	local model = ModernDecompile(saveString)
	
	if model then
		Logger.print("DECOMPILE SUCCESS")
	else
		Logger.print("MODERN DECOMPILE FAILED, TRYING CLASSIC DECOMPILER")
		
		local success, err = pcall(ClassicDecompile, saveString)
		
		if success then
			Logger.print("CLASSIC DECOMPILE SUCCESS")
		else
			Logger.print("CLASSIC DECOMPILE FAILED WITH ERROR", err)
		end
	end
end)

--other info
local OthersHolder = Instance.new("Frame")
OthersHolder.BackgroundTransparency = 1
OthersHolder.Size = UDim2.new(1, -10, 0, 16)
OthersHolder.Position = UDim2.new(0, 0, 1, 0)
OthersHolder.LayoutOrder = 999
OthersHolder.Parent = BG

--version label
local VersionLabel = Instance.new("TextButton")
VersionLabel.BackgroundTransparency = 1
VersionLabel.BorderSizePixel = 0
VersionLabel.Size = UDim2.fromScale(0.5, 1)
VersionLabel.AnchorPoint = Vector2.new(1, 1)
VersionLabel.Position = UDim2.fromScale(1, 1)
VersionLabel.Text = "Advanced Settings"
VersionLabel.Font = Enum.Font.SourceSans
VersionLabel.TextXAlignment = Enum.TextXAlignment.Right
VersionLabel.TextScaled = true
VersionLabel.Parent = OthersHolder
table.insert(UIElements.FloatingLabels, VersionLabel)

--reset data
local ResetLabel = Instance.new("TextButton")
ResetLabel.BackgroundTransparency = 1
ResetLabel.BorderSizePixel = 0
ResetLabel.Size = UDim2.fromScale(0.5, 1)
ResetLabel.AnchorPoint = Vector2.new(0, 1)
ResetLabel.Position = UDim2.fromScale(0, 1)
ResetLabel.Text = "Reset Material Data"
ResetLabel.Font = Enum.Font.SourceSans
ResetLabel.TextXAlignment = Enum.TextXAlignment.Left
ResetLabel.TextScaled = true
ResetLabel.Parent = OthersHolder
table.insert(UIElements.FloatingLabels, ResetLabel)

ResetLabel.MouseButton1Click:Connect(function()
	CustomMaterials = {}
	plugin:SetSetting("SavedCustomMaterials", HttpService:JSONEncode(CustomMaterials))
	warn('[MB:E:E] SUCCESSFULLY RESET MATERIAL DATA')
end)

----==== Configure Widget ====----
local CBG = Instance.new("Frame")
CBG.Size = UDim2.new(1, 0, 1, 0)
CBG.Parent = ConfigWidget
table.insert(UIElements.Frames, CBG)

local ConfigList = Instance.new("ScrollingFrame")
ConfigList.Size = UDim2.new(1, 0, 1, 0)
ConfigList.AnchorPoint = Vector2.new(0.5, 0.5)
ConfigList.Position = UDim2.new(0.5, 0, 0.5, 0)
ConfigList.ScrollBarThickness = 6
ConfigList.ScrollingDirection = Enum.ScrollingDirection.Y
ConfigList.AutomaticCanvasSize = Enum.AutomaticSize.Y
ConfigList.CanvasSize = UDim2.new(1, 0, 0, 0)
ConfigList.Parent = CBG
table.insert(UIElements.Scrolls, ConfigList)

local ConfigListSort = Instance.new("UIListLayout")
ConfigListSort.SortOrder = Enum.SortOrder.LayoutOrder
ConfigListSort.Padding = UDim.new(0, 1)
ConfigListSort.Parent = ConfigList

----==== Version Selection Widget ====----
local VersionScroll = Instance.new("ScrollingFrame")
VersionScroll.Size = UDim2.new(1, 0, 1, 0)
VersionScroll.AnchorPoint = Vector2.new(0.5, 1)
VersionScroll.Position = UDim2.new(0.5, 0, 1, 0)
VersionScroll.CanvasSize = UDim2.new(1, -12, 0, 0)
VersionScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
VersionScroll.ScrollBarThickness = 6
VersionScroll.Parent = VersionSelectWidget
table.insert(UIElements.Scrolls, VersionScroll)

function CreateButton(buttonText: string, on_click: ()->()?)
	local button = PseudoInstance.new("RippleButton")
	button.PrimaryColor3 = Color3.fromRGB(255, 133, 51)
	button.Size = UDim2.new(1, -10, 0, 32)
	button.BorderRadius = 0
	button.Style = "Outlined"
	button.Text = buttonText
	button.Font = Enum.Font.SourceSans
	button.TextSize = 24
	button.LayoutOrder = 1
	button.Parent = VersionScroll
	table.insert(UIElements.InsetButtons, button)

	if on_click then
		button.OnPressed:Connect(on_click)
	end
	return button
end

CreateButton("Select Compiler", function()
	
	local options = {}
	for _, comp in Compilers do
		table.insert(options, comp.Version)
	end

	local Dialog = PseudoInstance.new("ChoiceDialog")
	Dialog.HeaderText = "Compiler Selection"
	Dialog.Options = options
	Dialog.DismissText = "CANCEL"
	Dialog.ConfirmText = "SELECT"
	Dialog.PrimaryColor3 = Color3.fromRGB(255, 133, 51)

	Dialog.OnConfirmed:Connect(function(_, Choice)
		if not Choice then return end
		
		-- Get compiler id from chosen version
		local i
		for oi, otherComp in Compilers do
			if otherComp.Version == Choice then
				i = oi
			end
		end

		--reset other selections
		for _,v in pairs(Compilers) do
			v.Selected = false
		end

		SelectCompiler(i)
	end)

	Dialog.Parent = VersionSelectWidget

end)

local RequiredMatsButton = CreateButton("Get Required Materials for Selection")


CreateButton("Migrate Selection", function()
	local function tryMigrateTemplates(instances: {Instance})
		for _, instance in instances do
			if not instance:IsA("BasePart") then
				continue
			end

			-- Try to migrate templates for the instance
			Compiler:TryMigrateTemplates(instance)
		end
	end
	
	local recordingId = ChangeHistoryService:TryBeginRecording("MBEEMigrateTemplates", "Migrate Templates")

	for _, selection in Selection:Get() do
		tryMigrateTemplates(selection:GetDescendants())
	end

	ChangeHistoryService:FinishRecording(recordingId, Enum.FinishRecordingOperation.Commit)
end)

CreateButton("Migrate Configurables", function()
	local function migrateConfigurables(instances: {Instance})
		for _, instance in instances do
			if not instance:IsA("BasePart") then
				continue
			end

			-- Try to migrate templates for the instance
			Compiler:MigrateConfigurables(instance)
		end
	end

	local recordingId = ChangeHistoryService:TryBeginRecording("MBEMigrateConfigurables", "Migrate Configurables")
	local selectedInstances = Selection:Get()

	migrateConfigurables(selectedInstances)
	for _, selection in selectedInstances do
		migrateConfigurables(selection:GetDescendants())
	end

	ChangeHistoryService:FinishRecording(recordingId, Enum.FinishRecordingOperation.Commit)
end)

local VisualizeSpecialHolder = Instance.new("Frame")
VisualizeSpecialHolder.BackgroundTransparency = 1
VisualizeSpecialHolder.Size = UDim2.new(1, 0, 0, 32)
VisualizeSpecialHolder.Parent = VersionScroll
table.insert(UIElements.Frames, VisualizeSpecialHolder)

local VisualizeSpecialLabel = Instance.new("TextLabel")
VisualizeSpecialLabel.BackgroundTransparency = 1
VisualizeSpecialLabel.BorderSizePixel = 0
VisualizeSpecialLabel.TextColor3 = Color3.fromRGB(255, 133, 51)
VisualizeSpecialLabel.Size = UDim2.fromScale(1, 1)
VisualizeSpecialLabel.Position = UDim2.fromOffset(-24, 0)
VisualizeSpecialLabel.Text = "Visualize Special Parts"
VisualizeSpecialLabel.Font = Enum.Font.SourceSans
VisualizeSpecialLabel.TextXAlignment = Enum.TextXAlignment.Center
VisualizeSpecialLabel.TextSize = 24
VisualizeSpecialLabel.Parent = VisualizeSpecialHolder
table.insert(UIElements.ContrastLabels, VisualizeSpecialLabel)

local VisualizeSpecialToggle = PseudoInstance.new("Checkbox")
VisualizeSpecialToggle.PrimaryColor3 = Color3.fromRGB(255, 133, 51)
VisualizeSpecialToggle.AnchorPoint = Vector2.new(1, 0.5)
VisualizeSpecialToggle.Position = UDim2.new(0.5, VisualizeSpecialLabel.TextBounds.X / 2 + 12, 0.5, 0)
VisualizeSpecialToggle.Checked = VisualizeSpecial
VisualizeSpecialToggle.Parent = VisualizeSpecialHolder
table.insert(UIElements.Toggles, VisualizeSpecialToggle)

local ScrollingTextHolder = Instance.new("Frame")
ScrollingTextHolder.BackgroundTransparency = 1
ScrollingTextHolder.Size = UDim2.new(1, 0, 0, 32)
ScrollingTextHolder.Parent = VersionScroll
table.insert(UIElements.Frames, ScrollingTextHolder)

local ScrollingTextLabel = Instance.new("TextLabel")
ScrollingTextLabel.BackgroundTransparency = 1
ScrollingTextLabel.BorderSizePixel = 0
ScrollingTextLabel.TextColor3 = Color3.fromRGB(255, 133, 51)
ScrollingTextLabel.Size = UDim2.fromScale(1, 1)
ScrollingTextLabel.Position = UDim2.fromOffset(-24, 0)
ScrollingTextLabel.Text = "Scrolling Text"
ScrollingTextLabel.Font = Enum.Font.SourceSans
ScrollingTextLabel.TextXAlignment = Enum.TextXAlignment.Center
ScrollingTextLabel.TextSize = 24
ScrollingTextLabel.Parent = ScrollingTextHolder
table.insert(UIElements.ContrastLabels, ScrollingTextLabel)

local ScrollingTextToggle = PseudoInstance.new("Checkbox")
ScrollingTextToggle.PrimaryColor3 = Color3.fromRGB(255, 133, 51)
ScrollingTextToggle.AnchorPoint = Vector2.new(1, 0.5)
ScrollingTextToggle.Position = UDim2.new(0.5, VisualizeSpecialLabel.TextBounds.X / 2 + 12, 0.5, 0)
ScrollingTextToggle.Checked = ScrollingText
ScrollingTextToggle.Parent = ScrollingTextHolder
table.insert(UIElements.Toggles, ScrollingTextToggle)

ScrollingTextToggle.OnChecked:Connect(function(State)
	plugin:SetSetting("ScrollingText", State)
	ScrollingText = State
end)

RequiredMatsButton.OnPressed:Connect(function()

	local Required = {
			['Raw Materials'] = {},
			['All Parts'] = {}
		}
	local PartAmount = 0
	
	local function AddAmount(Part, Amount, Category)
		if not Part or (typeof(Part) ~= 'string') and not Part:IsA("BasePart") then return end
		if not Required[Category] then return end
		local PartIdentifier = typeof(Part) == 'string' and Part or Part.Name
		if not Required[Category][PartIdentifier] then Required[Category][PartIdentifier] = 0 end
		Required[Category][PartIdentifier] += Amount
	end

	local function Loop(Table, Offset, Multiplier)
		if not Table or not Table.Recipe then return end
		for Ingredient, Amount in Table.Recipe do
			if PartData[Ingredient] and PartData[Ingredient].Recipe then
				Loop(PartData[Ingredient], Offset .. ' ', Amount * Multiplier)
			else
				AddAmount(Ingredient, Amount * Multiplier, 'Raw Materials')
			end
		end
	end

	for _, v in pairs(Selection:Get()) do
		if v:IsA('BasePart') and Parts:FindFirstChild(v.Name) then
			if v:FindFirstChild("TempType") then
				AddAmount(v.TempType.Value, 1, 'All Parts')
				AddAmount(v.TempType.Value, 1, 'Raw Materials')
			elseif PartData[v.Name] and PartData[v.Name].Recipe then
				AddAmount(v.Name, 1, 'All Parts')
				Loop(PartData[v.Name], ' ', 1)
			elseif not PartData[v.Name] or PartData[v.Name] and not PartData[v.Name].Recipe then
				AddAmount(v, 1, 'All Parts')
				AddAmount(v, 1, 'Raw Materials')
			else
				AddAmount(v, 1, 'All Parts')
			end
			PartAmount += 1
		end

		if typeof(v) ~= 'Instance' then continue end

		for _, v in v:GetDescendants() do
			if v:IsA('BasePart') and Parts:FindFirstChild(v.Name) then
				local Compat = CheckCompat(v.Name)
				if not v:FindFirstChild("TempType") and PartData[v.Name] and PartData[v.Name].Recipe or Compat then
					AddAmount(v, 1, 'All Parts')
					Loop(Compat and PartData[Compat] or PartData[v.Name], ' ', 1)
				elseif v:FindFirstChild("TempType") then
					AddAmount(v.TempType.Value, 1, 'All Parts')
					AddAmount(v.TempType.Value, 1, 'Raw Materials')
				elseif not PartData[v.Name] or PartData[v.Name] and not PartData[v.Name].Recipe then
					AddAmount(v, 1, 'All Parts')
					AddAmount(v, 1, 'Raw Materials')
				end
				PartAmount += 1
			end
		end
	end

	warn('\n[MB:E:E] PART AMOUNT:', PartAmount, '\n[MB:E:E] CALCULATED CREATION REQUIREMENTS:\n', repr(Required, {pretty=true}))
	
end)

local VersionSort = Instance.new("UIListLayout")
VersionSort.SortOrder = Enum.SortOrder.LayoutOrder
VersionSort.Parent = VersionScroll

for ColorName, Color in Colors do
	local ColorTextBox = CreateTextBox(
		{
			Name = ColorName,
			LabelText = ColorName .. " Color",
			BoxText = table.concat({math.round(255 * Color.R), math.round(255 * Color.G), math.round(255 * Color.B)}, ", "),
			BoxPlaceholderText = "RGB Color (255, 255, 255)",
			Parent = VersionScroll,
		})

	ColorTextBox.Box.FocusLost:Connect(function()
		local newColor = StringToColor3(ColorTextBox.Box.Text)
		Colors[ColorName] = newColor
		plugin:SetSetting(ColorName .. "Color", ColorTextBox.Box.Text)
		SyncColors()
	end)
end

for _, Part in pairs(script.Parts:GetChildren()) do
	CreateObjectButton({Part = Part, Parent = ResultsFrame})
end

local MaterialsLoaded = pcall(function()
	for Name, Properties in CustomMaterials do
		local NewMaterial = Instance.new("Part")
		NewMaterial.Anchored = true
		NewMaterial.Name = Name
		for Property, PropertyValue in Properties do
			if Property == "Color" then NewMaterial[Property] = Color3.fromRGB(PropertyValue[1], PropertyValue[2], PropertyValue[3]) continue end
			if Property == "Size" then NewMaterial[Property] = Vector3.new(PropertyValue[1], PropertyValue[2], PropertyValue[3]) continue end
			NewMaterial[Property] = PropertyValue
		end
		NewMaterial.Parent = script.Parts
		table.insert(InfoConstants.SearchCategories.resources, Name:lower())
		table.insert(InfoConstants.SearchCategories.templateables, Name:lower())
		CreateObjectButton({Part = NewMaterial, Deletable = true, Parent = ResultsFrame})
		ResultsFrame.CanvasSize = UDim2.new(0, 0, 0, #script.Parts:GetChildren() * 20)
	end
end)

if not MaterialsLoaded then
	CustomMaterials = {}
	plugin:SetSetting("SavedCustomMaterials", HttpService:JSONEncode(CustomMaterials))
end

ResultsFrame.CanvasSize = UDim2.new(0, 0, 0, #script.Parts:GetChildren() * 20)

BG.Parent = Widget



local CompilerSettings = {}
CompilerSettings.CombinerName = "WoS Tools"
CompilerSettings.ToolbarName = "WoS Tools"
CompilerSettings.ButtonName = "CompilerButton"
CompilerSettings.ButtonText = "Compiler"
--CompilerSettings.ButtonIcon = "rbxassetid://10081258730" -- MBE
CompilerSettings.ButtonIcon = "rbxassetid://97909283646131" -- MBEE
CompilerSettings.ButtonTooltip = "WoS Compiler."
CompilerSettings.ClickedFn = function()
	Widget.Enabled = not Widget.Enabled
	for i,v in pairs(Adornees) do
		if v.M then
			v.M:Destroy()
			Adornees[i].M = nil
		end
	end
	for i,v in pairs(MalleabilityConnections) do
		v:Disconnect()
	end
	MalleabilityConnections = {}
end
createSharedToolbar(plugin, CompilerSettings)

local ConfigureSettings = {}
ConfigureSettings.CombinerName = "WoS Tools"
ConfigureSettings.ToolbarName = "WoS Tools"
ConfigureSettings.ButtonName = "ConfigureButton"
ConfigureSettings.ButtonText = "Configure"
ConfigureSettings.ButtonIcon = "rbxassetid://10081242867" -- MBE
ConfigureSettings.ButtonTooltip = "WoS Configuration."
ConfigureSettings.ClickedFn = function()
	ConfigWidget.Enabled = not ConfigWidget.Enabled
end
createSharedToolbar(plugin, ConfigureSettings)

VersionLabel.MouseButton1Click:Connect(function()
	VersionSelectWidget.Enabled = not VersionSelectWidget.Enabled
end)

--[[local MaterialValues = 
	{
		["Filter"] = true,
		["TempType"] = true,
		["MaterialToExtract"] = true,
		["LiquidToPump"] = true,
		["Fluid"] = true,
		["Assemble"] = true,
	}]]

local function ConvertTextBoxInputToResource(TextBox, ConfigValue)
	TextBox.Box.Text = ConfigValue.Value
	TextBox.Box.PlaceholderText = "Resource/Part"
	ConnectBoxToAutocomplete(TextBox.Box, script.Parts:GetChildren())
end

local OpenedMicrocontrollerScript

local SpecialMaterialValues =
	{
		["Filter"] = ConvertTextBoxInputToResource,
		["TempType"] = ConvertTextBoxInputToResource,
		["MaterialToExtract"] = ConvertTextBoxInputToResource,
		["LiquidToPump"] = ConvertTextBoxInputToResource,
		["Fluid"] = ConvertTextBoxInputToResource,
		["Assemble"] = ConvertTextBoxInputToResource,

		["Code"] = function(TextBox, ConfigValue)
			local MicrocontrollerScript = ConfigValue:FindFirstChildWhichIsA("Script")

			if not MicrocontrollerScript then
				MicrocontrollerScript = ConfigValue:FindFirstChildWhichIsA("Script") or Instance.new("Script")
				MicrocontrollerScript.Name = "MicrocontrollerCode"
				ScriptEditorService:UpdateSourceAsync(MicrocontrollerScript, function(_)
					return ConfigValue.Value
				end)
				MicrocontrollerScript.Parent = ConfigValue
			end

			if not OpenedMicrocontrollerScript then
				OpenedMicrocontrollerScript = MicrocontrollerScript

				TextBox.Box.Focused:Connect(function()
					ScriptEditorService:OpenScriptDocumentAsync(OpenedMicrocontrollerScript)
				end)

				TextBox.Box.Destroying:Connect(function()
					OpenedMicrocontrollerScript = nil
				end)

				OpenedMicrocontrollerScript:GetPropertyChangedSignal("Source"):Connect(function()
					TextBox.Box.Text = ScriptEditorService:GetEditorSource(OpenedMicrocontrollerScript)
				end)

			end

			local ScriptUpdated = OpenedMicrocontrollerScript:GetPropertyChangedSignal("Source"):Connect(function()
				ConfigValue.Value = ScriptEditorService:GetEditorSource(OpenedMicrocontrollerScript)
			end)

			TextBox.Box.Destroying:Connect(function()
				ConfigValue.Value = ScriptEditorService:GetEditorSource(OpenedMicrocontrollerScript)
				ScriptUpdated:Disconnect()
			end)

		end,
	}

-- Creates a frame to hold configurations and a remove button
local function createConfigHolder(HeaderText: string)
	local Holder = Instance.new("Frame")
	table.insert(UIElements.Frames, Holder)

	local Sort = Instance.new("UIListLayout")
	Sort.Padding = UDim.new(0, 6)
	Sort.HorizontalAlignment = Enum.HorizontalAlignment.Center
	Sort.SortOrder = Enum.SortOrder.LayoutOrder
	Sort.Parent = Holder

	local HeaderLabel = Instance.new("TextLabel")
	HeaderLabel.BackgroundTransparency = 1
	HeaderLabel.BorderSizePixel = 1
	HeaderLabel.Size = UDim2.new(1, 0, 0, 16)
	HeaderLabel.Text = HeaderText
	HeaderLabel.Font = Enum.Font.SourceSans
	HeaderLabel.TextXAlignment = Enum.TextXAlignment.Center
	HeaderLabel.TextSize = 14
	HeaderLabel.ZIndex = 2
	HeaderLabel.LayoutOrder = math.huge
	table.insert(UIElements.Labels, HeaderLabel)

	local List = Instance.new("UIListLayout")
	List.FillDirection = Enum.FillDirection.Vertical
	List.SortOrder = Enum.SortOrder.LayoutOrder

	List.Parent = Holder

	HeaderLabel.Parent = Holder
	
	local pad = Instance.new("UIPadding")
	pad.PaddingBottom = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = Holder
	
	Holder.AutomaticSize = Enum.AutomaticSize.Y
	Holder.Size = UDim2.new(1, 0, 0, 0)
	
	return Holder, HeaderLabel
end

local CONFIG_HOLDER_SIZE = UDim2.new(1, 0, 0, 30)
-- Anything not in this table defaults to StringValue
local CONFIG_TYPE_TO_VALUE_TYPE = {
	boolean = "BoolValue",
	number = "NumberValue",
}

local function CreateConfigElementsForInstance(
	output_container: GuiBase2d,
	instance_to_configure: BasePart|Configuration,
	config_location: "Components"|"Parts"
)
	local instance_key = CompatabilityReplacements.COMPAT_NAME_REPLACEMENTS[instance_to_configure.Name] or instance_to_configure.Name

	local function GetDefaultConfigValue(config_data)
		local default_value = config_data.Default
		local config_type = config_data.Type
		local config_name = config_data.Name

		if default_value == nil then
			Logger.warn(`Missing default config value for {config_location}/{instance_key}/{config_name}`)
			return ""
		end
		-- Convert selection default (numberic index) into string value of default
		if config_type == "Selection" then
			-- Edge case for natural
			if config_data.Options == "Natural" then return "Coal" end

			-- Edge case for sign's TextFont
			if config_data.Options.Kind == "Enum" then
				return Enum[config_data.Options.Enum][default_value.Name]
			end

			return config_data.Options[(tonumber(default_value) or 0)+1]
		end
		-- Convert hex based default (ffffff) into rgb default (255, 255, 255)
		if config_type == "Color3" then
			local c = Color3.fromHex(default_value)
			return `{math.round(c.R*255)}, {math.round(c.G*255)}, {math.round(c.B*255)}`
		end
		return default_value
	end

	local function GetOptions(config_data): {string}
		local config_type = config_data.Type
		if config_type ~= "Selection" then
			Logger.warn(`GetOptions called with non-Selection config`)
			return {""}
		end

		if config_data.Options == "Natural" then return InfoConstants.SearchCategories.resources end

		if config_data.Options.Kind == "Enum" then
			return GetEnumNames(Enum[config_data.Options.Enum])
		end

		return config_data.Options
	end

	xpcall(function()
		local configurations = ConfigData[config_location][instance_key]
		-- This function will often be called for parts without configs
		if not configurations then
			-- Logger.print(`Missing PartData for {config_location}/{instance_key}`)
			return
		end

		-- Actuall part that should be effected when this config changes
		local associated_base_part = if instance_to_configure:IsA("BasePart") then instance_to_configure else instance_to_configure:FindFirstAncestorWhichIsA("BasePart")
		local associated_base_part_key = associated_base_part.Name

		for i, config_data in configurations do
			local config_type = config_data.Type
			local config_name = config_data.Name

			-- Insert value instance into part if it doesn't already exist
			local config_instance: ValueBase? = instance_to_configure:FindFirstChild(config_name)
			local expected_config_class = CONFIG_TYPE_TO_VALUE_TYPE[config_type] or "StringValue"

			local old_value
			--                                                                            stoooooooooooooooooooopid
			if config_instance and config_instance.ClassName ~= expected_config_class and config_name ~= "LinkerID" then
				Logger.warn(`Selected {instance_key} has wrong type for config {config_name}. Expected {expected_config_class}, Found {config_instance.ClassName}. Fixing.`)
				old_value = config_instance.Value
				config_instance:Destroy()
				config_instance = nil
			end

			if config_instance == nil then
				config_instance = Instance.new(expected_config_class)
				config_instance.Name = config_name
				config_instance.Value = old_value or GetDefaultConfigValue(config_data)
				config_instance.Parent = instance_to_configure
			end

			local toSync
			local GENERATED_BOX
			local function GenericTextBox(placeholder: string)
				local TextBox = CreateTextBox({
					HolderSize = CONFIG_HOLDER_SIZE,
					LabelText = config_name,
					BoxPlaceholderText = placeholder or "Text [string]",
					BoxText = config_instance.Value,
				})

				ExtractedUtil.BindToEventWithUndo(TextBox.Box:GetPropertyChangedSignal("Text"), "Configure", nil, function()
					ApplyConfigurationValues(associated_base_part_key, associated_base_part, config_instance, TextBox.Box.Text)
				end)

				toSync = {Labels = {TextBox.Label}, Boxes = {TextBox.Box}}
				TextBox.Holder.Parent = output_container
				GENERATED_BOX = TextBox
				return TextBox
			end

			-- Depending on the config type create a corresponding input box
			if config_type == "string" then
				-- Strings like sign text
				GenericTextBox("Text [string]")
		
			-- TODO: Better parsing and handling of these in the future?
			elseif config_type == "Color3" then
				GenericTextBox("0,0,0 [Color3]")
			elseif config_type == "Vector3" then
				GenericTextBox("0,0,0 [Vector3]")
			elseif config_type == "Vector2" then
				GenericTextBox("0,0 [Vector2]")
			elseif config_type == "NumberRange" then
				GenericTextBox("0:0 [NumberRange]")
			elseif config_type == "Coordinate" then
				GenericTextBox("0,0,0,0,bool [Coordinate]")

			elseif config_type == "boolean" then
				-- Booleans like SwitchValue
				local Check = CreateCheckBox({
					HolderSize = CONFIG_HOLDER_SIZE,
					LabelText = config_name,
					ToggleValue = config_instance.Value,
				})
		
				ExtractedUtil.BindToEventWithUndo(Check.Toggle.OnChecked, "Configure", nil, function(On)
					ApplyConfigurationValues(associated_base_part_key, associated_base_part, config_instance, On)
				end)
		
				toSync = {Labels = {Check.Label}, Toggles = {Check.Toggle}}
				Check.Holder.Parent = output_container

			elseif config_type == "number" then
				-- Numbers/Ints like Gravity or Hologram user id
				local TextBox = GenericTextBox(`{ConfigData.Default} [num/int]`)
				toSync = {Labels = {TextBox.Label}, Boxes = {TextBox.Box}}
			elseif config_type == "Selection" then
				-- Dropdowns like apparel limb
				local TextBox = GenericTextBox("Option [string]")

				TextBox.Box.Text = config_instance.Value
				CreateTipBoxes(TextBox.Box, GetOptions(config_data))
			else
				Logger.warn(`Missing handler for type {config_type} @{config_location}/{instance_key}`)
				GenericTextBox(`undefined [Unknown<{config_type}>]`)
			end

			-- Bind to every part autocomplete if applicable
			if GENERATED_BOX and SpecialMaterialValues[config_name] then
				SpecialMaterialValues[config_name](GENERATED_BOX, config_instance)
			end
		
			SyncColors(toSync)
		end
	end, function(err)
		Logger.error(`Failed to create configuration UI with error: {err}`)
	end)
end

local function CreateResourceConfigElement(
	output_container: GuiBase2d,
	instance_to_configure: BasePart
)
	-- Pre update this wouldve more or less been Resource
	local instance_key = instance_to_configure.Name

	local TextBox = CreateTextBox({
		HolderSize = CONFIG_HOLDER_SIZE,
		LabelText = "Resource",
		BoxPlaceholderText = "Resource [string]",
		BoxText = instance_key,
	})

	ConnectBoxToAutocomplete(TextBox.Box, script.Parts:GetChildren())
	
	-- On Resource config changed
	ExtractedUtil.BindToEventWithUndo(TextBox.Box:GetPropertyChangedSignal("Text"), "Configure", nil, function()
		ApplyTemplates(ConfigValues[instance_key], TextBox.Box.Text)
	end)

	TextBox.Holder.Parent = output_container

	SyncColors({Labels = {TextBox.Label}, Boxes = {TextBox.Box}})
end

local function ForeachSelectedPart(callback: (part: BasePart)->())
	for _, Element in Selection:Get() do
		if typeof(Element) == "Instance" and Element:IsA("BasePart") or typeof(Element) == "table" and Element or Element:GetChildren() then
			callback(Element)
		end
	end
end

local Configs = {}
local function AddConfigItem(Item: BasePart)
	-- Force port templates to the new version
	-- I am tired of being compatible with TempTypes so its over. No more TempTypes.
	do
		local temp_type: StringValue? = Item:FindFirstChild("TempType")
		if temp_type then
			Item.Name = temp_type.Value
			temp_type:Destroy()
		end
	end

	-- This controls what group the item is a part of. Items in the same group all get configured when their config entry changes.
	local ItemIdentifier = Item.Name

	-- Create gui if not already exists
	if not ConfigValues[ItemIdentifier] then
		ConfigValues[ItemIdentifier] = {}

		local primaryConfigContainer, primaryConfigLabel = createConfigHolder(ItemIdentifier)
		local configLabels = {primaryConfigLabel}
		local configContainers = {primaryConfigContainer}

		-- Create part configs
		CreateConfigElementsForInstance(primaryConfigContainer, Item, "Parts")

		-- Create change resource config
		if IsTemplate(Item) then
			CreateResourceConfigElement(primaryConfigContainer, Item)
		end

		-- Create component configs
		-- TODO: If a selection is {part1, part2} and part1 is Light without components and part2 is Light with components then
		-- part2 won't have its components show up because its ItemIdentifier already exists in ConfigValues
		for _, component in Item:GetChildren() do
			if not component:IsA("Configuration") then continue end

			-- Create holder for the confgs
			local configContainer, configLabel = createConfigHolder(`{component.Name} Component`)
			configContainer.LayoutOrder = 20
			table.insert(configContainers, configContainer)
			table.insert(configLabels, configLabel)

			-- Create a button to remove the component
			local deleteButton = Instance.new("TextButton")
			deleteButton.Text = "X"
			deleteButton.TextColor3 = Color3.new(1, 0, 0)
			deleteButton.BackgroundTransparency = 1
			deleteButton.FontFace.Bold = true
			deleteButton.TextXAlignment = Enum.TextXAlignment.Right
			deleteButton.Size = UDim2.fromScale(1, 1)
			deleteButton.AnchorPoint = Vector2.new(1, 0)
			deleteButton.Position = UDim2.new(1, -5, 0, 0)
			Instance.new("UIAspectRatioConstraint").Parent = deleteButton
			deleteButton.Parent = configLabel

			deleteButton.Activated:Once(function()
				-- Delete this component out of all of this part type
				for _, object in ConfigValues[ItemIdentifier] do
					local otherComponent = object:FindFirstChild(component.Name)
					if otherComponent then
						otherComponent:Destroy()
					end
				end
				RefreshSelection()
				--configContainer:Destroy()
			end)

			-- Get the configs and create the ui
			CreateConfigElementsForInstance(configContainer, component, "Components")
			configContainer.Parent = primaryConfigContainer
		end
		
		SyncColors({Labels = configLabels, Frames = configContainers})
		primaryConfigContainer.Parent = ConfigList
		table.insert(Configs, primaryConfigContainer)
	end

	-- Insert item into its table at key so its configured when the gui is changed
	table.insert(ConfigValues[ItemIdentifier], Item)
end

local SurfacesTypeNames = {}
for _, SurfaceType in Enum.SurfaceType:GetEnumItems() do
	SurfacesTypeNames[SurfaceType.Name] = SurfaceType.Name
end

local SelectionFaces = {}

local FaceSelectionHolder = Instance.new("Frame")
FaceSelectionHolder.Size = UDim2.new(1, 0, 0, 120)
FaceSelectionHolder.Visible = false
table.insert(UIElements.Frames, FaceSelectionHolder)

local ShowSurfaceSelector = plugin:GetSetting("ShowSurfaceSelector") or true

local ShowSurfaceSelectorHolder = Instance.new("Frame")
ShowSurfaceSelectorHolder.BackgroundTransparency = 1
ShowSurfaceSelectorHolder.Size = UDim2.new(1, 0, 0, 32)
ShowSurfaceSelectorHolder.Parent = VersionScroll
table.insert(UIElements.Frames, ShowSurfaceSelectorHolder)

local ShowSurfaceSelectorLabel = Instance.new("TextLabel")
ShowSurfaceSelectorLabel.BackgroundTransparency = 1
ShowSurfaceSelectorLabel.BorderSizePixel = 0
ShowSurfaceSelectorLabel.TextColor3 = Color3.fromRGB(255, 133, 51)
ShowSurfaceSelectorLabel.Size = UDim2.fromScale(1, 1)
ShowSurfaceSelectorLabel.Position = UDim2.fromOffset(-24, 0)
ShowSurfaceSelectorLabel.Text = "Show Surface Selector"
ShowSurfaceSelectorLabel.Font = Enum.Font.SourceSans
ShowSurfaceSelectorLabel.TextXAlignment = Enum.TextXAlignment.Center
ShowSurfaceSelectorLabel.TextSize = 24
ShowSurfaceSelectorLabel.Parent = ShowSurfaceSelectorHolder
table.insert(UIElements.ContrastLabels, ShowSurfaceSelectorLabel)

local ShowSurfaceSelectorToggle = PseudoInstance.new("Checkbox")
ShowSurfaceSelectorToggle.PrimaryColor3 = Color3.fromRGB(255, 133, 51)
ShowSurfaceSelectorToggle.AnchorPoint = Vector2.new(1, 0.5)
ShowSurfaceSelectorToggle.Position = UDim2.new(0.5, VisualizeSpecialLabel.TextBounds.X / 2 + 12, 0.5, 0)
ShowSurfaceSelectorToggle.Checked = ShowSurfaceSelector
ShowSurfaceSelectorToggle.Parent = ShowSurfaceSelectorHolder
table.insert(UIElements.Toggles, ShowSurfaceSelectorToggle)

ShowSurfaceSelectorToggle.OnChecked:Connect(function(On)
	ShowSurfaceSelector = On
	plugin:SetSetting("ShowSurfaceSelector", On)
	FaceSelectionHolder.Visible = On and #Selection:Get() > 0
end)

local FaceSelectionCamera = Instance.new("Camera")
FaceSelectionCamera.FieldOfView = 15
FaceSelectionCamera.Parent = FaceSelectionHolder

local FaceSelectionViewport = Instance.new("ViewportFrame")
FaceSelectionViewport.Size = UDim2.new(0.75, 0, 1, 0)
FaceSelectionViewport.AnchorPoint = Vector2.new(0, 0.5)
FaceSelectionViewport.Position = UDim2.new(0, 0, 0.5, 0)
FaceSelectionViewport.CurrentCamera = FaceSelectionCamera
FaceSelectionViewport.BackgroundTransparency = 1
FaceSelectionViewport.Parent = FaceSelectionHolder

local FaceSelectionSizeKeeper = Instance.new("UIAspectRatioConstraint")
FaceSelectionSizeKeeper.DominantAxis = Enum.DominantAxis.Height
FaceSelectionSizeKeeper.Parent = FaceSelectionViewport

local FaceSelectionPart = Instance.new("Part")
FaceSelectionPart.Anchored = true
FaceSelectionPart.Size = Vector3.new(2, 2, 2)
FaceSelectionPart.Parent = FaceSelectionViewport

local FaceSelectionPartIndicator = Instance.new("Part")
FaceSelectionPartIndicator.Anchored = true
FaceSelectionPartIndicator.Size = Vector3.new(1, 1, 1)
FaceSelectionPartIndicator.Color = Colors.MainContrast
FaceSelectionPartIndicator.Parent = FaceSelectionViewport
table.insert(UIElements.ColoredObjects, FaceSelectionPartIndicator)

local FaceSelectionTab = CreateTextBox(
	{
		Name = "FaceSelectionTab",
		LabelText = "Unknown",
		LabelTextScaled = true,
		BoxText = "Undefined",
		HolderSize = UDim2.new(1, -24, 0, 30),
		HolderPosition = UDim2.new(1, -12, 0.5, 0),
		HolderAnchorPoint = Vector2.new(1, 0.5),
		LabelUIElement = "FloatingLabels",
		Parent = FaceSelectionHolder,

	})

FaceSelectionTab.Label.TextStrokeTransparency = 0

CreateTipBoxes(FaceSelectionTab.Box, SurfacesTypeNames)

local function ToCubeSpace(Part, TargetCF)
	local Scale = math.min(Part.Size.X, Part.Size.Y, Part.Size.Z)
	local SizeRedux = Vector3.new(Scale, Scale, Scale) / Part.Size
	return Part.CFrame * CFrame.new(Part.CFrame:ToObjectSpace(TargetCF).Position * SizeRedux)
end -- ty articlize

FaceSelectionTab.Box:GetPropertyChangedSignal("Text"):Connect(function()
	if not SurfacesTypeNames[FaceSelectionTab.Box.Text] then return end
	local function ChangeObjects(Objects)
		for _, Object in Objects do
			if Object:IsA("BasePart") then
				Object[FaceSelectionTab.Label.Text .. "Surface"] = Enum.SurfaceType[FaceSelectionTab.Box.Text]
			else
				ChangeObjects(Object:GetChildren())
			end
		end
	end
	ChangeObjects(Selection:Get())
	SelectionFaces[FaceSelectionTab.Label.Text] = Enum.SurfaceType[FaceSelectionTab.Box.Text]
	FaceSelectionPart[FaceSelectionTab.Label.Text .. "Surface"] = Enum.SurfaceType[FaceSelectionTab.Box.Text]
end)

FaceSelectionHolder.Parent = ConfigList


-- Add component button and dropdown
local ComponentSelectionHolder = Instance.new("Frame")
ComponentSelectionHolder.Size = UDim2.new(1, 0, 0, 50)
ComponentSelectionHolder.Visible = false
ComponentSelectionHolder.Parent = ConfigList
table.insert(UIElements.Frames, ComponentSelectionHolder)

local pad = Instance.new("UIPadding")
local paddAmt = UDim.new(0, 12)
pad.PaddingBottom = paddAmt
pad.PaddingTop = paddAmt
pad.PaddingRight = paddAmt
pad.PaddingLeft = paddAmt
pad.Parent = ComponentSelectionHolder

local AddComponentButton = PseudoInstance.new("RippleButton")
AddComponentButton.PrimaryColor3 = Colors.MainContrast
AddComponentButton.Size = UDim2.new(0.5, -12, 1, 0)
AddComponentButton.Position = UDim2.new(0, 0, 0, 0)
AddComponentButton.BorderRadius = 4
AddComponentButton.Style = "Contained"
AddComponentButton.Text = "Insert Component"
AddComponentButton.Font = Enum.Font.SourceSans
AddComponentButton.TextSize = 20--24
AddComponentButton.LayoutOrder = 5
AddComponentButton.Parent = ComponentSelectionHolder
table.insert(UIElements.Buttons, AddComponentButton)

local ComponentSelectionTab = CreateTextBox(
	{
		Name = "ComponentSelectionTab",
		LabelText = "",
		LabelTextScaled = true,
		BoxText = "",
		BoxPlaceholderText = "Component",
		BoxSize = UDim2.new(0.5, -4, 1, 0),
		BoxPosition = UDim2.new(0, 4, 0, 0),
		HolderSize = UDim2.new(0.5, 0, 1, 0),
		HolderPosition = UDim2.new(0.5, 0, 0, 0),
		HolderAnchorPoint = Vector2.new(0, 0),
		LabelUIElement = "FloatingLabels",
		Parent = ComponentSelectionHolder,

	})
ComponentSelectionTab.Label.TextStrokeTransparency = 0

-- If part is left
function AddComponentToPart(part: BasePart, componentName: string)
	-- Check if component already exists
	if part:FindFirstChild(componentName) then return end
	
	-- Grab component
	local component
	for _, c in Components do
		if c.Name == componentName then
			component = c
			break
		end
	end

	if component == nil then return end
	
	component:Clone().Parent = part
end

AddComponentButton.OnPressed:Connect(function()
	local componentName = ComponentSelectionTab.Box.Text
	-- Add component to parts
	ForeachSelectedPart(function(selected: BasePart) 
		AddComponentToPart(selected, componentName)
	end)
	
	-- Update part selection GUI
	RefreshSelection()
end)



local function UpdateFaceSelectionViewport()

	local Part = #Selection:Get() == 1 and Selection:Get()[1]:IsA("BasePart") and Selection:Get()[1]

	local PartSize, PartCFrame
	if Part then
		PartSize, PartCFrame = Part.Size, Part.CFrame
	else
		PartSize, PartCFrame = Vector3.new(2, 2, 2), CFrame.new()
	end

	FaceSelectionCamera.CFrame = Camera.CFrame.Rotation * CFrame.new(0, 0, 4 * PartSize.Magnitude)
	FaceSelectionPart.CFrame = PartCFrame.Rotation
	FaceSelectionPart.Size = PartSize

	local Distance, CurrentFace, CurrentVector, Size, Offset = math.huge, nil
	for Vector, Face in 
		{
			[PartCFrame.LookVector] = 	{"Front", 	Vector3.new(PartSize.X - 0.1, PartSize.Y - 0.1, 0.05), PartSize.Z},
			[-PartCFrame.LookVector] = 	{"Back", 	Vector3.new(PartSize.X - 0.1, PartSize.Y - 0.1, 0.05), PartSize.Z},
			[PartCFrame.UpVector] = 	{"Top", 	Vector3.new(PartSize.X - 0.1, 0.05, PartSize.Z - 0.1), PartSize.Y},
			[-PartCFrame.UpVector] = 	{"Bottom",	Vector3.new(PartSize.X - 0.1, 0.05, PartSize.Z - 0.1), PartSize.Y},
			[PartCFrame.RightVector] = 	{"Right", 	Vector3.new(0.05, PartSize.Y - 0.1, PartSize.Z - 0.1), PartSize.X},
			[-PartCFrame.RightVector] = {"Left", 	Vector3.new(0.05, PartSize.Y - 0.1, PartSize.Z - 0.1), PartSize.X},
		} do

		local _Distance = (FaceSelectionCamera.CFrame.Position - Vector).Magnitude
		if _Distance > Distance then continue end
		Distance, CurrentFace, CurrentVector, Size, Offset = _Distance, Face[1], Vector, Face[2], Face[3]

	end

	FaceSelectionPartIndicator.CFrame = PartCFrame.Rotation
	FaceSelectionPartIndicator.CFrame = ToCubeSpace(FaceSelectionPartIndicator, FaceSelectionPart.CFrame + CurrentVector * (Offset / 2))
	FaceSelectionPartIndicator.Size = Size

	FaceSelectionTab.Label.Text = CurrentFace
	FaceSelectionTab.Box.Text = SelectionFaces[CurrentFace] and SelectionFaces[CurrentFace].Name or SelectionFaces[CurrentFace] or "Undefined"

end

local FaceRender

local function Adjust(Object)
	if Object:IsA("BasePart") then AddConfigItem(Object) end
	if VisualizeSpecial and SpecialParts[Object.Name] then SpecialParts[Object.Name](Object) end
	if Object:FindFirstChild("ColorCopy") then
		ApplyColorCopy(Object)
		table.insert(TemporaryConnections, Object:GetPropertyChangedSignal("Color"):Connect(function()
			ApplyColorCopy(Object)
		end))
	end
end	

function RefreshSelection()

	for i,v in pairs(TemporaryConnections) do
		if typeof(v) == "Instance" then v:Destroy() continue end
		v:Disconnect()
	end
	TemporaryConnections = {}

	for i,v in Configs do
		v:Destroy()
	end

	ConfigValues = {}
	
	local SelectedParts = ExtractedUtil.SearchTableWithRecursion(Selection:Get(), function(Element) return typeof(Element) == "Instance" and Element:IsA("BasePart") or typeof(Element) == "table" and Element or Element:GetChildren() end)
	
	CheckTableMalleability(SelectedParts)
	CheckTableOverlap(SelectedParts)
	
	for _, Selected in SelectedParts do
		Adjust(Selected)
	end
	
	-- Create the button and dropdown for adding components
	if #Selection:Get() > 0 then
		CreateTipBoxes(ComponentSelectionTab.Box, Components)
		ComponentSelectionHolder.Visible = true
	else
		ComponentSelectionHolder.Visible = false
	end
	
	if not ShowSurfaceSelector then return end

	if #Selection:Get() > 0 then
		SelectionFaces = {}
		local function GetFaces(Objects)
			for _, Object in Objects do
				for _, Face in Enum.NormalId:GetEnumItems() do
					if SelectionFaces[Face.Name] and SelectionFaces[Face.Name] ~= Object[Face.Name .. "Surface"] then
						SelectionFaces[Face.Name] = "*"
						FaceSelectionPart[Face.Name .. "Surface"] = Enum.SurfaceType.Smooth
						FaceSelectionPartIndicator[Face.Name .. "Surface"] = Enum.SurfaceType.Smooth
					else
						SelectionFaces[Face.Name] = Object[Face.Name .. "Surface"]
						FaceSelectionPart[Face.Name .. "Surface"] = Object[Face.Name .. "Surface"]
						FaceSelectionPartIndicator[Face.Name .. "Surface"] = Object[Face.Name .. "Surface"]
					end
				end
			end
		end

		GetFaces(ExtractedUtil.SearchTableWithRecursion(Selection:Get(), function(Element) return typeof(Element) == "Instance" and Element:IsA("BasePart") or typeof(Element) == "table" and Element or Element:GetChildren() end))
		UpdateFaceSelectionViewport()
		FaceSelectionHolder.Visible = true

		TemporaryConnections["FaceRenderCamera"] = Camera:GetPropertyChangedSignal("CFrame"):Connect(function()
			GetFaces(ExtractedUtil.SearchTableWithRecursion(Selection:Get(), function(Element) return typeof(Element) == "Instance" and Element:IsA("BasePart") or typeof(Element) == "table" and Element or Element:GetChildren() end))
			UpdateFaceSelectionViewport()
		end)

		if #Selection:Get() ~= 1 then return end
		if not Selection:Get()[1]:IsA("BasePart") then return end

		TemporaryConnections["FaceRenderPartCFrame"] = Selection:Get()[1]:GetPropertyChangedSignal("CFrame"):Connect(function()
			GetFaces(Selection:Get())
			UpdateFaceSelectionViewport()
		end)
	else
		FaceSelectionHolder.Visible = false
	end

end

VisualizeSpecialToggle.OnChecked:Connect(function(On)
	VisualizeSpecial = On
	plugin:SetSetting("VisualizeSpecial", On)
	RefreshSelection()
end)

Selection.SelectionChanged:Connect(RefreshSelection)

local function GetSelection()
	local SelectionParts = {}
	local SelectionVectors = {}
	local SelectionCFrames = {}
	local FoundModel = nil
	--add selection descendants to table
	for _,s in pairs(Selection:Get()) do
		if s:IsA("BasePart") then --parts
			SelectionParts[#SelectionParts+1] = s
			SelectionVectors[#SelectionVectors+1] = s.Position
			table.insert(SelectionCFrames, s.CFrame)
		else --models
			for _,p in pairs(s:GetDescendants()) do
				if p:IsA("BasePart") then
					SelectionParts[#SelectionParts+1] = p
					SelectionVectors[#SelectionVectors+1] = p.Position
					table.insert(SelectionCFrames, p.CFrame)
				end
			end
			FoundModel = s
		end
	end
	return SelectionParts, SelectionVectors, SelectionCFrames
end

function ClearScriptsOfName(name: string)
	repeat
		local sc = workspace:FindFirstChild(name)
		if sc then sc:Destroy() end
	until not workspace:FindFirstChild(name)
end

CompileButton.OnPressed:Connect(function()
	local recordingId = ChangeHistoryService:TryBeginRecording("MBEECompile", "Compile Model")

	local success, err = pcall(function()
		if ReplaceCompiles then
			ClearScriptsOfName("MBEOutput")
			ClearScriptsOfName("MBEEOutput")
		end

		if ReplaceUploads then
			ClearScriptsOfName("MBEOutput_Upload")
			ClearScriptsOfName("MBEEOutput_Upload")
		end

		Logger.print("COLLECTING PARTS...")
		local SelectionParts, SelectionVectors, SelectionCFrames = GetSelection()
		Logger.print(`{#SelectionParts} PARTS COLLECTED`)
		
		-- Fill in random configs (gets reverted after compilation)
		local function generateRandId()
			-- Max is 64 https://discord.com/channels/616089055532417036/685118583713562647/1296564993679953931
			local length = 16
			-- inclusive safe utf-8 charcters to use for the antenna ID
			local minchar = 33
			local maxchar = 126

			local id = table.create(length)
			for i = 1, length do
				id[i] = string.char(math.random(minchar, maxchar))
			end
			return table.concat(id)
		end
		local alreadyMadeIds = {}
		local valuesToRevert = {}
		local function randomizeValue(value: ValueBase)
			-- format: `%<number>` eg: %2
			if not value:IsA("StringValue") then return end	-- Only run on string values
			if not (value.Value:sub(1, 1) == "%") then return end -- Only run on ones that match format
			
			valuesToRevert[value] = value.Value
			local id = value.Value:sub(2, -1)

			if alreadyMadeIds[id] then
				value.Value = alreadyMadeIds[id]
			else
				local randId = generateRandId()
				value.Value = randId
				alreadyMadeIds[id] = randId
			end
		end
		local function HandleValue(_value: ValueBase)
			local value = _value :: ValueBase & {Value:any} -- Who knows the the correct solution to make the errors go away is

			-- Handle % antenna randomization
			randomizeValue(value)

			-- Handle compat updates
			local values = CompatabilityReplacements.COMPAT_CONFIG_REPLACEMENTS[value.Name]
			if values then
				local replace = values[value.Value]
				if replace then
					value.Value = replace
				end
			end
		end
		for _, part in SelectionParts do
			for _, child: Configuration|ValueBase in part:GetChildren() do
				
				if child:IsA("Configuration") then
					for _, configValue in child:GetChildren() do
						if not configValue:IsA("ValueBase") then continue end
						HandleValue(configValue)
					end
				end
				
				if child:IsA("ValueBase") then
					HandleValue(child)
				end
			end
		end
		

		--calculate offset
		local BoundingCF, BoundingSize = ExtractedUtil.GetBoundingBox(SelectionParts)
		local AverageVector = ExtractedUtil.AverageVector3s(SelectionVectors)

		compilerSettings.Offset = Vector3.new(-AverageVector.X,-AverageVector.Y + (BoundingSize.Y)-30,-AverageVector.Z) --(BoundingSize.Y/2)-15
		--get offset from offset input
		local Vals = string.split(ModelOffset.Box.Text:gsub("%s+", ""), ",")
		compilerSettings.Offset = compilerSettings.Offset + Vector3.new(unpack(Vals))

		--show result
		Logger.print("COMPILE STARTED...")
		local startCompile = tick()
		local encoded = Compiler:Compile(SelectionParts, compilerSettings)
		local Compilation = HttpService:JSONEncode(encoded)
		
		Logger.print("FIXING PARTSHIFT")
		
		-- Hacky solution to fix part shift & unanchored parts
		local fixedCount = 0
		for i, part in SelectionParts do
			if part.CFrame ~= SelectionCFrames[i] then
				fixedCount += 1
			end
			-- Remove any snaps
			for _, snap in part:GetChildren() do
				if snap:IsA("Snap") then
					snap:Destroy()
				end
			end
			-- Reset parts to correct state
			part.Anchored = true
			part.CFrame = SelectionCFrames[i]
		end
		
		-- Undo randomized ids
		for value: ValueBase, oldValue: any in valuesToRevert do
			value.Value = oldValue
		end
		
		if fixedCount > 0 then
			Logger.warn(`Reverted compiler induced part shift on {fixedCount} parts`)
		end


		local elapsed = string.format("%.3f", tostring(tick() - startCompile))
		Logger.print(`COMPILE FINISHED IN: {elapsed} s.`)
		Logger.print(`COMPILE LENGTH: {#Compilation}`)


		local createdScripts = {}
		
		-- Gist uploads
		if CompileHost:lower() == 'gist' then
			local url = CompileUploader.GistUpload(Compilation, APIKey, UploadName.Box.Text)
			CreateOutputScript(url, "MBEEOutput_Upload", true)
			return
		end
		
		-- Hastebin.org uploads
		if CompileHost:lower() == 'hastebin' then
			local expires = UploadExpireTypes[table.find(UploadExpireAliasTypes, UploadExpireTime:lower()) or 1]
			local url = CompileUploader.HastebinUpload(Compilation, expires)
			CreateOutputScript(url, "MBEEOutput_Upload", true)
			return
		end
		
		if #Compilation <= 200000 then
			-- Warning removed because roblox fixed 16K text box bug!
			--if #Compilation > 16384 then
			--	warn('[MB:E:E] COMPILE EXCEEDS 16384 CHARACTERS (' .. #Compilation .. '), PLEASE UPLOAD YOUR COMPILE TO AN EXTERNAL SERVICE TO LOAD IN-GAME')
			--end
			CreateOutputScript(Compilation, "MBEEOutput", true)
		else
			Logger.warn(`COMPILE EXCEEDS 200000 CHARACTERS ({#Compilation}). AUTOMATICALLY SPLIT INTO MULTIPLE SCRIPTS.`)

			local folder = Instance.new("Folder")
			folder.Name = "MBEEOutput_" .. tostring(math.round(tick()))
			folder.Parent = workspace

			for i=0, math.ceil(#Compilation / 200000) - 1 do
				local source = string.sub(Compilation, 1 + 199999 * i, #Compilation >= (199999 + 199999 * i) and 199999 + 199999 * i or #Compilation)
				local OutputScript = CreateOutputScript(source, "Output #" .. i + 1, false)
				OutputScript.Parent = folder
				table.insert(createdScripts, OutputScript)
			end
		end

		for _, scr in createdScripts do
			if OpenCompilerScripts then
				local success, err = ScriptEditorService:OpenScriptDocumentAsync(scr)
				if not success then
					Logger.warn(`Failed to open script document: {err}`)
				end
			end
		end
	end)
	
	ChangeHistoryService:FinishRecording(recordingId, Enum.FinishRecordingOperation.Commit)
	
	if not success then
		Logger.warn(err)
		Logger.warn(debug.traceback())
		ChangeHistoryService:Undo()
	end
	
end)

SyncColors()
local Selection = game:GetService("Selection")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local ScriptEditorService = game:GetService("ScriptEditorService")

local Parts = script:WaitForChild("Parts")

local MalleabilityConnections = {}
local Adornees = {}

-- stupid stupid stupid...
-- Apparently module scripts don't get the plugin global so I need to do this.
_G.plugin = plugin

-- Load the MBReflect plugin that is now bundled with MBEE
require(script.MBReflect)

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

local APIKey = plugin:GetSetting("APIKey") or ''

local createSharedToolbar = require(script.createSharedToolbar)
local PartData = require(script.PartData)

--rostrap preloading
require(script.MBEPackages.Checkbox)
require(script.MBEPackages.RippleButton)
require(script.MBEPackages.ReplicatedPseudoInstance)
local PseudoInstance = require(script.MBEPackages.PseudoInstance)

local LuaEncode = require(script.MBEPackages.LuaEncode)
local repr = require(script.MBEPackages.repr)
local Branding = require(script.Modules.Branding)

local CustomModules = script.Modules
local Components = script.Components

local Fusion = require(script.Packages.fusion)
local Children = Fusion.Children
local scope = Fusion.scoped(Fusion, {
	Divider = require(Components.Divider),
	ScrollingFrame = require(Components.DynamicScrollingFrame),
	Container = require(Components.Container),
	Padding = require(Components.Padding),
	CheckBox = require(Components.Checkbox),
	TextBox = require(Components.TextBox),
	RippleButton = require(Components.RippleButton),
	UIListLayout = require(Components.UIListLayout),
})
local peek = Fusion.peek

local THEME = require(script.Theme)
local PluginSettingsModule = require(CustomModules.PluginSettings)
local Logger = require(CustomModules.Logger)
local CompileUploader = require(CustomModules.Uploader)
local CompatibilityReplacements = require(CustomModules.Compatibility)
local InfoConstants = require(CustomModules.Settings)
local ExtractedUtil = require(CustomModules.ExtractedUtil)
local UITemplates, UIElements, Colors; do
	local m = require(CustomModules.UITemplates)
	UITemplates = m.UITemplates
	UIElements = m.UIElements
	Colors = m.Colors
end
local PrimaryWidget, ConfigWidget, SettingsWidget
do
	local Widgets = require(script.Widgets)
	PrimaryWidget = Widgets.PrimaryWidget
	ConfigWidget = Widgets.ConfigWidget
	SettingsWidget = Widgets.SettingsWidget
end
local CustomMaterialsModule = require(CustomModules.CustomMaterials)
local CompilersModule = require(CustomModules.Compilers)

local PluginSettings = PluginSettingsModule.CreateFusionValues(scope)
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

type ConfigValue = (ValueBase & {Value: any})

local ConfigValues = {} :: {[string]: {BasePart}}
local TemporaryConnections = {} :: {any}

--[[ Make sure `Camera` always points to the newest camera ]]--
--- Returns current camera, will yield until it exists
local function GetCamera()
	local Camera
	while not Camera do
		Camera = workspace.CurrentCamera
		task.wait()
	end
	return Camera
end
local Camera = GetCamera()
local function OnCameraDestroy()
	Camera = GetCamera()
	Camera.Destroying:Once(OnCameraDestroy)
end
Camera.Destroying:Once(OnCameraDestroy)

local function CheckCompat(name: string): string?
	for i, v in CompatibilityReplacements.COMPAT_NAME_REPLACEMENTS do
		if v:lower() == name:lower() then
			return i
		end
	end
	return nil
end

local function CreateAdornee(subject, color, issue: string): SelectionBox?
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
	local Compiler = CompilersModule:GetSelectedCompiler()
	local temp_type_value_instance = Value:FindFirstChild("TempType") :: StringValue?
	if temp_type_value_instance then
		PartMalleability = Compiler:GetMalleability(tostring(temp_type_value_instance.Value or Value))
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
		if MalleabilityBox then
			table.insert(UIElements.MalleabilityIndicators, MalleabilityBox)
		end
	end
end

local function ApplyColorCopy(Object: BasePart)
	if not Object then Logger.warn("COLOR COPY FAIL, NO OBJECT") return end
	for _, v in pairs(Object:GetChildren()) do
		if v.Name ~= "ColorCopy" then continue end
		if v:IsA("SpecialMesh") then v.VertexColor = Vector3.new(Object.Color.R, Object.Color.G, Object.Color.B) end
		if v:IsA("Texture") or v:IsA("Decal") then (v :: any).Color3 = Object.Color end
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

	if not peek(PluginSettings.MalleabilityToggle) then return end
	if not List then return end
	if typeof(List) ~= 'table' then return end
	if not PrimaryWidget.Enabled then return end

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

local OverlapConnections = {} :: {RBXScriptConnection}
local function CheckTableOverlap(List)

	for i,v in Adornees do
		if not v.O then continue end
		v.O:Destroy()
		Adornees[i].O = nil
	end

	for _, connection in OverlapConnections do
		connection:Disconnect()
	end
	table.clear(OverlapConnections)

	if not peek(PluginSettings.OverlapToggle) then return end

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

settings().Studio.ThemeChanged:Connect(function()
	UITemplates.SyncColors()
end)

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

local function GetAndUpdateCapacityLabel(Object: BasePart, text_creator: (object_volume: number)->())
	local Capacity = Object:FindFirstChild("Capacity") :: BillboardGui?
	local CapacityLabel = Capacity and Capacity:FindFirstChild("CapacityLabel") :: TextLabel?

	-- Create label and bilboard if not exists
	if not Capacity then
		local new_capacity = Instance.new("BillboardGui")
		new_capacity.AlwaysOnTop = true
		new_capacity.Name = "Capacity"
		new_capacity.Archivable = false
		new_capacity.Parent = Object
		Capacity = new_capacity
	end

	if not CapacityLabel then
		local new_capacity_label = Instance.new("TextLabel")
		new_capacity_label.AnchorPoint = Vector2.new(0.5, 0.5)
		new_capacity_label.Position = UDim2.fromScale(0.5, 0.5)
		new_capacity_label.Size = UDim2.fromScale(1, 1)
		new_capacity_label.TextStrokeTransparency = 0
		new_capacity_label.TextColor3 = Color3.new(1, 1, 1)
		new_capacity_label.BackgroundTransparency = 1
		new_capacity_label.Font = Enum.Font.SciFi
		new_capacity_label.TextScaled = true
		new_capacity_label.Name = "CapacityLabel"
		new_capacity_label.Archivable = false
		new_capacity_label.Parent = Capacity
		CapacityLabel = new_capacity_label
	end

	assert(Capacity)
	assert(CapacityLabel)

	local function Update()
		local ObjectVolume = ExtractedUtil.GetVolume(Object)
		local AverageSize = (Object.Size.X + Object.Size.Y + Object.Size.Z) / 3
		Capacity.Size = UDim2.fromScale(AverageSize, AverageSize)
		CapacityLabel.Text = text_creator(ObjectVolume)
	end

	Update()

	-- Detect future updates
	table.insert(TemporaryConnections, Capacity)
	table.insert(TemporaryConnections, Object:GetPropertyChangedSignal("Size"):Connect(Update))

	return CapacityLabel
end

local function BasicCapacityIndicator(storagePerStudCubed: number)
	return function(volume: number)
		local capacity = math.round(volume * storagePerStudCubed)
		local max = CompilersModule:GetSelectedCompiler():GetMalleability("PowerCell") * storagePerStudCubed
		return `{capacity}/{max}`
	end
end

local function BasicRadiusVisualizer(Object: BasePart, radius: number|(volume: number)->(number), color: Color3?): SphereHandleAdornment
	local Sphere = Object:FindFirstChild("__MBEERadiusVisualizer") :: SphereHandleAdornment? or Instance.new("SphereHandleAdornment")
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
		Sphere.Radius = radius(ExtractedUtil.GetVolume(Object))
		table.insert(TemporaryConnections, Object:GetPropertyChangedSignal("Size"):Connect(function()
			Sphere.Radius = radius(ExtractedUtil.GetVolume(Object))
		end))
	else
		Sphere.Radius = radius
	end

	return Sphere
end

local function BasicGridVisualizer(Object: BasePart, size: Vector3|(volume: number)->(Vector3), color: Color3?): BoxHandleAdornment
	local Box = Object:FindFirstChild("__MBEEGridVisualizer") :: BoxHandleAdornment? or Instance.new("BoxHandleAdornment")
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
		Box.Size = size(ExtractedUtil.GetVolume(Object))
		table.insert(TemporaryConnections, Object:GetPropertyChangedSignal("Size"):Connect(function()
			Box.Size = size(ExtractedUtil.GetVolume(Object))
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
		BasicRadiusVisualizer(Object, function(volume)
			return (18 * volume + 0.5 * volume)
		end, Color3.new(0, 0.5, 1))

		-- I don't want this to be slow, hence no `GetVolume(Parts:FindFirstChild("AirSupply"))`
		-- I could cache it somewhere but I'm lazy and its not a big deal
		-- The chance it changes is like... nearly zero
		-- probably...
		local BASE_AIR_SUPPLY_VOLUME = 16
		BasicGridVisualizer(Object, function(volume)
			-- https://discord.com/channels/616089055532417036/1047587493693886547/1326707636405801052
			-- https://discord.com/channels/616089055532417036/616089055532417040/1314957945536249988
			return Vector3.one * (300 * volume / BASE_AIR_SUPPLY_VOLUME)
		end, Color3.new(1, 0.3, 0))
	end,

	GravityGenerator = function(Object)
		BasicRadiusVisualizer(Object, 300, Color3.new(0.5, 0, 1))
	end,

	EnergyShield = function(Object: BasePart & {ShieldRadius: NumberValue})
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
			local Color = ExtractedUtil.StringToColor3(Value)
			if Color then
				-- TODO: This is a weird bug thing
				-- because it needs to write the value in 0-1 range
				-- but the GUI wants to have a nice fancy 0-255 range
				-- figure out how to properly fix this
				Object:FindFirstChild("TextColor").Value = table.concat({Color.R, Color.G, Color.B}, ", ")
				SignGui.SignLabel.TextColor3 = Color
			end
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

local function GetSameConfigOfOtherObject(otherObject: BasePart, referenceConfig: ValueBase): ValueBase?
	local IS_COMPONENT_CONFIG = assert(referenceConfig.Parent, "Reference config has been destroyed"):IsA("Configuration")
	if IS_COMPONENT_CONFIG then
		local component = otherObject:FindFirstChild(referenceConfig.Parent.Name)
		return if component then component:FindFirstChild(referenceConfig.Name) :: ValueBase? else nil
	else
		return otherObject:FindFirstChild(referenceConfig.Name) :: ValueBase?
	end
end

-- Class name of part, Part instance, Value Instance, New Value
local function ApplyConfigurationValues(ItemIdentifier: string?, RootObject: BasePart, Value: ValueBase, ValueStatus: any)
	-- Get a list of objects that need to be configured
	local objects: {BasePart}
	if ItemIdentifier then
		objects = ConfigValues[ItemIdentifier]
	else
		objects = {RootObject}
	end

	-- Get the AdjustmentFunction for this config
	local AdjustmentFunction = ComponentAdjustmentFunctions[assert(Value.Parent).Name] or AdjustmentFunctions[RootObject.Name]

	-- Configure each object
	for _, object in objects do
		local otherValue = GetSameConfigOfOtherObject(object, Value) :: ConfigValue?
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

local BG = scope:ScrollingFrame {
	ListPadding = UDim.new(0, 10),
	ScrollBarThickness = 0,
	[Children] = {
		require(script.PartList),
	}
} :: ScrollingFrame

PrimaryWidget:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	plugin:SetSetting("PluginSize", {
		{PrimaryWidget.AbsoluteSize.X, PrimaryWidget.AbsoluteSize.Y},
		{ConfigWidget.AbsoluteSize.X, ConfigWidget.AbsoluteSize.Y}
	})
end)

-- MARK: Setting UI
-- Create the UI buttons and stuff to control internal setting states
do
	local CATEGORY_CONTAINERS = {
		-- advanced = _, -- TODO
		main = BG,
	}
	for i, setting in PluginSettingsModule.InfoArray do
		for _, category in setting.Categories do
			local container = CATEGORY_CONTAINERS[category]
			if not container then continue end
			local layout = {
				LayoutOrder = i
			}
			-- This will eventually be integrated entierly into fusion based UI
			-- For now its this hack until then
			if setting.Type == "boolean" then
				scope:CheckBox {
					Label = setting.Key,
					Parent = container,
					Checked = PluginSettings[setting.Key],
					Layout = layout,
				}
			else
				scope:TextBox {
					Parent = container,
					Text = PluginSettings[setting.Key],
					Layout = layout,
					Options = setting.Options,
					Label = {
						Text = setting.Key,
					}
				}
			end

		end
	end
end

scope:Observer(PluginSettings.MalleabilityToggle):onChange(function()
	CheckTableMalleability(Selection:Get())
end)

scope:Observer(PluginSettings.OverlapToggle):onChange(function()
	CheckTableOverlap(Selection:Get())
end)

local ModelOffset = UITemplates.UITemplatesCreateTextBox(
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


--[[
Things to re-add

ReplaceUploads only visible if CompileHost is valid
ReplaceCompiles only visible if CompileHost not valid
]]
--[[


UploadTo = UITemplates.UITemplatesCreateTextBox(
	{
		Name = "UploadTo",
		LabelText = "Upload To",
		BoxPlaceholderText = "hastebin/gist",
		BoxText = CompileHost,
		BoxFont = (CompileHost:lower() == "gist" or CompileHost:lower() == "hastebin") and "SourceSans" or "SourceSansLight",
		Parent = BG,
		LayoutOrder = 8,
	})
UITemplates.ConnectBoxToAutocomplete(UploadTo.Box, {"hastebin"})
UITemplates.CreateTipBoxes(UploadTo.Box, {"hastebin"})

UpladExpiry = UITemplates.UITemplatesCreateTextBox(
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
UITemplates.ConnectBoxToAutocomplete(UpladExpiry.Box, UploadExpireAliasTypes)
UITemplates.CreateTipBoxes(UpladExpiry.Box, UploadExpireAliasTypes)

UploadToken = UITemplates.UITemplatesCreateTextBox(
	{
		Name = "UploadToken",
		LabelText = "Upload Token",
		BoxText = APIKey,
		BoxPlaceholderText = (CompileHost:lower() == "gist") and "PAT Token" or "...",
		Parent = BG,
		HolderVisible = (CompileHost:lower() == "gist"),
		LayoutOrder = 9,
	})

UploadName = UITemplates.UITemplatesCreateTextBox(
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
]]

scope:Divider {
	Thickness = 1,
	LayoutOrder = 11,
	Parent = BG,
}

local Decompilation = UITemplates.UITemplatesCreateTextBox(
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
	if open and PluginSettings.OpenCompilerScripts then
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

		local instances, saveData = CompilersModule:GetSelectedCompiler():Decompile(content, compilerSettings)

		model = Instance.new("Model")
		model.Name = "Decompilation"

		for _, instance in instances do
			instance.Parent = model
		end

		local _, bounds = model:GetBoundingBox()

		model.Parent = workspace

		model:MoveTo(ExtractedUtil.GetInsertPoint(bounds.Magnitude * 2, bounds.Y / 2))

		-- Create a script to put the details in
		local source = `-- The following is a summary of the data contained in the model's save format generated by LuaEncode.\n-- Your model has been selected in the explorer. \nreturn {LuaEncode(saveData, {
			Prettify = true
		})}`
		local details_script = CreateOutputScript(source, Branding.NAME_ABBREVIATION .. "Details", true)
		if details_script then
			details_script.Parent = model
		end

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
		if ExtractedUtil.IsTemplate(v) then
			ExtractedUtil.ApplyTemplates({v})
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

	local save_string = Decompilation.Box.Text
	local model = ModernDecompile(save_string)

	if model then
		Logger.print("DECOMPILE SUCCESS")
	else
		Logger.print("MODERN DECOMPILE FAILED, TRYING CLASSIC DECOMPILER")

		local ok, result = pcall(ClassicDecompile, save_string)

		if ok then
			Logger.print("CLASSIC DECOMPILE SUCCESS")
		else
			Logger.print("CLASSIC DECOMPILE FAILED WITH ERROR", result)
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
	CustomMaterialsModule.Clear()
	warn('[MB:E:E] SUCCESSFULLY RESET MATERIAL DATA')
end)

----==== These functions are connected to buttons in the settings menu ====----
local function SelectCompilerButton()
	local options = {}
	local VERSION_TO_COMPILER_ID = {}
	for compiler_id, comp in CompilersModule:GetCompilers() do
		table.insert(options, comp.Version)
		VERSION_TO_COMPILER_ID[comp.Version] = compiler_id
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
		local i = VERSION_TO_COMPILER_ID[Choice]
		CompilersModule:SelectCompiler(i)
	end)

	Dialog.Parent = SettingsWidget
end

local function PerformGenericMigration(name: string, callback: (part: BasePart)->())
	local function tryMigrate(instances: {Instance})
		for _, instance in instances do
			if not instance:IsA("BasePart") then
				continue
			end

			callback(instance)
		end
	end
	ExtractedUtil.HistoricEvent(name, nil, function()
		local selected = Selection:Get()
		tryMigrate(selected)
		for _, selection in selected do
			tryMigrate(selection:GetDescendants())
		end
	end)
end

local function MigrateSelectionButton()
	local Compiler = CompilersModule:GetSelectedCompiler()

	PerformGenericMigration("MigrateTemplates", function(part: BasePart)
		-- Try to migrate templates for the instance
		Compiler:TryMigrateTemplates(part)
	end)

	PerformGenericMigration("CompatibilityMigration", function(part: BasePart)
		local replacement = CompatibilityReplacements.COMPAT_NAME_REPLACEMENTS[part.Name]
		if replacement then
			part.Name = replacement
		end
	end)
end

local function MigrateConfigurablesButton()
	local Compiler = CompilersModule:GetSelectedCompiler()
	PerformGenericMigration("MigrateConfigurables", function(part: BasePart)
		-- Try to migrate templates for the instance
		Compiler:MigrateConfigurables(part)
	end)
end

local function GetRequiredMaterialsButton()
	local Required = {
		['Raw Materials'] = {},
		['All Parts'] = {}
	}
	local PartAmount = 0

	local function AddAmount(Part: string|BasePart, Amount, Category)
		if not Part then return end
		if not(typeof(Part) == 'string' or Part:IsA("BasePart")) then return end
		if not Required[Category] then return end
		local PartIdentifier = if typeof(Part) == 'string' then Part else Part.Name
		if not Required[Category][PartIdentifier] then Required[Category][PartIdentifier] = 0 end
		Required[Category][PartIdentifier] += Amount
	end

	local function Loop(Table, Offset: string, Multiplier: number)
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
				local temp_type_instance = v:FindFirstChild("TempType") :: StringValue?
				if not temp_type_instance and PartData[v.Name] and PartData[v.Name].Recipe or Compat then
					AddAmount(v, 1, 'All Parts')
					Loop(Compat and PartData[Compat] or PartData[v.Name], ' ', 1)
				elseif temp_type_instance then
					AddAmount(temp_type_instance.Value, 1, 'All Parts')
					AddAmount(temp_type_instance.Value, 1, 'Raw Materials')
				elseif not PartData[v.Name] or PartData[v.Name] and not PartData[v.Name].Recipe then
					AddAmount(v, 1, 'All Parts')
					AddAmount(v, 1, 'Raw Materials')
				end
				PartAmount += 1
			end
		end
	end

	Logger.print("Part Amount:", PartAmount)
	Logger.print("Calculated Creation Requirements:\n", repr(Required :: any, {pretty=true} :: any))
end

-- Eventually `ConfigList` will be removed when fusion is more prevasive
-- Configure part Widget
local ConfigList = scope:ScrollingFrame {
	ScrollingDirection = "Y",
	BackgroundTransparency = 0,
	ListPadding = UDim.new(0, 1),
} :: ScrollingFrame
scope:New "Frame" {
	Size = UDim2.fromScale(1, 1),
	Parent = ConfigWidget,
	BackgroundColor3 = THEME.COLORS.MainBackground,
	[Children] = {
		ConfigList,
	}
}

----==== Plugin Settings Widget ====----
local function SettingGroup(
	scope: Fusion.Scope<typeof(Fusion)>,
	props: {
		[typeof(Children)]: Fusion.Child,
	}
): Fusion.Child
	local scope = scope:innerScope({
		Container = require(Components.Container),
		UIListLayout = require(Components.UIListLayout),
	})
	return scope:Container {
		BackgroundTransparency = 1,
		Layout = {
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromScale(1, 0),
		},
		[Children] = {
			scope:UIListLayout {
				SortOrder = Enum.SortOrder.Name
			},
			props[Children],
		}
	}
end
scope:Container {
	Parent = SettingsWidget,
	[Children] = {
		scope:ScrollingFrame {
			ScrollingDirection = "Y",
			ListPadding = UDim.new(0, 4),
			BackgroundTransparency = 1,
			[Children] = {
				-- Action buttons
				SettingGroup(scope, {
					[Children] = {
						scope:RippleButton {
							Label = "Select Compiler",
							Style = "Outlined",
							OnPressed = SelectCompilerButton,
						},
						scope:RippleButton {
							Label = "Get Required Materials for Selection",
							Style = "Outlined",
							OnPressed = GetRequiredMaterialsButton,
						},
						scope:RippleButton {
							Label = "Migrate Selection",
							Style = "Outlined",
							OnPressed = MigrateSelectionButton,
						},
						scope:RippleButton {
							Label = "Migrate Configurables",
							Style = "Outlined",
							OnPressed = MigrateConfigurablesButton,
						},
					}
				}),

				scope:Divider {},

				-- Settings
				SettingGroup(scope, {
					[Children] = scope:ForPairs(PluginSettings, function(use, scope: typeof(scope), key, value)
						local setting = PluginSettingsModule.Info[key]

						if setting.Type == "boolean" then
							return key, scope:CheckBox {
								Label = setting.Key,
								Checked = value,
							}
						else
							return key, scope:TextBox {
								Text = value,
								Label = {
									Text = setting.Key,
								}
							}
						end
					end),
				}),

				scope:Divider {},

				scope:RippleButton {
					Label = "Reset Colors",
					Style = "Outlined",
					OnPressed = function()
						THEME.Set("Classic")
					end,
				},
				SettingGroup(scope, {
					[Children] = {

						-- Color Settings
						-- TODO: fix formatting
						scope:ForPairs(THEME.COLORS, function(use, scope: typeof(scope), key, value: Fusion.Value<Color3>)
							local box_value = scope:Value(ExtractedUtil.Color3ToString(peek(value)))
							scope:Observer(box_value):onChange(function()
								local new_color = ExtractedUtil.StringToColor3(peek(box_value))
								if new_color then
									value:set(new_color)
								end
							end)
							return key, scope:TextBox {
								Text = box_value,
								BoxPlaceholderText = scope:Computed(function(use)
									return `RGB Color ({ExtractedUtil.Color3ToString(use(value))})`
								end),
								Box = {
									TextColor3 = scope:Computed(function(use)
										return ExtractedUtil.ContrastColor(use(value))
									end),
									BackgroundColor3 = value
								},
								Label = {
									Text = key,
								},
								Layout = {
									LayoutOrder = 100 + key:byte(1, 1) :: number + key:byte(2, 2) :: number * 26
								},
							}
						end)
					}
				}),
			}
		}
	}
}

BG.Parent = PrimaryWidget

local CompilerSettings = {}
CompilerSettings.CombinerName = "WoS Tools"
CompilerSettings.ToolbarName = "WoS Tools"
CompilerSettings.ButtonName = "CompilerButton"
CompilerSettings.ButtonText = "Compiler"
--CompilerSettings.ButtonIcon = "rbxassetid://10081258730" -- MBE
CompilerSettings.ButtonIcon = "rbxassetid://97909283646131" -- MBEE
CompilerSettings.ButtonTooltip = "WoS Compiler."
CompilerSettings.ClickedFn = function()
	PrimaryWidget.Enabled = not PrimaryWidget.Enabled
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
	SettingsWidget.Enabled = not SettingsWidget.Enabled
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
	UITemplates.ConnectBoxToAutocomplete(TextBox.Box, script.Parts:GetChildren())
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

		["Code"] = function(TextBox, ConfigValue: StringValue)
			local MicrocontrollerScript = ConfigValue:FindFirstChildWhichIsA("Script")

			if not MicrocontrollerScript then
				MicrocontrollerScript = ConfigValue:FindFirstChildWhichIsA("Script") or Instance.new("Script")
				assert(MicrocontrollerScript)
				MicrocontrollerScript.Name = "MicrocontrollerCode"
				ScriptEditorService:UpdateSourceAsync(MicrocontrollerScript, function(_)
					return ConfigValue.Value
				end)
				MicrocontrollerScript.Parent = ConfigValue
			end

			if not OpenedMicrocontrollerScript then
				OpenedMicrocontrollerScript = MicrocontrollerScript
				assert(OpenedMicrocontrollerScript)

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
			assert(OpenedMicrocontrollerScript)

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
	local instance_key = CompatibilityReplacements.COMPAT_NAME_REPLACEMENTS[instance_to_configure.Name] or instance_to_configure.Name

	local function GetDefaultConfigValue(config_data)
		local default_value = config_data.Default :: any
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
		local configurations = CompilersModule:GetConfigData()[config_location][instance_key]
		-- This function will often be called for parts without configs
		if not configurations then
			-- Logger.print(`Missing PartData for {config_location}/{instance_key}`)
			return
		end

		-- Actuall part that should be effected when this config changes
		local associated_base_part = if instance_to_configure:IsA("BasePart")
			then instance_to_configure
			else instance_to_configure:FindFirstAncestorWhichIsA("BasePart")
		assert(associated_base_part, "Instance|Configuration missing BasePart ancestor")
		local associated_base_part_key = associated_base_part.Name

		for i, config_data in configurations do
			local config_type = config_data.Type
			local config_name = config_data.Name

			-- Insert value instance into part if it doesn't already exist
			local config_instance = instance_to_configure:FindFirstChild(config_name) :: ConfigValue?
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
				local new_config_instance = Instance.new(expected_config_class) :: ConfigValue
				new_config_instance.Name = config_name
				new_config_instance.Value = old_value or GetDefaultConfigValue(config_data)
				new_config_instance.Parent = instance_to_configure
				config_instance = new_config_instance
			end
			assert(config_instance)

			local toSync: {[string]: {any}}
			local GENERATED_BOX
			local function GenericTextBox(placeholder: string)
				local TextBox = UITemplates.UITemplatesCreateTextBox({
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
				local Check = UITemplates.CreateCheckBox({
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
				local TextBox = GenericTextBox(`{config_data.Default} [num/int]`)
				toSync = {Labels = {TextBox.Label}, Boxes = {TextBox.Box}}
			elseif config_type == "Selection" then
				-- Dropdowns like apparel limb
				local TextBox = GenericTextBox("Option [string]")

				TextBox.Box.Text = config_instance.Value
				UITemplates.CreateTipBoxes(TextBox.Box, GetOptions(config_data))
			else
				Logger.warn(`Missing handler for type {config_type} @{config_location}/{instance_key}`)
				GenericTextBox(`undefined [Unknown<{config_type}>]`)
			end

			-- Bind to every part autocomplete if applicable
			if GENERATED_BOX and SpecialMaterialValues[config_name] then
				SpecialMaterialValues[config_name](GENERATED_BOX, config_instance)
			end

			UITemplates.SyncColors(toSync)
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

	local TextBox = UITemplates.UITemplatesCreateTextBox({
		HolderSize = CONFIG_HOLDER_SIZE,
		LabelText = "Resource",
		BoxPlaceholderText = "Resource [string]",
		BoxText = instance_key,
	})

	UITemplates.ConnectBoxToAutocomplete(TextBox.Box, script.Parts:GetChildren())

	-- On Resource config changed
	ExtractedUtil.BindToEventWithUndo(TextBox.Box:GetPropertyChangedSignal("Text"), "Configure", nil, function()
		ExtractedUtil.ApplyTemplates(ConfigValues[instance_key], TextBox.Box.Text)
	end)

	TextBox.Holder.Parent = output_container

	UITemplates.SyncColors({Labels = {TextBox.Label}, Boxes = {TextBox.Box}})
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
		local temp_type = Item:FindFirstChild("TempType") :: StringValue?
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
		if ExtractedUtil.IsTemplate(Item) then
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

		UITemplates.SyncColors({Labels = configLabels, Frames = configContainers})
		primaryConfigContainer.Parent = ConfigList
		table.insert(Configs, primaryConfigContainer)
	end

	-- Insert item into its table at key so its configured when the gui is changed
	table.insert(ConfigValues[ItemIdentifier], Item)
end

--------------------------
-- Face selection thing --
--------------------------
-- Function
local UpdateFaceSelectionViewport;do

	local FACES = {"Front", "Back", "Top", "Bottom", "Right", "Left"}

	-- Name of every surface (like Universal or Smooth)
	local SURFACE_TYPE_NAMES = {}; do
		local exclude = {
			Enum.SurfaceType.Weld,
			Enum.SurfaceType.Glue,
			Enum.SurfaceType.SteppingMotor,
		}
		for _, SurfaceType in Enum.SurfaceType:GetEnumItems() do
			if table.find(exclude, SurfaceType) then continue end
			SURFACE_TYPE_NAMES[SurfaceType.Name] = SurfaceType.Name
		end
	end

	local MAP_SURFACE_NAME_TO_ENUM = {}; do
		for _, surface_type in Enum.SurfaceType:GetEnumItems() do
			MAP_SURFACE_NAME_TO_ENUM[surface_type.Name] = surface_type
		end
	end

	--- Part that is currently being mirrored to the viewport frame
	local selected_part = scope:Value(nil :: BasePart?)

	--- CFrame of the local player's camera
	local camera_cframe = scope:Value(Camera.CFrame)
	table.insert(scope, Camera:GetPropertyChangedSignal("CFrame"):Connect(function()
		camera_cframe:set(Camera.CFrame)
	end))

	--- Computed cframe for the viewport frame camera
	local viewport_camera_cframe = scope:Computed(function(use)
		local block = use(selected_part)
		if not block then return CFrame.identity end
		return use(camera_cframe).Rotation * CFrame.new(0, 0, 4 * block.Size.Magnitude)
	end)
	local viewport_camera = scope:New "Camera" {
		FieldOfView = 15,
		CFrame = viewport_camera_cframe,
	} :: Fusion.Child

	--- Faces of currently selected part
	--- Maps Front/Back/etc to Universal/Weld/etc
	local SelectionFaces = scope:Value({})

	-- Update currently selected faces list
	table.insert(scope, Selection.SelectionChanged:Connect(function()
		if peek(selected_part) == nil then return end

		local faces = {}
		local selected_parts = Selection:Get()

		for _, face_name in FACES do
			for _, part in selected_parts do
				if not part:IsA("BasePart") then continue end
				local face_type = part[face_name .. "Surface"].Name
				if faces[face_name] and faces[face_name] ~= face_type then
					faces[face_name] = "*"
					break
				else
					faces[face_name] = face_type
				end
			end
		end

		SelectionFaces:set(faces)
	end))

	-- Face (Top/Left/etc) as string that is closest to the viewport frame camera
	local closest_face = scope:Computed(function(use)
		local cam_pos = use(viewport_camera_cframe).Position
		local closest_dist = math.huge
		local closest_face
		for _, face in FACES do
			local axis = Vector3.fromNormalId(face :: any)
			local distance = (cam_pos - axis).Magnitude
			if distance < closest_dist then
				closest_dist = distance
				closest_face = face
			end
		end
		return closest_face
	end)

	-- `closest_face` as a Vector3
	local closest_face_axis = scope:Computed(function(use)
		return Vector3.fromNormalId(use(closest_face) :: any)
	end)

	local face_selection_indicator_size = scope:Computed(function(use)
		local part = use(selected_part)
		if not part then return Vector3.one end

		local axis = use(closest_face_axis):Abs()
		local axis_mask = (axis - Vector3.one):Abs()
		local plate_thickness = 0.05
		local shrink_amount = 0.1
		return (part.Size - Vector3.one * shrink_amount) * axis_mask + axis * plate_thickness
	end)

	local function SetSurface(part: BasePart, face: string, surface_type: Enum.SurfaceType)
		if face == "Front" then
			part.FrontSurface = surface_type
		elseif face == "Back" then
			part.BackSurface = surface_type
		elseif face == "Top" then
			part.TopSurface = surface_type
		elseif face == "Bottom" then
			part.BottomSurface = surface_type
		elseif face == "Right" then
			part.RightSurface = surface_type
		elseif face == "Left" then
			part.LeftSurface = surface_type
		end
	end

	local function OnTextChange(surface_type_name: string)
		local surface_type = MAP_SURFACE_NAME_TO_ENUM[surface_type_name]
		if not surface_type then return end

		local current_face_name = peek(closest_face)

		-- Apply new surface to every selected part's face
		local function TryApplySurface(part: BasePart)
			if part:IsA("BasePart") then
				SetSurface(part, current_face_name, surface_type)
			end
		end
		for _, instance in Selection:Get() do
			TryApplySurface(instance)
			for _, instance in instance:GetDescendants() do
				TryApplySurface(instance)
			end
		end

		-- Update SelectionFaces value with the new surface type at the given face
		local _SelectionFaces = peek(SelectionFaces)
		_SelectionFaces[current_face_name] = surface_type.Name
		SelectionFaces:set(_SelectionFaces)
	end

	--- Generate higher order computed that is always equal to the input face's surface type
	local function SurfaceSyncer(face_name: string)
		return scope:Computed(function(use)
			-- Get correct surface type. If type is nil, return Universal as default
			local surface_type = use(SelectionFaces)[face_name]
			-- When multiple parts are selected and have
			-- different types for the same face
			-- it will be *
			-- In that case, just show a smooth "blank" surface
			if surface_type == "*" then
				return Enum.SurfaceType.Smooth

			-- Rare edge case that can be hit on initialization
			elseif surface_type == nil then
				return Enum.SurfaceType.Universal
			end

			-- By now `surface_type` should be garunteed to be a valid surface
			-- that all the selected parts share on this face
			return surface_type :: any
		end)
	end

	scope:New "Frame" {
		Name = "FaceSelectionHolder",
		Size = UDim2.new(1, 0, 0, 120),
		Visible = scope:Computed(function(use)
			return use(PluginSettings.ShowSurfaceSelector) and use(selected_part) ~= nil
		end),
		BackgroundColor3 = THEME.COLORS.MainBackground,
		Parent = ConfigList,
		[Children] = {
			viewport_camera,
			scope:New "ViewportFrame" {
				Size = UDim2.fromScale(0.75, 1),
				CurrentCamera = viewport_camera,
				BackgroundTransparency = 1,
				[Children] = {
					scope:New "UIAspectRatioConstraint" {
						DominantAxis = Enum.DominantAxis.Height,
					},
					-- FaceSelectionPart
					scope:New "Part" {
						Name = "FaceSelectionPart",
						Size = scope:Computed(function(use)
							part = use(selected_part)
							if not part then return Vector3.one*2 end
							return part.Size
						end),
						CFrame = scope:Computed(function(use)
							part = use(selected_part)
							if not part then return CFrame.identity end
							return part.CFrame.Rotation
						end),

						-- cursed
						FrontSurface = SurfaceSyncer("Front"),
						BackSurface = SurfaceSyncer("Back"),
						TopSurface = SurfaceSyncer("Top"),
						BottomSurface = SurfaceSyncer("Bottom"),
						RightSurface = SurfaceSyncer("Right"),
						LeftSurface = SurfaceSyncer("Left"),
					},
					-- FaceSelectionPartIndicator
					scope:New "Part" {
						Color = THEME.COLORS.MainContrast,
						Size = face_selection_indicator_size,
						CFrame = scope:Computed(function(use)
							local size = use(face_selection_indicator_size)
							local part = use(selected_part)
							if not part then return CFrame.identity end
							local selected_rotation = part.CFrame.Rotation
							local target_cf = selected_rotation + use(closest_face_axis) * part.Size / 2
							-- To cube space
							-- No idea what it does
							-- by articlize
							local Scale = math.min(size.X, size.Y, size.Z)
							local SizeRedux = Vector3.new(Scale, Scale, Scale) / size
							return selected_rotation * CFrame.new(selected_rotation:ToObjectSpace(target_cf).Position * SizeRedux)
						end),
						-- cursed
						FrontSurface = SurfaceSyncer("Front"),
						BackSurface = SurfaceSyncer("Back"),
						TopSurface = SurfaceSyncer("Top"),
						BottomSurface = SurfaceSyncer("Bottom"),
						RightSurface = SurfaceSyncer("Right"),
						LeftSurface = SurfaceSyncer("Left"),
					},
				}
			},
			-- Face change text box
			scope:TextBox {
				Text = scope:Computed(function(use)
					return use(SelectionFaces)[use(closest_face)] or "Undefined"
				end),
				onTextChange = OnTextChange,

				Label = {
					Text = scope:Computed(function(use)
						return use(closest_face)
					end),
					TextScaled = true,
					TextColor3 = THEME.COLORS.MainContrast,
				},

				Options = SURFACE_TYPE_NAMES,
				Layout = {
					Size = UDim2.new(1, -24, 0, 30),
					Position = UDim2.new(1, -12, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
				}
			},
		}
	}

	UpdateFaceSelectionViewport = function()
		for _, instance in Selection:Get() do
			if instance:IsA("BasePart") then
				selected_part:set(instance)
				return
			end
		end
		selected_part:set(nil)
	end
end
--- end ---

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

local ComponentSelectionTab = UITemplates.UITemplatesCreateTextBox({
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
	local component: Configuration?
	for _, c in CompilersModule:GetComponents() do
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

local function Adjust(Object)
	if Object:IsA("BasePart") then AddConfigItem(Object) end
	if peek(PluginSettings.VisualizeSpecial) and SpecialParts[Object.Name] then SpecialParts[Object.Name](Object) end
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
		UITemplates.CreateTipBoxes(ComponentSelectionTab.Box, CompilersModule:GetComponents())
		ComponentSelectionHolder.Visible = true
	else
		ComponentSelectionHolder.Visible = false
	end

	if not peek(PluginSettings.ShowSurfaceSelector) then return end
	UpdateFaceSelectionViewport()
end

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
	ExtractedUtil.HistoricEvent("Compile", "Compile Model", function()
		if peek(PluginSettings.ReplaceCompiles) then
			ClearScriptsOfName("MBEOutput")
			ClearScriptsOfName("MBEEOutput")
		end

		if peek(PluginSettings.ReplaceUploads) then
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
			local values = CompatibilityReplacements.COMPAT_CONFIG_REPLACEMENTS[value.Name]
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
		local encoded = CompilersModule:GetSelectedCompiler():Compile(SelectionParts, compilerSettings)
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

		local compile_host = peek(PluginSettings.CompileHost)

		-- Gist uploads
		if compile_host:lower() == 'gist' then
			local url = CompileUploader.GistUpload(Compilation, APIKey, UploadName.Box.Text)
			CreateOutputScript(url, "MBEEOutput_Upload", true)
			return
		end

		-- Hastebin.org uploads
		if compile_host:lower() == 'hastebin' then
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
			if peek(PluginSettings.OpenCompilerScripts) then
				local success, err = ScriptEditorService:OpenScriptDocumentAsync(scr)
				if not success then
					Logger.warn(`Failed to open script document: {err}`)
				end
			end
		end
	end)
end)
UITemplates.SyncColors()
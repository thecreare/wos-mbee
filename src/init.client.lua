local Selection = game:GetService("Selection")
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

local ConfigValues = require(script.ConfigValues_G)
local createSharedToolbar = require(script.createSharedToolbar)
local PartData = require(script.PartData)

--rostrap preloading
require(script.MBEPackages.Checkbox)
require(script.MBEPackages.RippleButton)
require(script.MBEPackages.ReplicatedPseudoInstance)
local PseudoInstance = require(script.MBEPackages.PseudoInstance)

local repr = require(script.MBEPackages.repr)
local ApplyColorCopy = require(script.Modules.ApplyColorCopy)
local ApplyConfigurationValues = require(script.Modules.ApplyConfigurationValues)
local GetEnumNames = require(script.Modules.GetEnumNames)
local UpdatePilotTypes = require(script.Modules.UpdatePilotTypes)
local WosSelection = require(script.Modules.WosSelection)

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
	LabeledSetting = require(Components.LabeledSetting),
	RippleButton = require(Components.RippleButton),
	UIListLayout = require(Components.UIListLayout),
})
local peek = Fusion.peek

local THEME = require(script.Theme)
local PluginSettingsModule = require(CustomModules.PluginSettings)
local Logger = require(CustomModules.Logger)
local CompatibilityReplacements = require(CustomModules.Compatibility)
local InfoConstants = require(CustomModules.Settings)
local ExtractedUtil = require(CustomModules.ExtractedUtil)
local Compile = require(CustomModules.Compile)
local Decompile = require(CustomModules.Decompile)
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

local PluginSettings = PluginSettingsModule.Values
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

type UsedAs<T>  = Fusion.UsedAs<T>
type ConfigValue = (ValueBase & {Value: any})

local TemporaryConnections = {} :: {any}

--[[ Make sure `Camera` always points to the newest camera ]]--
--- Returns current camera, will yield until it exists
local Camera
do
	local function GetCamera()
		local Camera
		while not Camera do
			Camera = workspace.CurrentCamera
			task.wait()
		end
		return Camera
	end
	Camera = GetCamera()
	local function OnCameraDestroy()
		Camera = GetCamera()
		Camera.Destroying:Once(OnCameraDestroy)
	end
	Camera.Destroying:Once(OnCameraDestroy)
end

local function CheckCompat(name: string): string?
	for i, v in CompatibilityReplacements.COMPAT_NAME_REPLACEMENTS do
		if i:lower() == name:lower() then
			return v
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

-- Primary Window
local function AutomaticIndividualLabeledSetting(setting: string, layout_order: number?)
	return scope:LabeledSetting {
		Setting = setting,
		Layout = {
			LayoutOrder = layout_order,
		}
	}
end
local upload_to_gist = scope:Computed(function(use)
	return use(PluginSettings.CompileHost):lower() == "gist"
end)
local upload_to_hastebin = scope:Computed(function(use)
	return use(PluginSettings.CompileHost):lower() == "hastebin"
end)
local no_upload = scope:Computed(function(use)
	return not use(upload_to_gist) and not use(upload_to_hastebin)
end)
local decompilation_text = ""
local BG = scope:ScrollingFrame {
	ListPadding = UDim.new(0, 10),
	ScrollBarThickness = 0,
	Parent = PrimaryWidget,
	[Children] = {
		require(script.PartList),
		AutomaticIndividualLabeledSetting("TemplateMaterial", 5),
		-- Template Material
		AutomaticIndividualLabeledSetting("MalleabilityToggle", 10),
		AutomaticIndividualLabeledSetting("OverlapToggle", 15),
		-- Removed because it doesn't seem to do anything
		-- AutomaticIndividualLabeledSetting("ModelOffset", 20),
		-- Compile Button
		scope:RippleButton {
			Label = "Compile",
			Style = "Contained",
			BorderRadius = 4,
			OnPressed = Compile,
			Layout = {
				Size = UDim2.new(1, -6, 0, 32),
				LayoutOrder = 25,
			}
		},
		-- Replace Old Compiles/Uploads
		scope:Computed(function(use)
			if use(no_upload) then
				return AutomaticIndividualLabeledSetting("ReplaceCompiles", 30)
			else
				return AutomaticIndividualLabeledSetting("ReplaceUploads", 30)
			end
		end),
		-- Upload To
		AutomaticIndividualLabeledSetting("CompileHost", 35),
		scope:Computed(function(use): Fusion.Child?
			if use(upload_to_gist) then
				return {
					AutomaticIndividualLabeledSetting("APIKey", 40),
					AutomaticIndividualLabeledSetting("UploadName", 41),
				}
				elseif use(upload_to_hastebin) then
					return AutomaticIndividualLabeledSetting("UploadExpireTime", 40)
			end
			return nil
		end),
		-- Divider
		scope:Divider {
			Thickness = 1,
			LayoutOrder = 45,
		},
		-- Compilation
		scope:TextBox {
			Text = "",
			PlaceholderText = "Compiled Model Code/Link",
			Label = {
				Text = "Compilation",
			},
			Layout = {
				LayoutOrder = 50,
			},
			onTextChange = function(text: string)
				decompilation_text = text
			end
		},
		-- Decompile
		scope:RippleButton {
			Label = "Decompile",
			Style = "Contained",
			BorderRadius = 4,
			OnPressed = function()
				Decompile(decompilation_text)
			end,
			Layout = {
				Size = UDim2.new(1, -6, 0, 32),
				LayoutOrder = 55,
			}
		},

		-- Bottom stuff
		scope:New "Frame" {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -10, 0, 16),
			Position = UDim2.new(0, 0, 1, 0),
			LayoutOrder = 1000,
			[Children] = {
				-- Advanced Settings
				scope:New "TextButton" {
					Text = "Advanced Settings",
					TextColor3 = THEME.COLORS.MainContrast,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(0.5, 1),
					AnchorPoint = Vector2.new(1, 1),
					Position = UDim2.fromScale(1, 1),
					Font = THEME.font,
					TextXAlignment = Enum.TextXAlignment.Right,
					TextScaled = true,
					[Fusion.OnEvent "Activated"] =  function()
						SettingsWidget.Enabled = not SettingsWidget.Enabled
					end
				},
				-- Reset Custom Materials
				scope:New "TextButton" {
					Text = "Reset Material Data",
					TextColor3 = THEME.COLORS.MainContrast,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(0.5, 1),
					AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.fromScale(0, 1),
					Font = THEME.font,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextScaled = true,
					[Fusion.OnEvent "Activated"] =  function()
						CustomMaterialsModule.Clear()
						Logger.print('SUCCESSFULLY RESET MATERIAL DATA')
					end
				}
			}
		}
	}
} :: ScrollingFrame


scope:Observer(PluginSettings.MalleabilityToggle):onChange(function()
	CheckTableMalleability(Selection:Get())
end)

scope:Observer(PluginSettings.OverlapToggle):onChange(function()
	CheckTableOverlap(Selection:Get())
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

	-- Try to migrate templates for the instance
	PerformGenericMigration("MigrateTemplates", function(part: BasePart)
		Compiler:TryMigrateTemplates(part)
	end)

	-- Try to migrate configurables for the instance
	PerformGenericMigration("MigrateConfigurables", function(part: BasePart)
		Compiler:MigrateConfigurables(part)
	end)

	PerformGenericMigration("CompatibilityMigration", function(part: BasePart)
		local replacement = CheckCompat(part.Name)
		if replacement then
			part.Name = replacement
		end
	end)
end

local function GetRequiredMaterialsButton()
	local raw_materials = {}
	local all_parts = {}
	local total_part_count = 0

	-- Increment the value of a key, defaults to 0 if the key doesn't exist
	local function Increment(t: {[string]: number}, name: string, amount: number)
		t[name] = (t[name] or 0) + amount
	end

	-- Gets part data from a part name
	local function GetData(part_name: string)
		return PartData["Parts"][part_name]
	end

	-- Gets the recipe for a part, returning nil if the part isn't craftable ingame
	local function GetRecipe(part_name: string): {[string]: number}?
		local part_data = GetData(part_name)
		if part_data.Craftable == false then
			return nil
		end
		return part_data.Recipe
	end

	local ingredient_stack = {}

	-- Count every selected part, inserting ones with recipes into `ingredient_stack`
	for _, part in WosSelection() do
		local name = part.Name
		Increment(all_parts, name, 1)
		total_part_count += 1
		if GetRecipe(name) then
			table.insert(ingredient_stack, name)	
		end
	end

	-- Perform a breadth first search to recursively find and count every raw ingredient
	while true do
		local pop = table.remove(ingredient_stack)
		if not pop then break end
		local part_data = PartData["Parts"][pop]
			
		for ingredient: string, amount: number in part_data.Recipe do
			if GetRecipe(ingredient) then
				table.insert(ingredient_stack, ingredient)
			else
				Increment(raw_materials, ingredient, amount)
			end
		end
	end

	Logger.print(`Calculated ingredients for {total_part_count} parts`)
	Logger.print("Raw Materials:\n", repr(raw_materials :: any, {pretty=true} :: any))
	Logger.print("All Parts:\n", repr(all_parts :: any, {pretty=true} :: any))
end

-- Eventually this will be removed when fusion is more pervasive
local ChildrenOfConfigList = {}

----==== Plugin Settings Widget ====----
local function SettingGroup(
	scope: Fusion.Scope<typeof(Fusion)>,
	props: {
		SortOrder: UsedAs<Enum.SortOrder>?,
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
				SortOrder = props.SortOrder or Enum.SortOrder.Name
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
					}
				}),

				scope:Divider {},

				-- Settings
				SettingGroup(scope, {
					SortOrder = Enum.SortOrder.LayoutOrder,
					[Children] = scope:ForPairs(PluginSettings, function(use, scope: typeof(scope), key, value)
						return key, scope:LabeledSetting {
							Setting = key,
							PluginSettingValues = PluginSettings,
							Layout = {
								LayoutOrder = PluginSettingsModule.Info[key].Index
							}
						}
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
							return key, scope:TextBox {
								Text = scope:Computed(function(use)
									return ExtractedUtil.Color3ToString_255(use(value))
								end),
								BoxPlaceholderText = scope:Computed(function(use)
									return `RGB Color ({ExtractedUtil.Color3ToString_255(use(value))})`
								end),
								onTextChange = function(text: string)
									local new_color = ExtractedUtil.StringToColor3_255(text)
									if new_color then
										value:set(new_color)
									end
								end,
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

local MICROCONTROLLER_SCRIPT_NAME = "MicrocontrollerCode"

-- On script change, update corresponding microcontroller Code value
ScriptEditorService.TextDocumentDidChange:Connect(function(document: ScriptDocument)
	local document_script = document:GetScript() :: LuaSourceContainer?
	-- Script can be nil if the edited document is the command bar
	if document_script == nil then return end
	if document_script.Name ~= MICROCONTROLLER_SCRIPT_NAME then return end
	if document_script.Parent == nil then return end
	local value = document_script.Parent :: StringValue
	if value.Name ~= "Code" then return end
	value.Value = document:GetText()
end)

--- Wrapper to update a script's source.
local function UpdateScript(script: LuaSourceContainer, new_value: string)
	ScriptEditorService:UpdateSourceAsync(script, function(_)
		return new_value
	end)
end

local SpecialMaterialValues =
	{
		["Filter"] = ConvertTextBoxInputToResource,
		["TempType"] = ConvertTextBoxInputToResource,
		["MaterialToExtract"] = ConvertTextBoxInputToResource,
		["LiquidToPump"] = ConvertTextBoxInputToResource,
		["Fluid"] = ConvertTextBoxInputToResource,
		["Assemble"] = ConvertTextBoxInputToResource,

		-- Gets called for every selected microcontroller's code value
		-- but TextBox is just a reference to the same element
		["Code"] = function(TextBox, ConfigValue: StringValue)
			-- Get microcontroller script, create if not exists
			local MicrocontrollerScript = ConfigValue:FindFirstChildWhichIsA("Script")
			if MicrocontrollerScript == nil then
				local new_script = Instance.new("Script")
				new_script.Name = MICROCONTROLLER_SCRIPT_NAME
				new_script.Parent = ConfigValue
				MicrocontrollerScript = new_script
			end
			assert(MicrocontrollerScript)

			-- Insert/update type checking if the setting is enabled
			if peek(PluginSettings.InsertPilotTypeChecker) and peek(PluginSettings.OpenMicrocontrollerScripts) then
				UpdatePilotTypes.UpdatePilotTypesIfNotDoneThisSession()
				ConfigValue.Value = UpdatePilotTypes.UpdateHeaderInString(ConfigValue.Value)
			end
			
			-- Make sure the script is up to date
			task.spawn(function()
				UpdateScript(MicrocontrollerScript, ConfigValue.Value)
			end)

			-- When the user clicks the text box, open a script
			local textbox_focused_event = TextBox.Box.Focused:Connect(function()
				if peek(PluginSettings.OpenMicrocontrollerScripts) then
					ScriptEditorService:OpenScriptDocumentAsync(MicrocontrollerScript)
				end
			end)

			-- When the text is edited, update every microcontroller
			local textbox_edited_event = TextBox.Box:GetPropertyChangedSignal("Text"):Connect(function()
				UpdateScript(MicrocontrollerScript, TextBox.Box.Text)
			end)

			TextBox.Box.Destroying:Once(function()
				textbox_focused_event:Disconnect()
				textbox_edited_event:Disconnect()
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

-- Check for an old instance that goes by a different name
local function CheckForConfigToPort(instance_to_configure: Instance, instance_key: string, config_name: string): any?
	local replacements = CompatibilityReplacements.COMPAT_CONFIG_NAME_REPLACEMENTS[instance_key]
	if not replacements then return end
	local config_replacements = replacements[config_name]
	if not config_replacements then return end
	for _, name in config_replacements do
		local old = instance_to_configure:FindFirstChild(name)
		if not old then continue end
		if not old:IsA("ValueBase") then
			Logger.warn(`Found instance that matches configuration value name porting but isn't a value instance`)
			continue
		end
		local value = (old :: ValueBase & {Value: any}).Value
		old:Destroy()
		return value
	end
	return
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
	local instance_key = CheckCompat(instance_to_configure.Name) or instance_to_configure.Name

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
		if config_type == "NumberRange" then
			return `{default_value[1]}:{default_value[2]}`
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

			local old_value = CheckForConfigToPort(instance_to_configure, instance_key, config_name)
			-- 
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
			elseif config_type == "Vector3" then
				GenericTextBox("0,0,0 [Vector3]")
			elseif config_type == "Vector2" then
				GenericTextBox("0,0 [Vector2]")
			elseif config_type == "NumberRange" then
				GenericTextBox("0:0 [NumberRange]")
			elseif config_type == "Coordinate" then
				GenericTextBox("0,0,0,0,bool [Coordinate]")
			elseif config_type == "number" then
				GenericTextBox(`{config_data.Default} [num/int]`)
			elseif config_type == "ResourceString" then
				GenericTextBox("Resource [ResourceString]")

			-- Color3 needs special handling because its stored as 0-1 in the Value
			-- but shown as 0-255 in GUI
			elseif config_type == "Color3" then
				local TextBox = GenericTextBox("0,0,0 [Color3]")
				local color = ExtractedUtil.StringToColor3_1(config_instance.Value)
				if color then
					TextBox.Box.Text = ExtractedUtil.Color3ToString_255(color)
				end

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

			elseif config_type == "Selection" then
				-- Dropdowns like apparel limb
				local TextBox = GenericTextBox("Option [string]")
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
		LabelText = "Type",
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

local Configs = {}
local ConfigsContainerFrame = scope:New "Frame" {
	Name = "Configurations",
	Size = UDim2.fromScale(1, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	[Children] = scope:New "UIListLayout" {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 1),
	},
}
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
		primaryConfigContainer.Parent = ConfigsContainerFrame
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

	local selected_part_cframe = scope:Value(CFrame.identity)
	local selected_part_size = scope:Value(Vector3.one)
	
	local cframe_signal
	local size_signal
	scope:Observer(selected_part):onBind(function()
		local part = peek(selected_part)
		if not part then return end
		if cframe_signal then
			cframe_signal:Disconnect()
		end
		if size_signal then
			size_signal:Disconnect()
		end
		cframe_signal = part:GetPropertyChangedSignal("CFrame"):Connect(function()
			selected_part_cframe:set(part.CFrame)
		end)
		size_signal = part:GetPropertyChangedSignal("Size"):Connect(function()
			selected_part_size:set(part.Size)
		end)
		selected_part_cframe:set(part.CFrame)
		selected_part_size:set(part.Size)
	end)

	--- CFrame of the local player's camera
	local camera_cframe = scope:Value(Camera.CFrame)
	table.insert(scope, Camera:GetPropertyChangedSignal("CFrame"):Connect(function()
		camera_cframe:set(Camera.CFrame)
	end))

	--- Computed cframe for the viewport frame camera
	local viewport_camera_cframe = scope:Computed(function(use)
		return use(camera_cframe).Rotation * CFrame.new(0, 0, 4 * use(selected_part_size).Magnitude)
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
		local part_cframe = use(selected_part_cframe)
		local cam_pos = use(viewport_camera_cframe).Position
		local closest_dist = math.huge
		local closest_face
		for _, face in FACES do
			local axis = part_cframe.Rotation:VectorToWorldSpace(Vector3.fromNormalId(face :: any))
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

	local face_selection_holder = scope:New "Frame" {
		Name = "FaceSelectionHolder",
		Size = UDim2.new(1, 0, 0, 120),
		Visible = scope:Computed(function(use)
			return use(PluginSettings.ShowSurfaceSelector) and use(selected_part) ~= nil
		end),
		BackgroundColor3 = THEME.COLORS.MainBackground,
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
						Size = selected_part_size,
						CFrame = scope:Computed(function(use)
							return use(selected_part_cframe).Rotation
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
						Size = scope:Computed(function(use)
							local axis = use(closest_face_axis):Abs()
							local axis_mask = (axis - Vector3.one):Abs()
							local plate_thickness = 0.05
							local shrink_amount = 0.1
							return (use(selected_part_size) - Vector3.one * shrink_amount) * axis_mask + axis * plate_thickness
						end),
						CFrame = scope:Computed(function(use)
							local selected_rotation = use(selected_part_cframe).Rotation
							local surface_pos = selected_rotation:VectorToWorldSpace(use(closest_face_axis) * use(selected_part_size) / 2)
							return CFrame.new(surface_pos) * selected_rotation
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

	table.insert(ChildrenOfConfigList, face_selection_holder)

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
ComponentSelectionHolder.Name = "ComponentInserter"
ComponentSelectionHolder.Size = UDim2.new(1, 0, 0, 50)
ComponentSelectionHolder.Visible = false
table.insert(ChildrenOfConfigList, ComponentSelectionHolder)
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

scope:ScrollingFrame {
	ScrollingDirection = "Y",
	ListPadding = UDim.new(0, 1),
	Parent = ConfigWidget,
	[Children] = {
		ChildrenOfConfigList :: Fusion.Child,
		ConfigsContainerFrame,
	}
}

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
	for _, part in WosSelection() do
		AddComponentToPart(part, componentName)
	end

	-- Update part selection GUI
	RefreshSelection()
end)

local function Adjust(Object)
	if Object:IsA("BasePart") then AddConfigItem(Object) end
	if peek(PluginSettings.VisualizeSpecial) and SpecialParts[Object.Name] then SpecialParts[Object.Name](Object) end
	if Object:FindFirstChild("ColorCopy") or Object:HasTag("ColorTexture") then
		ApplyColorCopy(Object)
		table.insert(TemporaryConnections, Object:GetPropertyChangedSignal("Color"):Connect(function()
			ApplyColorCopy(Object)
		end))
	end
end

function RefreshSelection()

	for i, v in pairs(TemporaryConnections) do
		if typeof(v) == "Instance" then
			v:Destroy()
			continue
		end
		v:Disconnect()
	end
	TemporaryConnections = {}

	for i, v in Configs do
		v:Destroy()
	end

	table.clear(ConfigValues)

	-- Do not do update stuff if plugin not open
	if not (ConfigWidget.Enabled or PrimaryWidget.Enabled) then
		return
	end

	local SelectedParts = WosSelection()

	CheckTableMalleability(SelectedParts)
	CheckTableOverlap(SelectedParts)

	for _, Selected in SelectedParts do
		Adjust(Selected)
	end

	-- Create the button and dropdown for adding components
	if #SelectedParts > 0 then
		UITemplates.CreateTipBoxes(ComponentSelectionTab.Box, CompilersModule:GetComponents())
		ComponentSelectionHolder.Visible = true
	else
		ComponentSelectionHolder.Visible = false
	end

	UpdateFaceSelectionViewport()
end

Selection.SelectionChanged:Connect(RefreshSelection)

UITemplates.SyncColors()
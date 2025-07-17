local plugin = _G.plugin
local Selection = game:GetService("Selection")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Dependencies
local CustomModules = script.Parent.Modules
local PseudoInstance = require(script.Parent.MBEPackages.PseudoInstance)
local Widgets = require(script.Parent.Widgets)
local ExtractedUtil = require(CustomModules.ExtractedUtil)
local Branding = require(Workspace.MBEE.MBEE.Modules.Branding)
local Constants = require(CustomModules.Constants)
local CustomMaterialsModule = require(CustomModules.CustomMaterials)
local CompilersModule = require(CustomModules.Compilers)
local Logger = require(CustomModules.Logger)
local InfoConstants = require(CustomModules.Settings)
local UITemplates, UIElements, Colors; do
	local m = require(CustomModules.UITemplates)
	UITemplates = m.UITemplates
	UIElements = m.UIElements
	Colors = m.Colors
end

-- vals
local PartsFolder = script.Parent.Parts
local AllParts = {} :: {BasePart}

-- gathered and returned to be put in thing as a list of fusion children
local children = {}

-- MARK: GUI
local SearchBoxHolder = Instance.new("Frame")
SearchBoxHolder.Size = UDim2.new(1, -6, 0, Widgets.PrimaryWidget.AbsoluteSize.Y - 248) -- UDim2.new(1, -6, 0, 30)
SearchBoxHolder.LayoutOrder = 5
table.insert(children, SearchBoxHolder)

local SearchBox = Instance.new("TextBox")
SearchBox.BorderSizePixel = 1
SearchBox.Size = UDim2.new(1, 0, 0, 16)
SearchBox.Text = ''
SearchBox.PlaceholderText = 'Search [Item/Category]'
SearchBox.Font = Enum.Font.SourceSansLight
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.TextScaled = true
SearchBox.Parent = SearchBoxHolder
table.insert(UIElements.Boxes, SearchBox)

local SearchMatches = Instance.new("TextLabel")
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

local ResultsFrame = Instance.new("ScrollingFrame")
ResultsFrame.Size = UDim2.new(1, 0, 1, -32)
ResultsFrame.CanvasSize = UDim2.fromScale(0, 0)
ResultsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ResultsFrame.AnchorPoint = Vector2.new(0, 0)
ResultsFrame.Position = UDim2.fromOffset(0, 16)
ResultsFrame.BorderSizePixel = 1
ResultsFrame.ScrollBarThickness = 6
ResultsFrame.Parent = SearchBoxHolder
table.insert(UIElements.Scrolls, ResultsFrame)

local ListLayout = Instance.new("UIListLayout", ResultsFrame)
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

-- MARK: Logic
do -- Create object buttons for normal wos parts
	local found_map = {}
	for _, Part in PartsFolder:GetChildren() do
		UITemplates.CreateObjectButton({Part = Part, Parent = ResultsFrame})
        table.insert(AllParts, Part)
		found_map[Part.Name] = true
	end

	if Constants.IS_LOCAL then
		for part_name, _ in CompilersModule:GetAllMalleability() do
            if found_map[part_name] then continue end
            Logger.warn(`Missing model for part {part_name}. Inserting placeholder.`)
            local Part = Instance.new("Part")
            Part.Color = BrickColor.Random().Color
            Part.Size = Vector3.one*2
            Part.Name = part_name
            Part.Anchored = true
            Part:AddTag("Placeholder")
            Part.Parent = PartsFolder
            table.insert(AllParts, Part)
            UITemplates.CreateObjectButton({Part = Part, Parent = ResultsFrame})
		end
	end
end

-- Create part button for each custom material
local MaterialsLoaded = pcall(function()
	for Name, Properties in CustomMaterialsModule.CustomMaterials do
		local NewMaterial = Instance.new("Part")
		NewMaterial.Anchored = true
		NewMaterial.Name = Name
		for Property, PropertyValue in Properties do
			if Property == "Color" then NewMaterial.Color = Color3.fromRGB(PropertyValue[1], PropertyValue[2], PropertyValue[3]); continue end
			if Property == "Size" then NewMaterial.Size = Vector3.new(PropertyValue[1], PropertyValue[2], PropertyValue[3]); continue end
			NewMaterial[Property] = PropertyValue
		end
		NewMaterial.Parent = PartsFolder
        table.insert(AllParts, NewMaterial)
		table.insert(InfoConstants.SearchCategories.resources, Name:lower())
		table.insert(InfoConstants.SearchCategories.templateables, Name:lower())
		UITemplates.CreateObjectButton({Part = NewMaterial, Deletable = true, Parent = ResultsFrame})
	end
end)

if not MaterialsLoaded then
	CustomMaterialsModule.Clear()
end

-------------
-------------
-------------
-------------
-------------
-------------

do
    local info = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    Widgets.PrimaryWidget:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        TweenService:Create(SearchBoxHolder, info, { Size = UDim2.new(1, 0, 0, Widgets.PrimaryWidget.AbsoluteSize.Y - 248) } ):Play()
    end)
end

local FocusSearch = plugin:CreatePluginAction(
    `{Branding.NAME_ABBREVIATION}FocusSearchQuery`,
    `[{Branding.NAME_ABBREVIATION}] Focus Search`,
    "Focuses on the search bar.",
    "",
    true
)

FocusSearch.Triggered:Connect(function()
	task.wait()
	SearchBox:CaptureFocus()
end)

UITemplates.ConnectBoxToAutocomplete(SearchBox, AllParts).Event:Connect(function(MatchedParts)
	if InfoConstants.SearchCategories[SearchBox.Text:lower()] then
		local CategoryItems = {}
		for _, Part in AllParts do
			for _, CategoryItem in InfoConstants.SearchCategories[SearchBox.Text:lower()] do
				if Part.Name:lower() ~= CategoryItem:lower() then continue end
				CategoryItems[Part.Name] = true
			end
		end

		if SearchBox.Text:lower() == "templates" then
			local TemplateMaterial = ExtractedUtil.MatchQueryToList(TemplateMaterial.Box.Text, AllParts)[1]
			if TemplateMaterial then
				CategoryItems[tostring(TemplateMaterial)] = true
			end
		end

		for _, SearchButton in ResultsFrame:GetChildren() do
            -- was GuiBase
			if not SearchButton:IsA("GuiObject") then continue end
			if not CategoryItems[SearchButton.Name] then
				SearchButton.Visible = false
				continue
			end
			SearchButton.Visible = true
		end

		return
	end

    if SearchBox.Text == "" then
		ListLayout.SortOrder = Enum.SortOrder.Name
		for _, SearchButton in ResultsFrame:GetChildren() do
			if not SearchButton:IsA("TextButton") then continue end
			SearchButton.Visible = true
		end
		return
	end

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
	for _, _Part in AllParts do
		if string.lower(_Part.Name) ~= MatchTo then continue end
		Part = _Part
	end

	if not Part then return end

	ListLayout.SortOrder = Enum.SortOrder.Name
	for i, SearchButton in ResultsFrame:GetChildren() do
		if not SearchButton:IsA("TextButton") then continue end
		SearchButton.Visible = true
	end

	SearchBox.Text, SearchMatches.Text, SearchMatches.Visible = "", "", false

	ExtractedUtil.SpawnPart(Part)
end)

AddMaterialButton.OnPressed:Connect(function()
	if #Selection:Get() <= 0 then
        Logger.warn('SELECT A PART TO TURN INTO A MATERIAL')
        return
    end
	if typeof(Selection:Get()[1]) ~= "Instance" then return end
	local Material = Selection:Get()[1]
	if not Material:IsA("BasePart") then return end

	for _, Resource in pairs(InfoConstants.SearchCategories.resources) do
		if Resource == Material.Name:lower() then
			Logger.warn(Material.Name:upper(), 'ALREADY EXISTS')
			return
		end
	end

	local NewMaterial = Material:Clone()
	NewMaterial.Parent = script.Parts

	CustomMaterialsModule.Add(NewMaterial.Name, {
		Material = NewMaterial.Material.Name,
		Transparency = NewMaterial.Transparency,
		Reflectance = NewMaterial.Reflectance,
		Color = {math.floor(NewMaterial.Color.R * 255), math.floor(NewMaterial.Color.G * 255), math.floor(NewMaterial.Color.B * 255)},
		Size = {NewMaterial.Size.X, NewMaterial.Size.Y, NewMaterial.Size.Z}
	})

	UITemplates.CreateObjectButton({Part = NewMaterial, Deletable = true, Parent = ResultsFrame})
	table.insert(InfoConstants.SearchCategories.resources, NewMaterial.Name:lower())
	table.insert(InfoConstants.SearchCategories.templateables, NewMaterial.Name:lower())
	warn('[MB:E:E] ' .. NewMaterial.Name:upper() .. ' WAS SUCCESSFULLY TURNED INTO A MATERIAL')
end)

return children
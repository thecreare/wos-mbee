local plugin = _G.plugin
local Selection = game:GetService("Selection")
local TweenService = game:GetService("TweenService")

-- Dependencies
local CustomModules = script.Parent.Modules
local PseudoInstance = require(script.Parent.MBEPackages.PseudoInstance)
local AllParts = require(script.Parent.Modules.AllParts)
local Branding = require(script.Parent.Modules.Branding)
local PluginSettings = require(script.Parent.Modules.PluginSettings)
local Widgets = require(script.Parent.Widgets)
local ExtractedUtil = require(CustomModules.ExtractedUtil)
local CustomMaterialsModule = require(CustomModules.CustomMaterials)
local Logger = require(CustomModules.Logger)
local InfoConstants = require(CustomModules.Settings)
local UITemplates, UIElements, Colors; do
	local m = require(CustomModules.UITemplates)
	UITemplates = m.UITemplates
	UIElements = m.UIElements
	Colors = m.Colors
end

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
-- Create object buttons for each part
for _, part in AllParts:GetPartsHash() do
	UITemplates.CreateObjectButton({
		Part = part.Instance,
		Deletable = part.IsCustom,
		Parent = ResultsFrame
	})
end

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

UITemplates.ConnectBoxToAutocomplete(SearchBox, AllParts:GetBasePartList()).Event:Connect(function(MatchedParts)
	local search_text = SearchBox.Text:lower()

	if InfoConstants.SearchCategories[search_text] then
		local CategoryItems = {}
		for _, part in AllParts:GetBasePartList() do
			for _, CategoryItem in InfoConstants.SearchCategories[search_text] do
				if part.Name:lower() ~= CategoryItem:lower() then continue end
				CategoryItems[part.Name] = true
			end
		end

		if search_text == "templates" then
			CategoryItems[PluginSettings.Get("TemplateMaterial")] = true
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

    if search_text == "" then
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
	for _, _Part in AllParts:GetBasePartList() do
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

local FACES = {"Top", "Bottom", "Left", "Right", "Front", "Back"}

AddMaterialButton.OnPressed:Connect(function()
	if #Selection:Get() <= 0 then
        Logger.warn('SELECT A PART TO TURN INTO A MATERIAL')
        return
    end
	if typeof(Selection:Get()[1]) ~= "Instance" then return end
	local selected_part = Selection:Get()[1]
	if not selected_part:IsA("BasePart") then return end

	for _, Resource in pairs(InfoConstants.SearchCategories.resources) do
		if Resource == selected_part.Name:lower() then
			Logger.warn(selected_part.Name:upper(), 'ALREADY EXISTS')
			return
		end
	end

	local properties = {
		Material = selected_part.Material.Name,
		Transparency = selected_part.Transparency,
		Reflectance = selected_part.Reflectance,
		Color = {math.floor(selected_part.Color.R * 255), math.floor(selected_part.Color.G * 255), math.floor(selected_part.Color.B * 255)},
		Size = {selected_part.Size.X, selected_part.Size.Y, selected_part.Size.Z}
	}

	-- Save surfaces
	for _, face in FACES do
		local surface_name = face .. "Surface"
		properties[surface_name] = (selected_part :: any)[surface_name]
	end

	local part = CustomMaterialsModule.Add(selected_part.Name, properties)

	UITemplates.CreateObjectButton({
		Part = part,
		Deletable = true,
		Parent = ResultsFrame
	})
	Logger.print('[MB:E:E] ' .. selected_part.Name:upper() .. ' WAS SUCCESSFULLY TURNED INTO A MATERIAL')
end)

return children
local plugin = _G.plugin
local TweenService = game:GetService("TweenService")

local PseudoInstance = require(script.Parent.Parent.MBEPackages.PseudoInstance)
local InfoConstants = require(script.Parent.Settings)
local ExtractedUtil = require(script.Parent.ExtractedUtil)
local CustomMaterials = require(script.Parent.CustomMaterials)
local Logger = require(script.Parent.Logger)
local Fusion = require(script.Parent.Parent.Packages.fusion)
local THEME = require(script.Parent.Parent.Theme)

local UITemplates = {}

-- TODO: This needs to be integrated into a real settings manager when I get around to that.
UITemplates.ScrollingText = plugin:GetSetting("ScrollingText") or true

-- MARK: Color Sync
local Colors = {
    MainBackground = ExtractedUtil.StringToColor3_255(plugin:GetSetting("MainBackgroundColor")) or settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
    MainText = ExtractedUtil.StringToColor3_255(plugin:GetSetting("MainTextColor")) or settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText),
    DimmedText = ExtractedUtil.StringToColor3_255(plugin:GetSetting("DimmedTextColor")) or settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.DimmedText),
    ScrollBarBackground = ExtractedUtil.StringToColor3_255(plugin:GetSetting("ScrollBarBackgroundColor")) or settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.ScrollBarBackground),
    ScrollBar = ExtractedUtil.StringToColor3_255(plugin:GetSetting("ScrollBarColor")) or settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.ScrollBar),
    InputFieldBackground = ExtractedUtil.StringToColor3_255(plugin:GetSetting("InputFieldBackgroundColor")) or settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
    Border = ExtractedUtil.StringToColor3_255(plugin:GetSetting("BorderColor")) or settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Border),
    MainContrast = ExtractedUtil.StringToColor3_255(plugin:GetSetting("MainContrastColor")) or Color3.fromRGB(255, 150, 50),
    ButtonHover = ExtractedUtil.StringToColor3_255(plugin:GetSetting("ButtonHoverColor")) or settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button),
    Button = ExtractedUtil.StringToColor3_255(plugin:GetSetting("ButtonColor")) or settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
    ButtonText = ExtractedUtil.StringToColor3_255(plugin:GetSetting("ButtonTextColor")) or settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.ButtonText),
    MainButton = ExtractedUtil.StringToColor3_255(plugin:GetSetting("MainButtonColor")) or settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton),
    MalleabilityCheck = ExtractedUtil.StringToColor3_255(plugin:GetSetting("MalleabilityCheckColor")) or Color3.fromRGB(255, 0, 0),
    OverlapCheck = ExtractedUtil.StringToColor3_255(plugin:GetSetting("OverlapCheckColor")) or Color3.fromRGB(255, 255, 0),
}

local UIElements = {
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
} :: {[string]: {any}}

function UITemplates.SyncColors(UIs: typeof(UIElements)?)
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
			if UITemplates.ScrollingText and Label.TextBounds.X >= Label.AbsoluteSize.X and not UIElements.Temporary[Label]["TextAnimator"] then
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
			if UITemplates.ScrollingText and ContrastLabel.TextBounds.X >= ContrastLabel.AbsoluteSize.X and not UIElements.Temporary[ContrastLabel]["TextAnimator"] then
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

-- MARK: Templates
-- Should not be used for new work, instead use scope:TextBox {}
function UITemplates.UITemplatesCreateTextBox(Settings: {[string]: any})
	if not Settings then warn("[MB:E:E] TEXTBOX MISSING SETTINGS.") return nil :: any end
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

-- Should not be used for new work, instead use scope:CheckBox {}
function UITemplates.CreateCheckBox(Settings: {[string]: any})
	if not Settings then
		Logger.error("CHECKBOX MISSING SETTINGS.")
	end

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

function UITemplates.CreateObjectButton(Settings: {[string]: any})
	if not Settings then Logger.error(`OBJECTBUTTON SETTINGS MISSING`) end
	if not Settings.Part then Logger.error(`OBJECTBUTTON PART MISSING`) end

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
		ExtractedUtil.SpawnPart(Settings.Part)
	end)

	UITemplates.SyncColors({TextButtons = {ResultHolder}, Labels = {ResultLabel}})

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
		UITemplates.SyncColors({Buttons = {DeleteButton}})

		DeleteButton.OnPressed:Connect(function()
            CustomMaterials.Remove(Settings.Part.Name)
			Settings.Part:Destroy()
			DeleteButton:Destroy()
			ResultHolder:Destroy()
		end)
	end
end

function UITemplates.ConnectBoxToAutocomplete(Box : TextBox, List : table)

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
		UITemplates.SyncColors({ContrastLabels = {BestMatchLabel}})
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

		local Matched = ExtractedUtil.MatchQueryToList(Box.Text, List)
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
function UITemplates.CreateTipBoxes(Gui, Table)
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
			UITemplates.SyncColors({TextButtons = {TipBox}})
			-- ahhhhhhhh FIXME
			TipBox.TextColor3 = Fusion.peek(THEME.COLORS.MainText)

			TipBox.Activated:Connect(function()
				Gui.Text = TipBox.Text
			end)

			TipBox.Parent = OptionsContainer

			table.insert(Temporary, TipBox)
			Count += 1
		end

		UITemplates.SyncColors({Scrolls = {OptionsContainer}})

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

return {
	UITemplates = UITemplates, 
	UIElements = UIElements, 
	Colors = Colors
}
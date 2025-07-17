local ExtractedUtil = require(script.Parent.ExtractedUtil)
local GetEnumNames = require(script.Parent.GetEnumNames)
local ConfigValues_G = require(script.Parent.Parent.ConfigValues_G)

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
return function(ItemIdentifier: string?, RootObject: BasePart, Value: ValueBase, ValueStatus: any)
	-- Get a list of objects that need to be configured
	local objects: {BasePart}
	if ItemIdentifier then
		objects = ConfigValues_G[ItemIdentifier]
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
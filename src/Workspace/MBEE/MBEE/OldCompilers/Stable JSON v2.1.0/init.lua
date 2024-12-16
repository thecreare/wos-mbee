local Compiler = {}
Compiler.DateAdded = "2022-02-28"
Compiler.Default = true -- selected by default

local Decompiler = require(script.Decompiler)

--local Malleability = require(script.Parent.Parent.Malleability)

local Round = false
local Offset = Vector3.new(0, -1, 0)
local TemplateDetection = false
local CompatibilityReplaceNames = true

local WARN_CODES = {}
WARN_CODES.SCRIPT_ERR = 1
WARN_CODES.BAD_SIZE = 2
WARN_CODES.BLANK_TEMPLATE = 3
WARN_CODES.MISSING_DATA = 4

local function round(Num,Step)
	if not Round then return Num end
	Step = Step or 0.001
	local Temp = Num/Step
	return (Temp == 0 and 0) or math.floor(math.abs(Temp) + 0.5)*Step*(Temp/math.abs(Temp))
end


local surfaceNames = {}
for i,v in pairs(Enum.NormalId:GetEnumItems()) do surfaceNames[i] = v.Name.."Surface" end
local surfaceTypes = {}
for i,v in pairs(Enum.SurfaceType:GetEnumItems()) do surfaceTypes[v] = i  end

local function getSurfaceData(part)
	local Vals = {}
	for _,Surface in pairs(surfaceNames) do
		Vals[#Vals + 1] = surfaceTypes[part[Surface]] or 6
	end
	local Surfaces = string.char(Vals[1] * 16 + Vals[2], Vals[3] * 16 + Vals[4], Vals[5] * 16 + Vals[6])
	return Surfaces
end

-- Convert number to hex
local function hex(x)
	if x < 10 then
		return string.char(x + 48)
	else
		return string.char(x + 55)
	end
end

-- Convert value (0-255) to hex
local function e(x)
	x = math.floor(x*255)
	return hex(math.floor(x/16))..hex(x%16)
end

-- no padding permitted, only encode in chunks of 3
local b64str = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local b64lookup = {}
for i = 0, 63 do
	local c = b64str:sub(i + 1, i + 1)
	b64lookup[i] = c
	b64lookup[c] = i
end
--local function b64encode(str)
--	local result = {}
--	for i = 1, #str, 3 do
--		local a, b, c = string.byte(str, i, i+2)

--		result[#result + 1] = table.concat({
--			b64lookup[bit32.band(0b11111100, a)/4],
--			b64lookup[bit32.band(0b00000011, a)*16 + bit32.band(0b11110000, b)/16],
--			b64lookup[bit32.band(0b00001111, b)*4 + bit32.band(0b11000000, c)/64],
--			b64lookup[bit32.band(0b00111111, c)]
--		}, "")
--	end
--	return table.concat(result, "")
--end

-- Improved base 64 encode
-- See this message in EggsD server: https://discord.com/channels/616089055532417036/823313507167502336/1133403859054772274
local function b64encode(str: string): string
	local result = table.create(#str * 4/3)
	local insertIndex = 1

	for i = 1, #str, 3 do
		local a, b, c = str:byte(i, i + 2)

		result[insertIndex] = b64lookup[bit32.band(0b11111100, a) / 4]
		result[insertIndex + 1] = b64lookup[bit32.band(0b00000011, a) * 16 + bit32.band(0b11110000, b) / 16]
		result[insertIndex + 2] = b64lookup[bit32.band(0b00001111, b) * 4 + bit32.band(0b11000000, c) / 64]
		result[insertIndex + 3] = b64lookup[bit32.band(0b00111111, c)]

		insertIndex += 4
	end

	return table.concat(result, "")
end

local TEMPLATE_EXCLUDE = {
	Wing = true;
}

local TEMPLATE_MESHES = {
	["rbxassetid://552212360"] = true;
	["rbxassetid://552211122"] = true;
}

local COMPAT_NAME_REPLACEMENTS = {
	SteeringSeat = "VehicleSeat";
	Aluminium = "Aluminum";
	SignalWire = "TriggerWire";
	Explosives = "Explosive";
	WheelTemplate = "Cylinder";
	CylinderTemplate = "Cylinder";
	WedgeTemplate = "Wedge";
	CornerTemplate = "CornerWedge";
	CornerTetraTemplate = "CornerTetra";
	TetrahedronTemplate = "Tetrahedron";
	BallTemplate = "Ball";
	DoorTemplate = "Door";
	BladeTemplate = "Blade";
	RoundTemplate = "RoundWedge";
	RoundTemplate2 = "RoundWedge2";
	CornerRoundTemplate = "CornerRoundWedge";
	CornerRoundTemplate2 = "CornerRoundWedge2";
	TrussTemplate = "Truss";
	Eridanium = "Iron";
	Abantium = "Iron";
	Lirvanite = "Iron";
	TouchTrigger = "TouchSensor";
	IonDrive = "Thruster";
	NeonBuildingPart = "Neon";
	SpotLight = "Spotlight";
	Airshield = "AirSupply";
	PsiSwitch = "WirelessButton";
}

local function getPartData(part, getIssues, Settings)
	if not part:IsA("BasePart") then return end
	if part.Name == "Terrain" or part.Name == "Baseplate" then return end

	local issue

	local partIsTemplate = part:FindFirstChild("TempType") ~= nil

	local pos = part.Position + Offset
	local name = part.Name
	local size = part.Size
	local vecX, vecY = part.CFrame.XVector, part.CFrame.YVector
	local color = part.Color
	
	print(script.Parent.Parent.Parts)
	
	local partsFolder = script.Parent.Parent.Parts or workspace:FindFirstChild("Parts") or game:GetService("ReplicatedStorage"):FindFirstChild("Parts")
	local partsFolderPart = partsFolder and partsFolder:FindFirstChild(name)

	if TemplateDetection then
		if part.Material == Enum.Material.Concrete and not partIsTemplate and not TEMPLATE_EXCLUDE[part.Name] then
			local TemplateName = part:IsA("CornerWedgePart") and "CornerWedgeTemplate"
				or part:IsA("WedgePart") and "WedgeTemplate"
				or (part:IsA("MeshPart") and TEMPLATE_MESHES[part.MeshId])
			if TemplateName then
				partIsTemplate = true
				--local val = Instance.new("StringValue")
				--val.Value = name
				--val.Name = "TempType"
				--val.Parent = part
				name = TemplateName
			end
		end
	end
	
	if CompatibilityReplaceNames and COMPAT_NAME_REPLACEMENTS[name] then
		name = COMPAT_NAME_REPLACEMENTS[name]
	end

	local data = {
		-- surface data here
		b64encode(string.pack("<ddddddddddddBBB",
			round(pos.X),round(pos.Y),round(pos.Z),
			vecX.X,vecX.Y,vecX.Z,
			vecY.X,vecY.Y,vecY.Z,
			round(size.X),round(size.Y),round(size.Z),
			math.floor(color.R * 255),math.floor(color.G * 255),math.floor(color.B * 255)
		)..getSurfaceData(part)); --getSurfaceData is another 3 chars
		name;
		-- template type
		-- configurables
	}
	if partIsTemplate then
		local templateMaterial = part.TempType.Value
		if CompatibilityReplaceNames and COMPAT_NAME_REPLACEMENTS[templateMaterial] then
			templateMaterial = COMPAT_NAME_REPLACEMENTS[templateMaterial]
		end
		table.insert(data,templateMaterial)
	end
	
	local Configs = nil
	for i,v in pairs(part:GetChildren()) do
		if v:IsA("ValueBase") and v.Name ~= "TempType" then
			if not Configs then
				Configs = {}
				table.insert(data, Configs)
			end
			if part.Name == "Microcontroller" and Settings["UploadMethod"] and Settings["UploadMethod"] == "gist" then
				Configs[v.Name] = tostring(v.Value):gsub('\\"', '\\\\"'):gsub('"', '\\"'):gsub("\n", "\\n")
			else
				Configs[v.Name] = tostring(v.Value)
			end
		end
	end

	return data
end

Compiler.Selected = false
Compiler.WARN_CODES = WARN_CODES

function Compiler.Compile(Parts, Settings)
	if Settings.Round ~= nil then
		Round = Settings.Round
	end

	if Settings.Offset ~= nil then
		Offset = Settings.Offset
	end

	local result = {}

	for i = 0, math.ceil(#Parts / 150) - 1 do
		local PartOffset = 150 * i
		for i = 1 + PartOffset, 150 + PartOffset do
			coroutine.resume(coroutine.create(function()
				if not Parts[i] then return end
				local success, data, issue, err = pcall(getPartData, Parts[i], false, Settings)
				if success then
					table.insert(result, data)
				else
					warn(err)
				end
			end))
		end
	end

	repeat task.wait() until #result >= #Parts
	
	return game:GetService("HttpService"):JSONEncode(result)
end

function Compiler.GetPartData(part, getIssues)
	return pcall(getPartData, part, getIssues, {})
end

function Compiler.Decompile(CF, Data)
	return Decompiler(CF, Data)
end

return Compiler

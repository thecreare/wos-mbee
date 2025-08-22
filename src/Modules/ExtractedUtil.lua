local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")

local AllParts = require(script.Parent.AllParts)
local Branding = require(script.Parent.Branding)
local Logger = require(script.Parent.Logger)
local CompilersModule = require(script.Parent.Compilers)
local Fusion = require(script.Parent.Parent.Packages.fusion)
local PluginSettings = require(script.Parent.PluginSettings)

local peek = Fusion.peek
local PARTS = script.Parent.Parent.Parts

local ExtractedUtil = {}

--https://devforum.roblox.com/t/how-does-roblox-calculate-the-bounding-boxes-on-models-getextentssize/216581/8
function ExtractedUtil.GetBoundingBox(model, orientation)
	if typeof(model) == "Instance" then
		model = model:GetDescendants()
	end
	if not orientation then
		orientation = CFrame.new()
	end
	local abs = math.abs
	local inf = math.huge

	local minx, miny, minz = inf, inf, inf
	local maxx, maxy, maxz = -inf, -inf, -inf

	for _, obj in pairs(model) do
		if obj:IsA("BasePart") then
			local cf = obj.CFrame
			cf = orientation:toObjectSpace(cf)
			local size = obj.Size
			local sx, sy, sz = size.X, size.Y, size.Z

			local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:components()

			local wsx = 0.5 * (abs(R00) * sx + abs(R01) * sy + abs(R02) * sz)
			local wsy = 0.5 * (abs(R10) * sx + abs(R11) * sy + abs(R12) * sz)
			local wsz = 0.5 * (abs(R20) * sx + abs(R21) * sy + abs(R22) * sz)

			if minx > x - wsx then
				minx = x - wsx
			end
			if miny > y - wsy then
				miny = y - wsy
			end
			if minz > z - wsz then
				minz = z - wsz
			end

			if maxx < x + wsx then
				maxx = x + wsx
			end
			if maxy < y + wsy then
				maxy = y + wsy
			end
			if maxz < z + wsz then
				maxz = z + wsz
			end
		end
	end

	local omin, omax = Vector3.new(minx, miny, minz), Vector3.new(maxx, maxy, maxz)
	local omiddle = (omax+omin)/2
	local wCf = orientation - orientation.p + orientation:pointToWorldSpace(omiddle)
	local size = (omax-omin)
	return wCf, size
end

-- History and stuff
function ExtractedUtil.HistoricEvent(name: string, display_name: string?, callback: ()->(), ...:any): (boolean, string?)
	name = Branding.NAME_ABBREVIATION .. name
	display_name = Branding.NAME_ABBREVIATION .. " " .. (display_name or name)

	local recordingId = ChangeHistoryService:TryBeginRecording(name, display_name)

	local success, err = pcall(callback, ...)

	if recordingId then
		local operation = if success then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel
		ChangeHistoryService:FinishRecording(recordingId, operation)
	else
		Logger.warn(`Failed to generate recordingId for {name}`)
	end

	if not success then
		Logger.error(`{name} failed with error: {err}`)
	end

	return success, err
end

function ExtractedUtil.BindToEventWithUndo(event: RBXScriptSignal, name: string, display_name: string?, callback: (...any)->())
	event:Connect(function(...)
		ExtractedUtil.HistoricEvent(name, display_name, callback, ...)
	end)
end

-- Misc things
-- ExtractedUtil
function ExtractedUtil.RoundPos(part)
	part.Position = Vector3.new(math.floor(part.Position.X), math.floor(part.Position.Y), math.floor(part.Position.Z))
end

function ExtractedUtil.GetTableLength(Table)
	local Total = 0
	for _, _ in Table do
		Total += 1
	end
	return Total
end

function ExtractedUtil.SearchTableWithRecursion(Table, ComparsionFunction)
	local Finds = {}
	for _, Element in Table do
		local Result = ComparsionFunction(Element)

		if Result == true then
			table.insert(Finds, Element)
		elseif typeof(Result) == 'table' then
			for _, v in ExtractedUtil.SearchTableWithRecursion(Result, ComparsionFunction) do
				table.insert(Finds, v)
			end
		end
	end
	return Finds
end

function ExtractedUtil.AverageVector3s(v3s)
	local sum = Vector3.new()
	for _,v3 in pairs(v3s) do
		sum = sum + v3
	end
	return sum / #v3s
end

type MalleabilityValue = number|Vector3|{MalleabilityValue}
function ExtractedUtil.CheckMalleabilityValue(Part: BasePart, Value: MalleabilityValue)
	if typeof(Value) == "number" then
		return Part.Size.X * Part.Size.Y * Part.Size.Z <= Value
	end

	if typeof(Value) == "Vector3" then
		return Part.Size == Value
	end

	if typeof(Value) == "table" then
		for _, _Value in Value do
			if ExtractedUtil.CheckMalleabilityValue(Part, _Value) then return true end
		end
		return false
	end
	error(`Invalid malleability value type: {typeof(Value)}`)
end

function ExtractedUtil.MatchQueryToList(Query, List)
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

function ExtractedUtil.ApplyTemplates(List: {BasePart}, Material: string?)
	for _, Part: BasePart in ExtractedUtil.SearchTableWithRecursion(List, function(Element) return typeof(Element) == "Instance" and Element:IsA("BasePart") or typeof(Element) == "table" and Element or Element:GetChildren() end) do
		-- Remove material gui things
		for _, child in Part:GetChildren() do
			if child:IsA("Decal") or child:IsA("Texture") then
				child:Destroy()
			end
		end

		-- Reset Part to default template
		if Material == nil then
			Part.Material = Enum.Material.Concrete
			Part.Transparency = 0
			Part.Reflectance = 0
			Part.Name = CompilersModule:GetPartMetadata():GetShape(Part) -- TODO: This will error on part of shape Block
			continue
		end

		local TemplatePart = PARTS:FindFirstChild(tostring(Material))
		if not TemplatePart then continue end
		if not ExtractedUtil.IsResource(TemplatePart) then continue end -- So you don't set a resource to Hyperdrive or something

		Part.Material = TemplatePart.Material
		Part.Transparency = TemplatePart.Transparency
		Part.Reflectance = TemplatePart.Reflectance
		Part.Name = TemplatePart.Name

		for _, child in TemplatePart:GetChildren() do
			if child:IsA("Decal") or child:IsA("Texture") then
				child:Clone().Parent = Part
			end
		end
	end
end

function ExtractedUtil.GetInsertPoint(distance: number, shift_up: number?)
	local cam_cf = workspace.CurrentCamera.CFrame
	local direction = cam_cf.LookVector * distance
	local hit = workspace:Raycast(cam_cf.Position, direction)
	local hit_point = if hit then hit.Position else cam_cf.Position + direction
	return (hit_point + Vector3.yAxis * (shift_up or 0)):Floor()
end

function ExtractedUtil.SpawnPart(Part: BasePart): BasePart?
	local new_part

	ExtractedUtil.HistoricEvent("InsertPart", "Insert Part", function()
		new_part = Part:Clone()
		local distance = (new_part.Size.X + new_part.Size.Y + new_part.Size.Z) / 3 * 1.5 + 10
		new_part.Position = ExtractedUtil.GetInsertPoint(distance, new_part.Size.Y / 2)
		ExtractedUtil.RoundPos(new_part)

		new_part.Parent = workspace

		if PluginSettings.Get("SelectSpawnedPart") then
			Selection:Set({new_part})
		end

		if ExtractedUtil.IsSpecialTemplate(new_part) then
			local query = peek(PluginSettings.Values.TemplateMaterial)
			if query == "" or query == nil then return new_part end
			local Matched = ExtractedUtil.MatchQueryToList(query, PARTS:GetChildren())
			if not Matched then return new_part end
			if not Matched[1] then return new_part end
			if #Matched > 32 then return new_part end
			ExtractedUtil.ApplyTemplates({new_part}, Matched[1])
			new_part.Color = Matched[1].Color
		end
	end)

	return new_part
end

function ExtractedUtil.StringToColor3_255(str): Color3?
	if not str then return end
	local channels = str:gsub("[^0-9,]", ""):split(",")
	return if #channels == 3 then Color3.fromRGB(
		tonumber(channels[1]),
		tonumber(channels[2]),
		tonumber(channels[3])
	) else nil
end

function ExtractedUtil.StringToColor3_1(str): Color3?
	if not str then return end
	local channels = str:gsub("[^0-9,.]", ""):split(",")
	return if #channels == 3 then Color3.new(
		tonumber(channels[1]),
		tonumber(channels[2]),
		tonumber(channels[3])
	) else nil
end

function ExtractedUtil.Color3ToString_255(color: Color3): string
	local R = math.round(color.R * 255)
	local G = math.round(color.G * 255)
	local B = math.round(color.B * 255)
	return table.concat({R,G,B}, ", ")
end

function ExtractedUtil.Color3ToString_1(color: Color3): string
	local R = color.R
	local G = color.G
	local B = color.B
	return table.concat({R,G,B}, ", ")
end

-- Ported from https://stackoverflow.com/questions/1855884/determine-font-color-based-on-background-color
function ExtractedUtil.ContrastColor(color: Color3): Color3 
    -- Counting the perceptive luminance - human eye favors green color...
    local luminance = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B;

    if luminance > 0.5 then
       return Color3.new(0, 0, 0) -- bright colors - black font
    else
		return Color3.new(1, 1, 1) -- dark colors - white font
	end
end

-- Gets the volume of the given BasePart
function ExtractedUtil.GetVolume(part: BasePart): number
	return part.Size.X * part.Size.Y * part.Size.Z
end

-- Returns if given part can be used as a template material (aka set as the Resource for something like Wedge)
function ExtractedUtil.IsResource(part: BasePart): boolean
	-- As far as I'm aware every part that can be resized can be used as a template shape
	return typeof(CompilersModule:GetSelectedCompiler():GetMalleability(part.Name)) == "number"
	-- And until custom parts have malleability support they need to be manually OK-ed here
		or AllParts:IsCustom(part.Name)
end

-- Returns if a given part is a shaped part like wedge (returns false for block)
function ExtractedUtil.IsSpecialTemplate(part: BasePart): boolean
	return CompilersModule:GetPartMetadata():GetShape(part) ~= nil
end
-- Returns if given part should have a Resource config (note: the IsResource() call is to allow you to change the resource of Blocks)
function ExtractedUtil.IsTemplate(part: BasePart): boolean
	local shape = CompilersModule:GetPartMetadata():GetShape(part)
	return shape
		or ExtractedUtil.IsResource(part)
		-- Edge case for the literal "Block" template part
		or part.Name == "Block"
end

return ExtractedUtil
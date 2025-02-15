local ChangeHistoryService = game:GetService("ChangeHistoryService")

local Logger = require(script.Parent.Logger)
local CompilersModule = require(script.Parent.Compilers)

local PARTS = script.Parent.Parent.Parts

local ExtractedUtil = {}

--[[
Due to still being in the process of refactoring things there are
some global things that I can't yet untangle.

This table just serves as a way for the main script to push data into this module.
List of things that get put in:
- `TemplateMaterial` This is the text box below the part menu that controls what template material
	to use when spawning a template

]]
ExtractedUtil.StupidGlobals = {}

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
	name = "MBEE" .. name
	display_name = "MBEE " .. (display_name or name)

	local recordingId = ChangeHistoryService:TryBeginRecording(name, display_name)

	local success, err = pcall(callback, ...)

	local operation = if success then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel
	ChangeHistoryService:FinishRecording(recordingId, operation)

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

function ExtractedUtil.CheckMalleabilityValue(Part, Value)
	if typeof(Value) == "number" then
		return (math.ceil(Part.Size.X) * math.ceil(Part.Size.Y) * math.ceil(Part.Size.Z)) <= Value
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

function ExtractedUtil.ApplyTemplates(List, Material)
	for _, Part in ExtractedUtil.SearchTableWithRecursion(List, function(Element) return typeof(Element) == "Instance" and Element:IsA("BasePart") or typeof(Element) == "table" and Element or Element:GetChildren() end) do
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
	end
end

function ExtractedUtil.SpawnPart(Part): Model?
	local SelectedPart

	ExtractedUtil.HistoricEvent("InsertPart", "Insert Part", function()
		SelectedPart = Part:IsA("BasePart") and Part:Clone() or ExtractedUtil.MatchQueryToList(tostring(Part), PARTS:GetChildren())
		if not SelectedPart then return end
		local cam_cf = workspace.CurrentCamera.CFrame
		local RayResult = workspace:Raycast(cam_cf.Position, cam_cf.LookVector * ((SelectedPart.Size.X + SelectedPart.Size.Y + SelectedPart.Size.Z) / 3 * 1.5 + 10))
		SelectedPart.Position = RayResult and RayResult.Position and Vector3.new(RayResult.Position.X, RayResult.Position.Y + SelectedPart.Size.Y / 2, RayResult.Position.Z) or cam_cf.Position + cam_cf.LookVector * 12
		ExtractedUtil.RoundPos(SelectedPart)

		SelectedPart.Parent = workspace

		if ExtractedUtil.IsSpecialTemplate(SelectedPart) then
			local query = ExtractedUtil.StupidGlobals.TemplateMaterial.Box.Text
			if query == "" or query == nil then return SelectedPart end
			local Matched = ExtractedUtil.MatchQueryToList(query, PARTS:GetChildren())
			if not Matched then return SelectedPart end
			if not Matched[1] then return SelectedPart end
			if #Matched > 32 then return SelectedPart end
			ExtractedUtil.ApplyTemplates({SelectedPart}, Matched[1])
			SelectedPart.Color = Matched[1].Color
		end
	end)

	return SelectedPart
end

function ExtractedUtil.StringToColor3(str)
	if not str then return end
	local newStr = string.gsub(str, "%s", "")
	local Vals = string.split(newStr, ",")
	return #Vals >= 3 and Color3.fromRGB(unpack(Vals)) or Color3.new(1,1,1)
end



-- Gets the volume of the given BasePart
function ExtractedUtil.GetVolume(part: BasePart): number
	return part.Size.X * part.Size.Y * part.Size.Z
end

-- Returns if given part can be used as a template material (aka set as the Resource for something like Wedge)
function ExtractedUtil.IsResource(part: BasePart): boolean
	-- As far as I'm aware every part that can be resized can be used as a template shape
	return typeof(CompilersModule:GetSelectedCompiler():GetMalleability(part.Name)) == "number"
end

-- Returns if a given part is a shaped part like wedge (returns false for block)
function ExtractedUtil.IsSpecialTemplate(part: BasePart): boolean
	return CompilersModule:GetPartMetadata():GetShape(part) ~= nil
end
-- Returns if given part should have a Resource config (note: the IsResource() call is to allow you to change the resource of Blocks)
function ExtractedUtil.IsTemplate(part: BasePart): boolean
	local shape = CompilersModule:GetPartMetadata():GetShape(part)
	return shape or ExtractedUtil.IsResource(part)
end

return ExtractedUtil
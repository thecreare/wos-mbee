local OBJECTS_FOLDER = script.Parent.Parent.Parent.Parts

local b64str = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local b64lookup = {}
for i = 0, 63 do
	local c = b64str:sub(i + 1, i + 1)
	b64lookup[i] = c
	b64lookup[c] = i
end
b64decode = function(str)
	local result = {}
	for i = 1, #str, 4 do
		local a, b, c, d = b64lookup[str:sub(i, i)], b64lookup[str:sub(i+1, i+1)], b64lookup[str:sub(i+2, i+2)], b64lookup[str:sub(i+3, i+3)]

		result[#result + 1] = string.char(
			a*4 + bit32.band(0b00110000, b)/16,
			bit32.band(0b00001111, b)*16 + bit32.band(0b00111100, c)/4,
			bit32.band(0b00000011, c)*64 + d
		)
	end
	return table.concat(result, "")
end

local NormalIdNames = {}
NormalIdLookup = {}
local SurfaceNames = {}
for i,v in pairs(Enum.NormalId:GetEnumItems()) do
	SurfaceNames[i] = v.Name.."Surface"
	NormalIdNames[i] = v.Name
	NormalIdNames[v.Name] = i
	NormalIdLookup[v] = i
	NormalIdLookup[i] = v
end

-- Convert Enum.SurfaceType into a dictionary with string keys to get the surface enum out
-- This is ~10x faster than calling tonumber() at runtime to index Enum.SurfaceType directly
SurfaceTypes = {}
for i,v in pairs(Enum.SurfaceType:GetEnumItems()) do SurfaceTypes[tostring(i)] = v SurfaceTypes[i] = v  end

LoadSurfaces = function(Part, Surfaces)
	if Surfaces then
		local Val1, Val2, Val3 = string.byte(string.sub(Surfaces, 1, 1)), string.byte(string.sub(Surfaces, 2, 2)), string.byte(string.sub(Surfaces, 3, 3))
		Part[SurfaceNames[1]] = SurfaceTypes[math.floor(Val1 / 16 + 0.01)]
		Part[SurfaceNames[2]] = SurfaceTypes[Val1 % 16]

		Part[SurfaceNames[3]] = SurfaceTypes[math.floor(Val2 / 16 + 0.01)]
		Part[SurfaceNames[4]] = SurfaceTypes[Val2 % 16]

		Part[SurfaceNames[5]] = SurfaceTypes[math.floor(Val3 / 16 + 0.01)]
		Part[SurfaceNames[6]] = SurfaceTypes[Val3 % 16]
	end
end

return function(CF, Data)
	local Parts = game:GetService("HttpService"):JSONDecode(Data)
	local CreatedPartsList = {}
	for i, PartData in pairs(Parts) do
		local x, d = pcall(function()
			--Format string containing most of the part data
			local pX, pY, pZ, r1, r2, r3, r4, r5, r6, sX, sY, sZ, r, g, b, s1, s2, s3 = string.unpack("<ddddddddddddBBBBBB", b64decode(PartData[1]))

			local RelativeCF = CFrame.fromMatrix(Vector3.new(pX, pY, pZ), Vector3.new(r1, r2, r3), Vector3.new(r4, r5, r6))
			local PartName = PartData[2]

			local function sizeCorrect(num) return math.clamp(tonumber(num), 0.05, 2048) end
			local Size = Vector3.new(sizeCorrect(sX),sizeCorrect(sY),sizeCorrect(sZ))
			local Color = Color3.fromRGB(r, g, b)
			local PlayerWhoLocked = nil;
			
			--Create the part
			local Part = OBJECTS_FOLDER:FindFirstChild(PartName)
			if Part then Part = Part:Clone() else return end

			local PropertiesIndex = 3
			if type(PartData[PropertiesIndex]) == "string" then
				local Data = PartData[PropertiesIndex]
				if Part:FindFirstChild("TempType") ~= nil then
					Part.TempType.Value = Data
				end
				PropertiesIndex = PropertiesIndex + 1
			end

			xpcall(function()
				local ValueClassLookup = {
					boolean = "BoolValue";
					string = "StringValue";
					number = "NumberValue";
				}
				for PropName, PropVal in pairs(PartData[PropertiesIndex] or {}) do
					local Special = {["true"] = true; ["false"] = false;}
					local ValObj = Part:FindFirstChild(PropName)
					local EvaluatedValue = (PropVal and (Special[PropVal:lower()] or tonumber(PropVal) or PropVal)) or tonumber(Data) or Data
					if not ValObj then
						if PropName:sub(1,1) == "_" then -- underscore configs are special
							ValObj = Instance.new(ValueClassLookup[typeof(EvaluatedValue)])
							ValObj.Name = PropName
							ValObj.Parent = Part
						else
							local ActionTaken = "was not loaded."
							for _, existingVal in pairs(Part:GetChildren()) do
								if not PartData[PropertiesIndex][existingVal.Name] and ValueClassLookup[typeof(EvaluatedValue)] == existingVal.ClassName then
									ValObj = existingVal
									ActionTaken = "was loaded into "..existingVal.Name
									break
								end
							end

							warn("Config property "..PropName.." of "..PartName.." may be outdated and "..ActionTaken.."\nValue: "..tostring(PropVal))
						end
					end
					if ValObj then
						ValObj.Value = EvaluatedValue
					end	
				end
			end, function(err)
				warn("Decompiler error configuring "..PartName..":\n"..err.."\n"..debug.traceback())
			end)

			if Part:IsA("Tool") then return end

			Part.CFrame = CF*RelativeCF
			local Mesh = Part:FindFirstChildWhichIsA("SpecialMesh")
			if Mesh and Mesh.MeshType == Enum.MeshType.FileMesh then
				Mesh.Scale = Mesh.Scale * Size/Part.Size
			end
			Part.Size = Size
			Part.Color = Color

			LoadSurfaces(Part, string.char(s1, s2, s3))

			table.insert(CreatedPartsList, Part)
		end)
		if not x then warn("Model Loader error:", d) end
	end
	return CreatedPartsList
end
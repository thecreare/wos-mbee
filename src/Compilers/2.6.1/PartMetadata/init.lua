--[[PB]]--[[
This file was automatically modified by tools/compiler_patcher.py
2025-01-03
]]
--[[PE]]

--!strict
local HttpService = game:GetService("HttpService")

local Compression = require(script.Compression)
local Refcoder = require(script.Refcoder)
local compress, decompress = Compression.CompressZlib, Compression.DecompressZlib
local b64encode, b64decode = unpack(require(script.Base64))

local ConfigData = require(script.ConfigData)
local Joints = require(script.Joints)

export type ConfigurableTypes = "number" | "boolean" | "string" | "ResourceString" | "Vector3" | "Color3" | "Vector2" | "Selection" | "Coordinate" | "NumberRange"

export type ConfigValue = {
	Name: string;
	Type: ConfigurableTypes;
	Default: any;
	Options: any?;
	Description: string?;
}

local PartMetadata = {}

function PartMetadata:SaveString(data)
	return b64encode(compress(data))
end
function PartMetadata:LoadString(data)
	return decompress(b64decode(data))
end

function PartMetadata:SaveData(data)
	return buffer.fromstring(Refcoder.encode(data))
end
function PartMetadata:LoadData(data)
	return Refcoder.decode(buffer.tostring(data))
end

function PartMetadata:MigrateModelToBuffer(modelCode: (string | buffer)?): buffer?
	if type(modelCode) == "buffer" or type(modelCode) == "nil" then
		return modelCode
	end

	if type(modelCode) == "string" then
		if modelCode == "" or modelCode == "NO_DATA" then
			modelCode = nil
		else
			-- Try to decode the model data as JSON
			if string.sub(modelCode, 1, 1) == "{" then
				pcall(function()
					modelCode = HttpService:JSONDecode(modelCode)
				end)

				if type(modelCode) == "buffer" then
					return modelCode
				end
			end

			-- Try to convert the model to a string
			if type(modelCode) == "string" then
				modelCode = buffer.fromstring(PartMetadata:LoadString(modelCode))
			end
		end
	end

	assert(type(modelCode) == "buffer", "Invalid model code.")

	return modelCode
end

-- Constants
local OBJECT_ASSETS_FOLDER = script:WaitForChild("ObjectsFolder")
local OBJECT_ASSETS = OBJECT_ASSETS_FOLDER:GetChildren()
local SHAPE_ASSETS_FOLDER = script.Parent:WaitForChild("Shapes")
local SHAPE_ASSETS = SHAPE_ASSETS_FOLDER:GetChildren()
local SHAPE_ENUM = table.create(#SHAPE_ASSETS)

local SHAPE_NAMES_BY_PART_TYPE = {
	[Enum.PartType.Block] = "Block",
	[Enum.PartType.Ball] = "Ball",
	[Enum.PartType.Cylinder] = "Cylinder",
	[Enum.PartType.Wedge] = "Wedge",
	[Enum.PartType.CornerWedge] = "CornerWedge",
}

-- Assign constants
PartMetadata.OBJECT_ASSETS_FOLDER = OBJECT_ASSETS_FOLDER
PartMetadata.OBJECT_ASSETS = OBJECT_ASSETS
PartMetadata.SHAPE_ENUM = SHAPE_ENUM
PartMetadata.SHAPE_ASSETS_FOLDER = SHAPE_ASSETS_FOLDER
PartMetadata.SHAPE_ASSETS = SHAPE_ASSETS

-- Extract shape names & meshes
local shapesByMeshId = {}
for _, shapePart in ipairs(SHAPE_ASSETS) do
	table.insert(SHAPE_ENUM, shapePart.Name)
	if shapePart:IsA("MeshPart") then
		shapesByMeshId[shapePart.MeshId] = shapePart.Name
	end
end

function PartMetadata:GetShape(part: BasePart): string?
	local mesh = part:FindFirstChildWhichIsA("SpecialMesh")
	if mesh and mesh.MeshType == Enum.MeshType.Sphere then
		return "Spheroid"
	--[[PB]]elseif mesh and mesh.MeshType == Enum.MeshType.Brick then
		return "nil"
	--[[PE]]--[[PB]]elseif mesh and mesh.MeshType == Enum.MeshType.Wedge then
		return "Wedge"
	--[[PE]]--[[PB]]elseif mesh and mesh.MeshType == Enum.MeshType.Cylinder then
		return "Cylinder"
	--[[PE]]--[[PB]]elseif mesh and shapesByMeshId[mesh.MeshId] then
		return shapesByMeshId[mesh.MeshId]
	--[[PE]]--[[PB]]elseif mesh and mesh.MeshId == "http://www.roblox.com/asset/?id=11294911" then
		return "CornerWedge"
	--[[PE]]elseif part:IsA("Part") then
		local shape = part.Shape

		-- If the part is a block, return nil
		if shape == Enum.PartType.Block then
			return nil
		end

		-- Return the shape name by the part type
		return SHAPE_NAMES_BY_PART_TYPE[shape]
	elseif part:IsA("WedgePart") then
		return "Wedge"
	elseif part:IsA("CornerWedgePart") then
		return "CornerWedge"
	elseif part:IsA("TrussPart") then
		return "Truss"
	elseif part:IsA("MeshPart") then
		return shapesByMeshId[part.MeshId]
	end
	return nil
end

-- Configurable getter
function PartMetadata:GetConfigurables(instance: Instance): { [string]: any }
	local configurables = instance:GetAttributes()
	-- Copy values from ValueBase objects
	for _, child in ipairs(instance:GetChildren()) do
		if not child:IsA("ValueBase") then
			continue
		end
		local name = child.Name
		if configurables[name] ~= nil then
			continue
		end
		if name ~= "TempType" then
			configurables[name] = (child :: any).Value
		end
	end
	return configurables
end

-- Component getter
function PartMetadata:GetComponents(instance: Instance): { [string]: unknown }
	local components = {}

	for _, child in instance:GetChildren() do
		if not child:IsA("Configuration") then
			continue
		end

		local configData = ConfigData.Components[child.Name]
		local configurables = PartMetadata:GetConfigurables(child)

		local compressedConfigurables = if configData then PartMetadata:CompressConfigurables(configurables, configData) else configurables

		components[child.Name] = { compressedConfigurables }
	end

	return components
end

local function getConfigIndices(configData: { ConfigValue }): { [string]: number }
	local configIndices = {}

	for configIndex, configInfo in configData do
		configIndices[configInfo.Name] = configIndex
	end

	return configIndices
end

--- Takes a dictionary of configurables & a list of config info and replaces the config indices with their numeric versions
function PartMetadata:CompressConfigurables(configurables: { [string]: any }, configData: { ConfigValue })
	local compressedValues: { [string | number]: any } = table.clone(configurables)

	-- Get the config indices
	local configIndices = getConfigIndices(configData)

	-- Collect all compressed values in order
	for configName, configValue in configurables do
		-- Skip non-named config indices
		if type(configName) ~= "string" then
			continue
		end

		-- Grab the config index if there is one
		local configIndex = configIndices[configName]

		if not configIndex then
			continue
		end

		local configInfo = configData[configIndex]

		-- If the value is a selection
		if configInfo.Type == "Selection" then
			local options = configInfo.Options

			-- Sanity check for unknown option type
			if not options then
				warn(`Unknown selection type for config {configInfo.Name}:`, configInfo)
				continue
			end

			if type(options) == "table" and options.Enum then
				-- Look for enum
				local enum = Enum[options.Enum]

				-- Sanity check for enums
				if not enum then
					warn(`Invalid enum config options for selection {configInfo.Name}: {options.Enum}`)
					continue
				end

				-- Convert enum item name -> EnumItem
				if type(configValue) == "string" then
					-- Search every EnumItem
					for _, enumItem in enum:GetEnumItems() do
						local nameMatches = string.lower(enumItem.Name) == string.lower(configValue)
						local pathMatches = string.lower(tostring(enumItem)) == string.lower(tostring(configValue))

						if nameMatches or pathMatches then
							configValue = enumItem
							break
						end
					end
				end
			elseif type(options) == "table" then
				-- Sanity check for invalid numeric configs
				if type(options[1]) == "number" then
					warn(`Invalid numeric config options for selection {configInfo.Name}:`, configInfo)
					continue
				end

				-- Convert enum -> value
				if type(configValue) ~= "number" then
					local valueIndex = table.find(options, configValue)
					configValue = if valueIndex then valueIndex - 1 else configValue
				end
			elseif options == "Natural" then
				-- TODO
			end
		elseif configInfo.Type == "NumberRange" and type(configValue) == "string" then
			local parts = string.split(configValue, ":")
			configValue = { tonumber(parts[1]) or 0, tonumber(parts[2]) or 0 }
		elseif configInfo.Type == "Vector2" and type(configValue) == "string" then
			local parts = string.split(configValue, ",")
			configValue = { tonumber(parts[1]) or 0, tonumber(parts[2]) or 0 }
		elseif configInfo.Type == "Coordinate" and configValue == "" then
			configValue = nil
		end

		-- Move the config value to the config index
		compressedValues[configIndex] = configValue
		compressedValues[configName] = nil
	end

	return compressedValues
end

function PartMetadata:DecompressConfigurables(configurables: { [string | number]: any }, configData: { ConfigValue })
	local decompressedValues = table.clone(configurables)

	-- Get the config indices
	local configIndices = getConfigIndices(configData)

	-- Move all of the configurables
	for configIndex, configValue in configurables do
		-- Get config index for non-numeric config indices
		if type(configIndex) ~= "number" then
			configIndex = configIndices[configIndex]
		end

		if not configIndices then
			continue
		end

		-- Grab the config info for the config index if it is defined
		local configInfo = configData[configIndex :: any]

		if not configInfo then
			continue
		end

		-- If the value is a selection
		if configInfo.Type == "Selection" then
			local options = configInfo.Options

			-- Sanity check for unknown option type
			if not options then
				warn(`Unknown selection type for config {configInfo.Name}:`, configInfo)
				continue
			end

			if type(options) == "table" and options.Enum then
				-- Look for enum
				local enum = Enum[options.Enum]

				-- Sanity check for enums
				if not enum then
					warn(`Invalid enum config options for selection {configInfo.Name}: {options.Enum}`)
					continue
				end

				-- Convert enum ID -> EnumItem (This is no longer valid encoding, but exists for compatibility with older formats)
				if type(configValue) == "number" then
					configValue = enum:FromValue(configValue)
				end

				-- Convert EnumItem -> name
				if typeof(configValue) == "EnumItem" then
					configValue = configValue.Name
				end
			elseif type(options) == "table" then
				-- Sanity check for invalid numeric configs
				if type(options[1]) == "number" then
					warn(`Invalid numeric config options for selection {configInfo.Name}:`, configInfo)
					continue
				end

				-- Convert enum -> value
				if type(configValue) == "number" then
					configValue = options[configValue + 1]
				end
			elseif options == "Natural" then
				-- TODO
			end
		elseif configInfo.Type == "NumberRange" and type(configValue) == "table" then
			configValue = `{tonumber(configValue[1]) or 0}:{tonumber(configValue[2]) or 0}`
		elseif configInfo.Type == "Vector2" and type(configValue) == "table" then
			configValue = `{tonumber(configValue[1]) or 0},{tonumber(configValue[2]) or 0}`
		elseif configInfo.Type == "Coordinate" and type(configValue) == "nil" then
			configValue = ""
		end

		-- Move the config value from the config index
		decompressedValues[configInfo.Name] = configValue
		decompressedValues[configIndex] = nil
	end

	return decompressedValues
end

-- Parts & part info
export type ObjectInfo = {
	Instance: Instance,
	ClassName: string,

	CFrame: CFrame,
	Size: Vector3,
	Color: Color3,

	Anchored: boolean,

	Surfaces: {
		TopSurface: Enum.SurfaceType,
		BottomSurface: Enum.SurfaceType,
		LeftSurface: Enum.SurfaceType,
		RightSurface: Enum.SurfaceType,
		FrontSurface: Enum.SurfaceType,
		BackSurface: Enum.SurfaceType,
	},

	Configurables: { [string]: any },

	Joints: { Joints.AnyJointInfo },

	Fields: { [string]: any },
}

function PartMetadata:GetPrimaryPart(realObject: Instance): BasePart?
	if realObject:IsA("BasePart") then
		-- Return the part itself
		return realObject
	elseif realObject:IsA("Tool") then
		-- Look for a Handle part
		local handle
		for _, child in ipairs(realObject:GetChildren()) do
			if child.Name == "Handle" and child:IsA("BasePart") then
				handle = child
				break
			end
		end

		if handle then
			return handle
		end
	elseif realObject:IsA("Model") then
		-- Look for model primary part
		local primaryPart = realObject.PrimaryPart
		if primaryPart then
			return primaryPart
		end
	end

	-- Look for any descendant BasePart
	return realObject:FindFirstChildWhichIsA("BasePart", true)
end

local function getObjectInfo(instance: Instance, primaryPart: BasePart, origin: CFrame): ObjectInfo?
	-- Only consider parts
	local className = instance.Name
	if not OBJECT_ASSETS_FOLDER:FindFirstChild(className) then
		return
	end

	local components = instance:GetTags()
	local componentData = PartMetadata:GetComponents(instance)

	for componentName, _ in componentData do
		table.insert(components, componentName)
	end

	local objectInfo = {
		Instance = instance,
		ClassName = className,

		CFrame = origin:ToWorldSpace(primaryPart.CFrame),
		Size = primaryPart.Size,
		Color = instance:GetAttribute("Color") :: Color3 or primaryPart.Color,

		Anchored = primaryPart.Anchored,

		Surfaces = {
			TopSurface = primaryPart.TopSurface,
			BottomSurface = primaryPart.BottomSurface,
			LeftSurface = primaryPart.LeftSurface,
			RightSurface = primaryPart.RightSurface,
			FrontSurface = primaryPart.FrontSurface,
			BackSurface = primaryPart.BackSurface,
		},

		Configurables = PartMetadata:GetConfigurables(instance),

		Joints = Joints:GetJoints(primaryPart),

		Fields = {
			Shape = if primaryPart == instance then PartMetadata:GetShape(primaryPart) else nil,
			Tags = components,
		},
	}

	return objectInfo
end

function PartMetadata:GetWoSParts(descendants: { Instance }, origin: CFrame): ({ ObjectInfo }, { [BasePart]: ObjectInfo })
	local partToObject: { [BasePart]: ObjectInfo } = {}

	-- Process each part
	local partCount = 0
	for _, object in ipairs(descendants) do
		if object:IsA("Model") and not object:IsA("Tool") then
			continue
		end

		local primaryPart = PartMetadata:GetPrimaryPart(object)
		if primaryPart then
			-- If the primary part already has object info, skip it
			if partToObject[primaryPart] then
				continue
			end

			-- Get object info
			local objectInfo = getObjectInfo(object, primaryPart, origin)
			if objectInfo then
				-- Map primary part -> object info & add object
				partToObject[primaryPart] = objectInfo
				partCount += 1
			end
		end
	end

	-- Create object info array
	local objectInfos = table.create(partCount)
	for part, objectInfo in partToObject do
		table.insert(objectInfos, objectInfo)
	end
	return objectInfos, partToObject
end

return PartMetadata

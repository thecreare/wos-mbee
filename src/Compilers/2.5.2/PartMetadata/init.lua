--!strict
local Refcoder = require(script.Refcoder)
local Compression = require(script.Compression)
local compress, decompress = Compression.CompressZlib, Compression.DecompressZlib
local b64encode, b64decode = unpack(require(script.Base64))

local Joints = require(script.Joints)

local PartMetadata = {}

function PartMetadata:SaveString(data)
	return b64encode(compress(data))
end
function PartMetadata:LoadString(data)
	return decompress(b64decode(data))
end

function PartMetadata:SaveData(data)
	return PartMetadata:SaveString(Refcoder.encode(data))
end
function PartMetadata:LoadData(data)
	return Refcoder.decode((PartMetadata:LoadString(data)))
end

-- Constants
local OBJECT_ASSETS_FOLDER = script:WaitForChild("ObjectsFolder")
local OBJECT_ASSETS = OBJECT_ASSETS_FOLDER:GetChildren()
local SHAPE_ASSETS_FOLDER = script:WaitForChild("Shapes")
local SHAPE_ASSETS = SHAPE_ASSETS_FOLDER:GetChildren()
local SHAPE_ENUM = table.create(#SHAPE_ASSETS)

local SHAPE_NAMES_BY_PART_TYPE = {
	[Enum.PartType.Block] = "Block";
	[Enum.PartType.Ball] = "Ball";
	[Enum.PartType.Cylinder] = "Cylinder";
	[Enum.PartType.Wedge] = "Wedge";
	[Enum.PartType.CornerWedge] = "CornerWedge";
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
	elseif part:IsA("Part") then
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
function PartMetadata:GetConfigurables(instance: Instance): {[string]: any}
	local configurables = instance:GetAttributes()
	-- Copy values from ValueBase objects
	for _, child in ipairs(instance:GetChildren()) do
		if not child:IsA("ValueBase") then continue end
		local name = child.Name
		if configurables[name] ~= nil then continue end
		if name ~= "TempType" then
			configurables[name] = (child :: any).Value
		end
	end
	return configurables
end

-- Component getter
function PartMetadata:GetComponents(instance: Instance): {[string]: unknown}
	local components = {}

	for _, child in instance:GetChildren() do
		if not child:IsA("Configuration") then
			continue
		end

		components[child.Name] = {PartMetadata:GetConfigurables(child)}
	end

	return components
end

-- Parts & part info
export type ObjectInfo = {
	Instance: Instance;
	ClassName: string;

	CFrame: CFrame;
	Size: Vector3;
	Color: Color3;

	Anchored: boolean;

	Surfaces: {
		TopSurface: Enum.SurfaceType;
		BottomSurface: Enum.SurfaceType;
		LeftSurface: Enum.SurfaceType;
		RightSurface: Enum.SurfaceType;
		FrontSurface: Enum.SurfaceType;
		BackSurface: Enum.SurfaceType;
	};

	Configurables: {[string]: any};

	Joints: {Joints.AnyJointInfo};

	Fields: {[string]: any};
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

		if handle then return handle end
	elseif realObject:IsA("Model") then
		-- Look for model primary part
		local primaryPart = realObject.PrimaryPart
		if primaryPart then return primaryPart end
	end

	-- Look for any descendant BasePart
	return realObject:FindFirstChildWhichIsA("BasePart", true)
end

local function getObjectInfo(instance: Instance, primaryPart: BasePart, origin: CFrame): ObjectInfo?
	-- Only consider parts
	local className = instance.Name
	if not OBJECT_ASSETS_FOLDER:FindFirstChild(className) then return end

	local objectInfo = {
		Instance = instance;
		ClassName = className;

		CFrame = origin:ToWorldSpace(primaryPart.CFrame);
		Size = primaryPart.Size;
		Color = instance:GetAttribute("Color") or primaryPart.Color;

		Anchored = primaryPart.Anchored;

		Surfaces = {
			TopSurface = primaryPart.TopSurface;
			BottomSurface = primaryPart.BottomSurface;
			LeftSurface = primaryPart.LeftSurface;
			RightSurface = primaryPart.RightSurface;
			FrontSurface = primaryPart.FrontSurface;
			BackSurface = primaryPart.BackSurface;
		};

		Configurables = PartMetadata:GetConfigurables(instance);

		Joints = Joints:GetJoints(primaryPart);

		Fields = {
			Shape = if primaryPart == instance then PartMetadata:GetShape(primaryPart) else nil;
			Tags = instance:GetTags();
		};
	}

	return objectInfo
end

function PartMetadata:GetWoSParts(descendants: {Instance}, origin: CFrame): ({ObjectInfo}, {[BasePart]: ObjectInfo})
	local partToObject: {[BasePart]: ObjectInfo} = {}

	-- Process each part
	local partCount = 0
	for _, object in ipairs(descendants) do
		local primaryPart = PartMetadata:GetPrimaryPart(object)
		if primaryPart then
			-- If the primary part already has object info, skip it
			if partToObject[primaryPart] then continue end

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
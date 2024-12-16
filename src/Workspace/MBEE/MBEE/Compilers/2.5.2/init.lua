local Sift = require(script.Parent.Parent.Packages.Sift)

local Malleability = require(script.Parent.Parent.Malleability)
local COMPAT_NAME_REPLACEMENTS = require(script.Parent.Parent.Compatibility)
local Util = require(script.Parent.Parent.Util)

-- Copy parts into PartMetadata
local OBJECT_ASSETS_FOLDER = script.Parent.Parent.Parts:Clone()
OBJECT_ASSETS_FOLDER.Name = "ObjectsFolder"
OBJECT_ASSETS_FOLDER.Parent = script.PartMetadata

local Compiler = require(script.PartMetadata.Compiler)
local Joints = require(script.PartMetadata.Joints)
local PartMetadata = require(script.PartMetadata)
local Refcoder = require(script.PartMetadata.Refcoder)

local ModelBuilder = {}

ModelBuilder.Title = "Unstable"
ModelBuilder.DateAdded = "2024-05-14"
ModelBuilder.Default = false
ModelBuilder.Selected = false

local CONSTRAINT_PROPS = {
	RodConstraint = {
		"Length";
	};
	RopeConstraint = {
		"Length";
		"Restitution";
	};
	SpringConstraint = {
		"FreeLength";
		"MaxForce";
		"Stiffness";
		"Damping";
	};
}

local CONSTRAINT_ENUM = { "RodConstraint", "RopeConstraint", "SpringConstraint" }

for index, value in CONSTRAINT_ENUM do
	CONSTRAINT_ENUM[value] = index
end

local function GetClosestFace(vec: Vector3): Enum.NormalId -- returns the face whose normal is most aligned with the input unit vector
	local Face = Enum.NormalId.Front
	local PrevDot = 0
	local Normal = Vector3.FromNormalId(Face)
	for _,F in pairs(Enum.NormalId:GetEnumItems()) do
		local ThisNormal = Vector3.FromNormalId(F)
		local Dot = vec:Dot(ThisNormal)
		if Dot > PrevDot then
			PrevDot = Dot
			Face = F
			Normal = ThisNormal
		end
	end
	return Face
end

local LoadSurfaces, GetSurfaces, NormalIdFromValue
do
	-- Create an array with names of surface properties, eg. {"FrontSurface", "BackSurface", ...}
	NormalIdFromValue = {}
	local SurfacePropertyNames = {}
	for _,v in pairs(Enum.NormalId:GetEnumItems()) do
		SurfacePropertyNames[v.Value] = v.Name.."Surface"
		NormalIdFromValue[v.Value] = v
	end

	-- Convert Enum.SurfaceType into a dictionary with string keys to get the surface enum out
	-- This is ~10x faster than calling tonumber() at runtime to index Enum.SurfaceType directly
	SurfaceTypeFromValue = {}
	for _,v in pairs(Enum.SurfaceType:GetEnumItems()) do
		SurfaceTypeFromValue[v.Value] = v
end

	-- override stuff to be universal instead in case someone modified their plugin
	SurfaceTypeFromValue[Enum.SurfaceType.Weld.Value] = Enum.SurfaceType.Universal
	SurfaceTypeFromValue[Enum.SurfaceType.Glue.Value] = Enum.SurfaceType.Universal
	SurfaceTypeFromValue[Enum.SurfaceType.SteppingMotor.Value] = Enum.SurfaceType.Universal

	LoadSurfaces = function(Part : BasePart, Val: number)
		for i = 5, 0, -1 do
			Part[SurfacePropertyNames[i]] = SurfaceTypeFromValue[bit32.band(Val, 0xf)]
			Val = bit32.rshift(Val, 4)
		end
	end

	GetSurfaces = function(Part : BasePart, Hinges: {any}?): number
		local Val = 0
		for i = 0, 5 do
			Val = bit32.lshift(Val, 4)

			local surfaceType = Part[SurfacePropertyNames[i]]

			local hinge = Hinges and Hinges[NormalIdFromValue[i]]
			if hinge then
				surfaceType = if hinge[4] then Enum.SurfaceType.Motor else Enum.SurfaceType.Hinge
			end

			Val += surfaceType.Value
		end
		return Val
	end
end

function ModelBuilder:GetAssemblies(parts: {BasePart}, includeExternal: boolean?)
	-- Create a set of valid parts if necessary
	local validSet = {}
	if not includeExternal then
		for _, part in ipairs(parts) do
			validSet[part] = true
		end
	end

	-- Create list of assembly origins & parts, and global offset lookup table
	local assembliesOriginList = {}
	local assembliesPartsList = {}
	local assemblyOffsets = {}

	-- For each part, get the assembly it is part of & assign offsets
	for _, part in ipairs(parts) do
		if typeof(part) ~= "Instance" then continue end
		if not part:IsA("BasePart") then continue end

		-- Avoid duplicating assemblies
		if assemblyOffsets[part] then continue end

		-- Grab the root part & its CFrame
		local rootPart = part.AssemblyRootPart or part
		local rootCFrame = rootPart.CFrame

		-- Grab all assembly parts & filter against the input if includeExternal is not set
		local fullAssembly = rootPart:GetConnectedParts(true)

		-- If the assembly is empty it is likely not in the DataModel, so use the part itself
		if not next(fullAssembly) then
			fullAssembly = {rootPart}
		end

		-- Filter the assembly for parts in the input parts list
		local assembly = if includeExternal then fullAssembly else Sift.Array.filter(fullAssembly, function(otherPart)
			-- If the part is not in the set of valid parts, do not include it
			if not validSet[otherPart] then return false end
			return true
		end)

		-- Add the assembly & its origin to the assemblies list & the origins list
		table.insert(assembliesOriginList, rootCFrame)
		table.insert(assembliesPartsList, assembly)

		-- For each part in the assembly
		for _, otherPart in ipairs(assembly) do
			assemblyOffsets[otherPart] = rootCFrame:ToObjectSpace(otherPart.CFrame)
		end
	end

	return assembliesOriginList, assembliesPartsList, assemblyOffsets
end

function ModelBuilder:Compile(instances, saveConfig): string
	local yieldTime = os.clock()
	local function throttle()
		if os.clock() - yieldTime > 1 then
			task.wait()
			yieldTime = os.clock()
		end
	end

	for _, instance in pairs(instances) do
		instance.Anchored = false
		instance:MakeJoints()
	end

	throttle()

	local origin = saveConfig and CFrame.new(saveConfig.Offset)
	
	local assemblyCFrames, assemblyPartLists, partOffsets = self:GetAssemblies(instances)

	throttle()

	local assemblies: { Compiler.AssemblyDataSparse } = {}

	local savedPartSet = {}

	local currentPartIndex = 0
	local partIndexLookup = {}
	
	local savedParts = {}
	local savedPartData = {}

	for assemblyIndex: number, assemblyCFrame: CFrame in assemblyCFrames do
		local assemblyParts = Sift.Array.map(assemblyPartLists[assemblyIndex], function(part: BasePart): Compiler.PartDataSparse?
			throttle()

			if savedPartSet[part] then
				return nil
			end
			savedPartSet[part] = true

			local className = part.Name
			
			-- Look for a template part			
			local templateValue = part:FindFirstChild("TempType")
			if templateValue then
				className = templateValue.Value
			end
			
			-- Compatibility replacements
			if COMPAT_NAME_REPLACEMENTS[className] then
				className = COMPAT_NAME_REPLACEMENTS[className]
			end

			local properties: {[string]: unknown} = {}

			local configurables = PartMetadata:GetConfigurables(part)
			local components = PartMetadata:GetComponents(part)

			properties.Components = if next(components) then components else nil
			properties.Shape = PartMetadata:GetShape(part)

			-- Generate the part data for the object
			local partData: Compiler.PartDataSparse = {
				ClassName = className;

				Color = part.Color;
				Size = part.Size;
				Surfaces = GetSurfaces(part);

				CFrame = partOffsets[part];

				Properties = properties;
				Configuration = configurables;

				Constraints = {};
				Hinges = {};
				Welds = {};
				Grounded = false;
			}

			currentPartIndex += 1
			savedParts[currentPartIndex] = part

			partIndexLookup[part] = currentPartIndex
			savedPartData[currentPartIndex] = partData

			return partData
		end)

		assemblies[assemblyIndex] = {
			CFrame = origin:ToObjectSpace(assemblyCFrame);
			Parts = assemblyParts;
		}
	end

	throttle()

	-- For each part to be saved, populate all the joint & constraint data
	for partIndex, partData in savedPartData do
		throttle()

		local instance = savedParts[partIndex]
		local primaryPart = if instance:IsA("BasePart") then instance elseif instance:IsA("Model") then instance.PrimaryPart else nil

		if not primaryPart then
			continue
		end

		-- Get all of the weld/constraint/hinge data so we can populate it
		local welds = partData.Welds
		local constraints = partData.Constraints
		local hinges = partData.Hinges
		local grounded = false

		-- Create a set of welded parts for weld deduplication
		local weldSet = {}

		-- Save all constraints & welds
		for _, joint in primaryPart:GetJoints() do
			throttle()

			if not joint.Archivable then
				continue
			end

			local part0, part1 = Joints:GetJointParts(joint)
			local otherPart = part0 == primaryPart and part1 or part0

			if joint:IsA("JointInstance") or joint:IsA("RigidConstraint") then
				if otherPart then
					--if otherPart:IsDescendantOf(workspace.Terrain) then
					--	grounded = true
					--	continue
					--end

					local otherPartIndex = partIndexLookup[otherPart]
					local otherPartData = savedPartData[otherPartIndex]
					local otherWelds = otherPartData and otherPartData.Welds
					
					if not otherPartIndex then
						continue
					end

					if joint:IsA("DynamicRotate") or joint:IsA("Rotate") then
						if joint.Parent ~= primaryPart then
							continue
						end

						local c0, c1 = joint.C0, joint.C1

						local face = GetClosestFace(-c0.LookVector)

						local hingeData = hinges[face.Value] or {}
						hinges[face.Value] = hingeData

						local otherFace = GetClosestFace(-c1.LookVector)
						local look = CFrame.lookAt(Vector3.zero, Vector3.FromNormalId(otherFace))
						local rotation = math.acos(look.UpVector:Dot(c1.RightVector)) * math.sign(look.RightVector:Dot(c1.RightVector))

						table.insert(hingeData, {otherPartIndex, c1.Position.X, c1.Position.Y, c1.Position.Z, otherFace.Value, rotation})
						continue
					end

					if not otherWelds[partIndex] then
						weldSet[otherPartIndex] = true
					end
				end
			elseif joint:IsA("Constraint") then
				if part0 == primaryPart and otherPart then
					local otherPartIndex = partIndexLookup[otherPart]
					local constraint = {otherPartIndex, CONSTRAINT_ENUM[joint.Name]}

					-- If the joint has properties
					local props = CONSTRAINT_PROPS[joint.Name]

					if not props then
						continue
					end

					-- Add the property value to the constraint
					for _, propName in props do
						table.insert(constraint, joint[propName])
					end

					table.insert(constraints, constraint)
				end
			end
		end

		-- Add all welds to the welds list
		for otherPartIndex, _ in weldSet do
			throttle()

			table.insert(welds, otherPartIndex)
		end

		-- Trim empty joint data
		if not next(welds) then
			partData.Welds = nil
		end
		if not next(constraints) then
			partData.Constraints = nil
		end
		if not next(hinges) then
			partData.Hinges = nil
		end

		-- Update grounded state
		partData.Grounded = grounded or nil
	end

	throttle()

	-- Encode the assembly data
	local encoded = Compiler:Encode({
		Assemblies = assemblies	
	}, {})

	-- Encode/compress the data
	return PartMetadata:SaveString(buffer.tostring(encoded))
end

function ModelBuilder:GetMalleability(className: string)
	return Malleability[className]
end

return ModelBuilder
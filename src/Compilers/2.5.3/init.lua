local HttpService = game:GetService("HttpService")

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

local SHAPE_ASSETS_FOLDER = PartMetadata.SHAPE_ASSETS_FOLDER

type SaveConfig = Compiler.SaveConfig & {
	Offset: Vector3,
	ShowTODO: boolean
}
type AssemblyData = Compiler.AssemblyData
type PartData = Compiler.PartData

local TODO_WARNING = "The model was partially decompiled, however it has a trait such as configurables, component configs, or hinges, which aren't yet fully supported. Some information may be missing."

local PLACEABLE_CONSTRAINT_PROPERTIES = {
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

local PLACEABLE_CONSTRAINTS = { "RodConstraint", "RopeConstraint", "SpringConstraint" }

for index, value in PLACEABLE_CONSTRAINTS do
	PLACEABLE_CONSTRAINTS[value] = index
end

local CLASS_TO_COMPONENT_NAMES = {
	Hull = {"Hull"};
	Button = {"ClickButton", "KeyButton"};
	Blade = {"Blade"};
	Door = {"Door"};
}

local ModelBuilder = {}

ModelBuilder.Title = "Unstable"
ModelBuilder.DateAdded = "2024-05-20"
ModelBuilder.Default = false -- selected by default
ModelBuilder.Selected = false

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

function ModelBuilder:Compile(instances: {Instance}, saveConfig: SaveConfig): buffer
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
					local constraint = {otherPartIndex, PLACEABLE_CONSTRAINTS[joint.Name]}

					-- If the joint has properties
					local props = PLACEABLE_CONSTRAINT_PROPERTIES[joint.Name]

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
	return Compiler:Encode({
		Assemblies = assemblies	
	}, {})
end

function ModelBuilder:Decompile(data: string, saveConfig: SaveConfig)
	local hasTODO = false

	-- WIP Port from Unstable
	local progress-- = saveConfig.ProgressState
	local status-- = saveConfig.StatusState

	local yieldTime = os.clock()

	local function throttlePause(duration: number?)
		task.wait(duration)
		yieldTime = os.clock()
	end

	local lastProgress = 0

	local function shouldThrottle()
		---- If there is a progress state we want to do % based throttling too
		--if progress then
		--	-- Grab the current progress
		--	local newProgress = peek(progress)

		--	-- If the progress has increased by at least 0.1 or changed to 1, we should throttle
		--	if newProgress - lastProgress >= 0.1 or (lastProgress ~= 1 and newProgress == 1) then
		--		lastProgress = newProgress
		--		return true
		--	end
		--end

		return os.clock() - yieldTime > 1
	end

	local function throttle()
		if shouldThrottle() then
			throttlePause(0)
		end
	end

	local function setProgress(amount: number)
		--if not progress then
		--	return
		--end

		--task.defer(progress.set, progress, amount)
	end

	local function setStatus(message: string)
		--if not status then
		--	return
		--end

		--task.defer(status.set, status, message)
	end

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include

	-- Newer buffer format
	if type(data) == "string" and string.sub(data, 1, 1) == "{" then
		pcall(function()
			data = HttpService:JSONDecode(data)
		end)
	end

	-- Beginning of decoding
	local encoded = if type(data) == "buffer" then data else buffer.fromstring(PartMetadata:LoadString(data))
	local decoded = Compiler:Decode(encoded, saveConfig)

	local instances = {}
	local partDataToInstance = {}

	-- Create assembly containers
	local assemblyInfoToContainer = {}
	for assemblyIndex, assemblyInfo in decoded.Assemblies do
		local assemblyContainer = Instance.new("Folder")
		assemblyContainer.Name = `Assembly #{assemblyIndex}`

		assemblyInfoToContainer[assemblyInfo] = assemblyContainer

		table.insert(instances, assemblyContainer)
	end

	for partIndex, partInfo in decoded.Parts do
		local properties = partInfo.Properties
		local shape = properties.Shape
		local components = properties.Components

		local shapeAsset = shape and SHAPE_ASSETS_FOLDER:FindFirstChild(tostring(shape))
		local partAsset = OBJECT_ASSETS_FOLDER:FindFirstChild(tostring(partInfo.ClassName))

		local partTemplate = if shapeAsset then shapeAsset else partAsset

		if not partAsset then
			warn("Unknown part class", partInfo.ClassName)
			continue
		end

		if not partTemplate then
			warn("Unknown shape kind", shape)
			continue
		end

		local part = partTemplate:Clone()

		-- If the part is shaped
		if shapeAsset then
			-- Copy all children from the part asset to the part
			for _, child in partAsset:GetChildren() do
				local copy = child:Clone()
				copy.Parent = part
			end
		end

		-- Move the part to the part cframe
		part:PivotTo(partInfo.Assembly.CFrame:ToWorldSpace(partInfo.CFrame))

		if part:IsA("BasePart") then
			part.Size = partInfo.Size
			part.Color = partInfo.Color
		end

		--for _, configData in partInfo.Configuration do
		--	-- TODO
		--end
		
		if partInfo.Configuration and next(partInfo.Configuration) then
			if saveConfig.ShowTODO then
				warn("TODO: Configuration", `See: Part #{partIndex}`, partInfo)
			end
			hasTODO = true
		end
		
		if components then
			local hasConfig = false

			for componentName, componentData in components do
				if next(componentData) then
					hasConfig = true
				end

				local component = Instance.new("Configuration")

				component.Name = componentName

				component.Parent = part
			end

			if hasConfig then
				if saveConfig.ShowTODO then
					warn("TODO: Component configuration", `See: Part #{partIndex}`, partInfo)
				end
				hasTODO = true
			end
		end

		part.Parent = assemblyInfoToContainer[partInfo.Assembly]

		partDataToInstance[partInfo] = part
	end
	-- End of decoding

	overlapParams.FilterDescendantsInstances = instances

	throttle()

	local partCount = #decoded.Parts
	local partContacts = {}
	local primaryPartList = {}

	for partIndex, partData: PartData in decoded.Parts do
		setProgress((partIndex - 1) / partCount)

		throttle()

		local instance = partDataToInstance[partData]

		if not instance then
			continue
		end

		-- Get the primary part of the object
		local primaryPart = PartMetadata:GetPrimaryPart(instance)

		table.insert(primaryPartList, primaryPart)

		-- If the object has no primary part, skip it, we can't make any joints
		if not primaryPart then
			continue
		end

		-- Create set of compressed parts
		partContacts[partIndex] = Sift.Set.fromArray(workspace:GetPartsInPart(primaryPart, overlapParams))
	end

	for partIndex, partData: PartData in decoded.Parts do
		setProgress((partIndex - 1) / partCount)

		throttle()

		-- Get the primary part of the object
		local primaryPart = primaryPartList[partIndex]

		-- If the object has no primary part, skip it, we can't make any joints
		if not primaryPart then
			continue
		end

		-- If the part was grounded to the terrain
		if partData.Grounded then
			-- Anchor the part
			primaryPart.Anchored = true
		end

		-- Create set of compressed parts
		local touchingParts = partContacts[partIndex]

		throttle()

		-- Load manual welds
		for _, targetId in partData.Welds do
			throttle()

			local otherPart = primaryPartList[targetId]

			-- If the weld reference is invalid, skip
			if not otherPart then
				continue
			end

			---- Check if the part is intersecting
			--if saveConfig.VerifyData and not touchingParts[otherPart] then
			--	continue
			--end

			local weld = Instance.new("Weld")

			weld.Part0 = primaryPart
			weld.Part1 = otherPart

			weld.C0 = primaryPart.CFrame:ToObjectSpace(otherPart.CFrame)

			weld.Parent = primaryPart
		end

		-- Load constraints
		for _, constraintData in partData.Constraints do
			throttle()

			local targetId = constraintData[1]
			local otherPart = primaryPartList[targetId]

			-- If the constraint reference is invalid, skip
			if not otherPart then
				continue
			end

			-- Grab the constraint type & class
			local constraintType = constraintData[2]
			local constraintClass = PLACEABLE_CONSTRAINTS[constraintType]

			-- Skip if the constraint type is invalid
			if not constraintClass then
				continue
			end

			-- Try to create the constraint
			local constraint = Instance.new(constraintClass)

			-- Try to assign the constraint properties
			for i, propName in PLACEABLE_CONSTRAINT_PROPERTIES[constraintClass] do
				throttle()

				constraint[propName] = constraintData[i + 2]
			end

			-- Create the constraint
			local attachment0 = Instance.new("Attachment", primaryPart)
			local attachment1 = Instance.new("Attachment", otherPart)

			attachment0:AddTag("CJoint")
			attachment1:AddTag("CJoint")

			constraint:AddTag("CJoint")

			constraint.Visible = true

			constraint.Attachment0 = attachment0
			constraint.Attachment1 = attachment1

			constraint.Parent = primaryPart
		end

		-- Load hinge data
		for normalIdValue, hingeData in partData.Hinges do
			throttle()

			for _, attachmentData in hingeData do
				throttle()

				if saveConfig.ShowTODO then
					warn("TODO: Hinge constraint generation", `Part #{partIndex}`)
				end
				hasTODO = true
				--local targetId = attachmentData[1]
				--local otherPart = primaryPartList[targetId]

				---- If the hinge reference is invalid, skip
				--if not otherPart then
				--	continue
				--end

				---- Grab the hinge
				--local hinge = instance and instance.Hinges[NormalIdFromValue[tonumber(normalIdValue)]]

				--if not hinge then
				--	continue
				--end

				--local position = Vector3.new(attachmentData[2], attachmentData[3], attachmentData[4])
				--local otherFace = NormalIdFromValue[attachmentData[5]]

				---- Determine the hinge axis
				--local axis = Vector3.FromNormalId(otherFace)

				---- Break the joints between the two parts
				--Calculation.BreakWeldsBetween(primaryPart, otherPart)

				--throttle()

				---- Create socket attachment
				--local socket = Instance.new("Attachment")
				--socket.Name = "Socket"

				---- Load the socket cframe
				--socket.CFrame = CFrame.lookAt(position, position + axis) * CFrame.Angles(0, 0, attachmentData[6])
				--socket.Axis = axis
				--socket.Parent = otherPart

				---- Create the hinge
				--local hingeConstraint = Instance.new("HingeConstraint")

				--for property, value in hinge[5] do
				--	throttle()

				--	hingeConstraint[property] = value
				--end

				--hingeConstraint.Attachment0 = hinge[1]
				--hingeConstraint.Attachment1 = socket

				--hingeConstraint.ActuatorType = if hinge[4] then Enum.ActuatorType.Motor else Enum.ActuatorType.None
				--hingeConstraint.Parent = primaryPart

				--table.insert(hinge[2], hingeConstraint)
				--table.insert(hinge[3], socket)
			end
		end
	end

	if hasTODO then
		decoded[1] = `WARNING: {TODO_WARNING}`
	end

	return instances, decoded
end

function ModelBuilder:GetMalleability(className: string)
	return Malleability[className]
end

function ModelBuilder:TryMigrateShape(instance: BasePart)
	local shapeTemplate = SHAPE_ASSETS_FOLDER:FindFirstChild(instance.Name)

	if not shapeTemplate then
		return
	end

	local templateTypeValue = instance:FindFirstChild("TempType") or instance:FindFirstChild("TemplateType")

	if not templateTypeValue then
		return
	end

	local shape: BasePart = shapeTemplate:Clone()

	-- Name the shape
	shape.Name = templateTypeValue.Value

	-- Remove the template value
	templateTypeValue:Destroy()

	-- Copy a whole bunch of part properties
	shape.CFrame = instance.CFrame
	shape.Size = instance.Size
	shape.Color = instance.Color
	shape.Material = instance.Material
	shape.Transparency = instance.Transparency
	shape.Reflectance = instance.Reflectance
	shape.CollisionGroup = instance.CollisionGroup
	shape.Anchored = instance.Anchored
	shape.CanCollide = instance.CanCollide
	shape.CanQuery = instance.CanQuery
	shape.CanTouch = instance.CanTouch
	shape.CustomPhysicalProperties = instance.CurrentPhysicalProperties
	shape.Locked = instance.Locked
	shape.Massless = instance.Massless

	-- Move all children to the shape
	for _, child in instance:GetChildren() do
		child.Parent = shape
	end

	-- Copy all tags to the shape
	for _, tag in instance:GetTags() do
		shape:AddTag(tag)
	end

	-- Copy all attributes to the shape
	for attributeName, attributeValue in instance:GetAttributes() do
		shape:SetAttribute(attributeName, attributeValue)
	end
	
	-- Replace the instance with the shape
	shape.Parent = instance.Parent
	instance:Destroy()
end

function ModelBuilder:TryMigrateComponents(instance: Instance)
	local className = instance.Name
	local components = CLASS_TO_COMPONENT_NAMES[className]

	-- Create any components
	if not components then
		return
	end

	for _, componentName in components do
		-- If the component already exists, skip it
		if instance:FindFirstChild(componentName) then
			continue
		end

		local componentTemplate = script.Components:FindFirstChild(componentName)
		local component = if componentTemplate then componentTemplate:Clone() else Instance.new("Configuration")

		component.Name = componentName

		component.Parent = instance
	end
end

function ModelBuilder:TryMigrateTemplates(instance: BasePart)
	-- Try to migrate the part's shape
	ModelBuilder:TryMigrateShape(instance)

	-- Try to migrate the components
	ModelBuilder:TryMigrateComponents(instance)

	-- Grab the template type
	local templateTypeValue = instance:FindFirstChild("TemplateType")

	if not templateTypeValue then
		return
	end

	-- Grab the template type & delete the template value
	local templateType = templateTypeValue.Value
	templateTypeValue:Destroy()

	-- Name the part its template type
	if templateType then
		instance.Name = templateType
	end
end

return ModelBuilder
--!strict
local Joints = {}

local VALID_JOINTS: {[any]: any} = {"Weld", "RigidConstraint", "WeldConstraint", "RodConstraint", "RopeConstraint", "SpringConstraint"}
for _, jointClass in ipairs(VALID_JOINTS) do
	VALID_JOINTS[jointClass] = true
end
Joints.VALID_JOINTS = VALID_JOINTS

-- Joint info
type JointInfo<ClassName> = {
	ClassName: ClassName;
	OtherPart: BasePart;
}

export type WeldInfo = JointInfo<"Weld"> & {
	Offset0: CFrame?;
	Offset1: CFrame?;
}
export type RigidConstraintInfo = JointInfo<"RigidConstraint"> & {
	Offset0: CFrame?;
	Offset1: CFrame?;
}
export type WeldConstraintInfo = JointInfo<"WeldConstraint">

export type RodInfo = JointInfo<"RodConstraint"> & {
	Length: number;
}

export type RopeInfo = JointInfo<"RopeConstraint"> & {
	Length: number;
	Restitution: number;
}

export type SpringInfo = JointInfo<"SpringConstraint"> & {
	Length: number;
	MaxForce: number;
	Stiffness: number;
	Damping: number;
}

export type GetJointPartsOptions = {
	CJointLengthLimit: number?;
	CJointRaycastParams: RaycastParams?;
}
function Joints:GetJointParts(joint: Constraint | JointInstance | WeldConstraint, options: GetJointPartsOptions?): (BasePart?, BasePart?)
	local cjointLengthLimit = if options then options.CJointLengthLimit else nil
	local params = if options then options.CJointRaycastParams else nil
	
	local part1, part0
	if joint:IsA("Constraint") then
		local attachment0 = joint.Attachment0
		local attachment1 = joint.Attachment1

		part0 = attachment0 and attachment0.Parent :: BasePart
		part1 = attachment1 and attachment1.Parent :: BasePart

		-- If a CJoint length limit is specified, ignore non-rigid constraints that are too long
		if cjointLengthLimit and not joint:IsA("RigidConstraint") then
			if attachment0 and attachment1 then
				-- If distance is too high, return nil
				if (attachment0.WorldPosition - attachment1.WorldPosition).Magnitude > cjointLengthLimit then
					return nil, nil
				end
				
				-- If raycast params are specified
				if params then
					-- If an obstacle is in the way, return nil
					local worldRoot = joint:FindFirstAncestorWhichIsA("WorldRoot") or workspace
					local result = worldRoot:Raycast(attachment0.WorldPosition, attachment1.WorldPosition - attachment0.WorldPosition, params)
					local instance = result and result.Instance
					if instance and instance ~= part0 and instance ~= part1 then
						return nil, nil
					end
				end
			end
		end
	elseif joint:IsA("JointInstance") or joint:IsA("WeldConstraint") then
		part0 = joint.Part0
		part1 = joint.Part1
	else
		pcall(function()
			part0 = joint.Part0
		end)
		pcall(function()
			part1 = joint.Part1
		end)
	end

	return part0, part1
end

export type AnyJointInfo = WeldInfo | WeldConstraintInfo | RigidConstraintInfo | RodInfo | RopeInfo | SpringInfo;

local function filterArrayTwoPass<T>(array: {T}, filter: (T) -> boolean?): {T}
	-- First pass (size allocation)
	local filteredCount = 0
	for _, item in ipairs(array) do
		if not filter(item) then continue end
		filteredCount += 1
	end

	-- Second pass
	local output = table.create(filteredCount)
	for _, item in ipairs(array) do
		if not filter(item) then continue end
		table.insert(output, item)
	end
	return output
end

export type AnyJointInstance = JointInstance | Constraint | WeldConstraint
local function isValidJoint(joint: AnyJointInstance)
	-- Ignore non-archivable joints
	if not joint.Archivable then return false end
	
	-- Ignore inactive joints
	if not joint.Active then return false end

	-- Check for all valid joint types
	if joint:IsA("Weld") then return true end
	if joint:IsA("WeldConstraint") then return true end

	-- Check for attachments
	if joint:IsA("Constraint") then
		if not joint.Attachment0 or not joint.Attachment1 then return false end
	end
	
	-- Check valid constraints
	if joint:IsA("RigidConstraint") then return true end
	if joint:IsA("RodConstraint") then return true end
	if joint:IsA("RopeConstraint") then return true end
	if joint:IsA("SpringConstraint") then return true end

	return false
end

local function getJointInfo(descendant: BasePart, joint: AnyJointInstance): AnyJointInfo?
	local part0, part1 = Joints:GetJointParts(joint)

	-- If a part is missing, skip
	if not part0 or not part1 then return end

	-- If the root part isn't the descendant, skip
	if part0 ~= descendant then return end

	-- Insert joint info
	if joint:IsA("Weld") then
		local c0 = joint.C0
		local c1 = joint.C1
		return {
			ClassName = "Weld" :: "Weld";
			OtherPart = part1;
			Offset0 = if c0 == CFrame.identity then nil else c0;
			Offset1 = if c1 == CFrame.identity then nil else c1;
		}
	elseif joint:IsA("WeldConstraint") then
		return {
			ClassName = "WeldConstraint" :: "WeldConstraint";
			OtherPart = part1;
		}
	elseif joint:IsA("RigidConstraint") then
		local attachment0 = joint.Attachment0
		local attachment1 = joint.Attachment1
		local c0 = attachment0 and attachment0.CFrame
		local c1 = attachment1 and attachment1.CFrame
		return {
			ClassName = "RigidConstraint" :: "RigidConstraint";
			OtherPart = part1;
			Offset0 = if c0 == CFrame.identity then nil else c0;
			Offset1 = if c1 == CFrame.identity then nil else c1;
		}
	elseif joint:IsA("RodConstraint") then
		return {
			ClassName = "RodConstraint" :: "RodConstraint";
			OtherPart = part1;
			Length = joint.Length;
		}
	elseif joint:IsA("RopeConstraint") then
		return {
			ClassName = "RopeConstraint" :: "RopeConstraint";
			OtherPart = part1;
			Length = joint.Length;
			Restitution = joint.Restitution;
		}
	elseif joint:IsA("SpringConstraint") then
		return {
			ClassName = "SpringConstraint" :: "SpringConstraint";
			OtherPart = part1;
			Length = joint.FreeLength;
			MaxForce = joint.MaxForce;
			Stiffness = joint.Stiffness;
			Damping = joint.Damping;
		}
	end
	return nil
end

function Joints:GetJoints(descendant: BasePart): {AnyJointInfo}
	local validJoints: {AnyJointInstance} = filterArrayTwoPass((descendant:GetJoints() :: {any}) :: {AnyJointInstance}, isValidJoint)

	local jointInfos: {AnyJointInfo} = table.create(#validJoints)
	for _, joint in ipairs(validJoints) do
		local jointInfo = getJointInfo(descendant, joint)
		if jointInfo then
			table.insert(jointInfos, jointInfo)
		end
	end
	return jointInfos
end

function Joints:CreateJoint(part: BasePart, jointInfo: AnyJointInfo)
	local className = jointInfo.ClassName
	if not VALID_JOINTS[className] then return end
	
	local part0 = part
	local part1 = jointInfo.OtherPart
	
	local function getAttachments(offsetInfo: {Offset0: CFrame?, Offset1: CFrame?}?)
		local attachment0 = Instance.new("Attachment")
		local attachment1 = Instance.new("Attachment")

		-- If offsetInfo is passed
		if offsetInfo then
			attachment0.CFrame = offsetInfo.Offset0 or CFrame.identity
			attachment1.CFrame = offsetInfo.Offset1 or CFrame.identity
		end

		-- Parent the attachments
		attachment0.Parent = part0
		attachment1.Parent = part1

		-- Return the attachments
		return attachment0, attachment1
	end
	
	if jointInfo.ClassName == "Weld" then
		local joint = Instance.new("Weld")

		-- Assign joint offsets
		joint.C0 = jointInfo.Offset0 or CFrame.identity
		joint.C1 = jointInfo.Offset1 or CFrame.identity

		-- Assign Part0 & Part1
		joint.Part0 = part0
		joint.Part1 = part1

		joint.Parent = part0
		return joint
	elseif jointInfo.ClassName == "WeldConstraint" then
		local joint = Instance.new("WeldConstraint")

		-- Set Part0 & Part1
		joint.Part0 = part0
		joint.Part1 = part1

		joint.Parent = part0
		return joint
	elseif jointInfo.ClassName == "RigidConstraint" then
		local joint = Instance.new("RigidConstraint")

		-- Create attachments with joint offsets
		joint.Attachment0, joint.Attachment1 = getAttachments(jointInfo)

		joint.Parent = part0
		return joint
	elseif jointInfo.ClassName == "RodConstraint" then
		local joint = Instance.new("RodConstraint")

		-- Assign properties
		joint.Length = jointInfo.Length

		-- Create attachments
		joint.Attachment0, joint.Attachment1 = getAttachments()

		joint.Parent = part0
		return joint
	elseif jointInfo.ClassName == "RopeConstraint" then
		local joint = Instance.new("RopeConstraint")

		-- Assign properties
		joint.Restitution = jointInfo.Restitution
		joint.Length = jointInfo.Length

		-- Create attachments
		joint.Attachment0, joint.Attachment1 = getAttachments()

		joint.Parent = part0
		return joint
	elseif jointInfo.ClassName == "SpringConstraint" then
		local joint = Instance.new("SpringConstraint")

		-- Assign properties
		joint.MaxForce = jointInfo.Stiffness
		joint.Damping = jointInfo.Damping
		joint.FreeLength = jointInfo.Length

		-- Create attachments
		joint.Attachment0, joint.Attachment1 = getAttachments()

		joint.Parent = part0
		return joint
	end
end

return Joints
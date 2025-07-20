-- original "Reflect" plugin by stravant
-- edited by TWllNS
-- edited by creare

-- Debugging stub to temporarily turn off the plugin easily with Ctrl+Shift+L
if false then
	return false
end

--Updated June 2022:
-- * Improved toolbar combiner, based on Module.

local plugin = _G.plugin
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CoreGui = game:GetService("CoreGui")
local LogService = game:GetService("LogService")

local Compilers = require(script.Parent.Modules.Compilers)
local createSharedToolbar = require(script.Parent.createSharedToolbar)

local Plugin = plugin

local clickedButton;

local sharedToolbarSettings = {} :: createSharedToolbar.SharedToolbarSettings
sharedToolbarSettings.CombinerName = "WoS Tools"
sharedToolbarSettings.ToolbarName = "WoS Tools"
sharedToolbarSettings.ButtonName = "ReflectButton"
sharedToolbarSettings.ButtonText = "Reflect"
sharedToolbarSettings.ButtonIcon = "rbxassetid://10081605298"
sharedToolbarSettings.ButtonTooltip = "[WoS VERSION 2] Reflect the currently selected parts and/or models over a plane of your choice. The new reflected copy will be selected after creation."
sharedToolbarSettings.ClickedFn = function() clickedButton() end
createSharedToolbar(plugin, sharedToolbarSettings)

local Gui = script.ReflectPluginGui:Clone()
--local Gui = Workspace.ReflectPlugin.ReflectPluginGui:Clone()
Gui.Archivable = false
Gui.Parent = game:GetService('CoreGui')

local Dialog = Gui:WaitForChild('Dialog')

local CancelButton = Dialog:WaitForChild('CancelButton')

local tooLongStart = 0
local hasGivenStillWorkingMessage = false
local WarnAfter = 5
_G.ReflectTimeout = 15
local function tooLongCheck()
	if not hasGivenStillWorkingMessage and (os.clock() - tooLongStart) > WarnAfter then
		hasGivenStillWorkingMessage = true
		warn("Reflecting is taking a long time... will continue for " .. (_G.ReflectTimeout - WarnAfter) .. " more seconds.")
		task.wait(0.1)
	end
	if (os.clock() - tooLongStart) > _G.ReflectTimeout then
		error("Reflecting took to long. Run \"_G.ReflectTimeout = 137\" in the command bar with a number of seconds to allow more time.")
	end
end

function CFrameFromTopBack(at, top, back)
	local right = top:Cross(back)
	return CFrame.new(at.x, at.y, at.z,
		right.x, top.x, back.x,
		right.y, top.y, back.y,
		right.z, top.z, back.z)
end

function Spin(v)
	if v == Vector3.new(0, 1, 0) then
		return Vector3.new(0, 0, 1)
	else
		return Vector3.new(0, 1, 0)
	end
end

local function reflectVec(v, axis)
	return v - 2*(axis*v:Dot(axis))
end

local function ReflectCFrame(cf: CFrame, overCFrame: CFrame, corner: boolean, attachment: boolean)
	-- Mirroring characteristics
	local mirrorPoint = overCFrame.Position
	local mirrorAxis = overCFrame.LookVector

	-- Break to components
	local position = cf.Position
	local x, y, z = position.X, position.Y, position.Z

	-- Mirror position
	local newPos =
		mirrorPoint +
		reflectVec(Vector3.new(x, y, z) - mirrorPoint, mirrorAxis)

	-- Get rotation axis components
	local xAxis = cf.XVector
	local yAxis = cf.YVector
	local zAxis = cf.ZVector

	-- Mirror them
	xAxis = reflectVec(xAxis, mirrorAxis)
	yAxis = reflectVec(yAxis, mirrorAxis)
	zAxis = reflectVec(zAxis, mirrorAxis)

	-- Handedness fix
	if attachment then
		-- For attachments, the X and Y axis are the actively used ones that
		-- we want to preserve.
		zAxis = -zAxis
	else
		-- X axis chosen so that WedgeParts will work
		xAxis = -xAxis
	end

	-- Corner fix
	if corner then
		xAxis, zAxis = -zAxis, xAxis
	end

	-- Reconstitute
	return CFrame.new(newPos.X, newPos.Y, newPos.Z,
		xAxis.X,  yAxis.X,  zAxis.X,
		xAxis.Y,  yAxis.Y,  zAxis.Y,
		xAxis.Z,  yAxis.Z,  zAxis.Z)
end

function IsCornerWedge(part)
	for _, ch in pairs(part:GetChildren()) do
		if ch:IsA('SpecialMesh') and ch.MeshType == Enum.MeshType.CornerWedge then
			return true
		end
	end
	return part:IsA('CornerWedgePart')
end

function IsFaceItem(instance)
	return instance:IsA('FaceInstance') or instance:IsA('SurfaceGui') or 
		instance:IsA('SurfaceLight') or instance:IsA('SpotLight')
end

function ReflectFaceItems(part)
	for _, ch in pairs(part:GetChildren()) do
		if IsFaceItem(ch) then
			if IsCornerWedge(part) then
				if ch.Face == Enum.NormalId.Left then
					ch.Face = 'Back'
				elseif ch.Face == Enum.NormalId.Right then
					ch.Face = 'Front'
				elseif ch.Face == Enum.NormalId.Front then
					ch.Face = 'Right'
				elseif ch.Face == Enum.NormalId.Back then
					ch.Face = 'Left'
				end
			else
				if ch.Face == Enum.NormalId.Left then
					ch.Face = 'Right'
				elseif ch.Face == Enum.NormalId.Right then
					ch.Face = 'Left'
				end
			end
		end
	end
end

function ReflectRawPart(part: BasePart, axis: CFrame)
	local isCorner = IsCornerWedge(part)
	local new = part
	new.Parent = part.Parent
	new.CFrame = ReflectCFrame(new.CFrame, axis, isCorner, false)
	if isCorner then
		new.BackSurface, new.FrontSurface, new.RightSurface, new.LeftSurface =
			new.LeftSurface, new.RightSurface, new.FrontSurface, new.BackSurface

		-- Added 18/12/19: Thanks TheNexusAvenger for this fix
		new.Size = Vector3.new(new.Size.Z, new.Size.Y, new.Size.X)
	else
		new.RightSurface, new.LeftSurface = new.LeftSurface, new.RightSurface
	end
	ReflectFaceItems(new)
	return new
end

function NegateUnion(part)
	return plugin:Negate({part})[1]
end

function SeparateUnion(part)
	return plugin:Separate({part})
end

function UnionTogether(parts)
	return plugin:Union(parts)
end

local function copyPartProperties(from, to)
	to.UsePartColor = from.UsePartColor
	to.Material = from.Material
	to.Color = from.Color
	to.Transparency = from.Transparency
	to.Anchored = from.Anchored
	to.CanCollide = from.CanCollide
	to.SmoothingAngle = from.SmoothingAngle
	to.CollisionGroupId = from.CollisionGroupId
end

function ReflectPart(part, axis, replacementPartMap: {BasePart: BasePart}, unionDepth, unionPath)
	if unionDepth > 10 then
		print(unionDepth, unionPath)
		return
	end
	tooLongCheck()
    local wos_shape = Compilers:GetPartMetadata():GetShape(part)
	if part:IsA('UnionOperation') then
		-- Need to reparent the children to the reflected union
		local children = part:GetChildren()
		for _, ch in pairs(children) do
			ch.Parent = nil
		end
		local oldSiblings = part.Parent:GetChildren()
		local st, err = pcall(function()
			return SeparateUnion(part)
		end)
		
		if st then
			local subParts = err
			for i, subPart in pairs(subParts) do
				subParts[i] = ReflectPart(subPart, axis, replacementPartMap, unionDepth + 1, unionPath .. "." .. subPart.Name)
			end

			st, err = pcall(function()
				local result = UnionTogether(subParts)
				copyPartProperties(part, result)
				replacementPartMap[part] = result
				return result
			end)
			if st then
				local reflectedUnion = err
				-- Reparent the stuff
				for _, ch in pairs(children) do
					ch.Parent = reflectedUnion
				end
				-- Flip the face items
				ReflectFaceItems(reflectedUnion)
				return reflectedUnion -- err is the returned union
			else
				warn("Error Unioning `"..subParts[1]:GetFullName().."`: "..err)
				-- Put back the children
				for _, ch in pairs(children) do
					ch.Parent = part
				end
				ReflectRawPart(part, axis)
				return part
			end
		else
			-- Separating may still create extra instances that weren't there
			-- before even in the case where the separate fails, so we need to
			-- have this extra code to remove those instances.
			local oldSiblingsSet = {}
			for _, ch in ipairs(oldSiblings) do
				oldSiblingsSet[ch] = true
			end
			for _, newSibling in ipairs(part.Parent:GetChildren()) do
				if not oldSiblingsSet[newSibling] then
					newSibling:Destroy()
				end
			end
			
			warn("Error Separating `"..part:GetFullName().."`: "..err)
			-- Put back the children
			for _, ch in pairs(children) do
				ch.Parent = part
			end
			ReflectRawPart(part, axis)
			return part
		end
	elseif part:IsA('NegateOperation') then
		-- Negate should never fail
		local result = NegateUnion(ReflectPart(NegateUnion(part), axis, replacementPartMap, unionDepth + 1, unionPath))
		replacementPartMap[part] = result
		return result
		
	elseif wos_shape == 'Tetrahedron' or wos_shape == 'RoundWedge2' or wos_shape == 'RoundWedge' or wos_shape == 'CornerRoundWedge' then
		ReflectRawPart(part, axis)
		part.Size = Vector3.new(part.Size.Z, part.Size.Y, part.Size.X)
		part.CFrame *= CFrame.Angles(0, -math.pi/2, 0)
		return part

	elseif wos_shape == 'CornerTetra' then
		ReflectRawPart(part, axis)
		part.Size = Vector3.new(part.Size.X, part.Size.Z, part.Size.Y)
		part.CFrame *= CFrame.Angles(math.pi/2, math.pi, 0)
		return part

	elseif wos_shape == 'CornerRoundWedge2' then
		ReflectRawPart(part, axis)
		part.Size = Vector3.new(part.Size.X, part.Size.Z, part.Size.Y)
		part.CFrame *= CFrame.Angles(-math.pi/2, -math.pi, 0)
		return part
		
	else
		ReflectRawPart(part, axis)
		return part
	end
end

function ReflectPartsAndModelsRecursive(instance: Instance, axis: CFrame, oldCFrameMap: {BasePart: CFrame}, modelPrimaryPartMap: {Model: BasePart}, replacementPartMap: {BasePart: BasePart})
	tooLongCheck()
	if instance:IsA("BasePart") then
		local oldCFrame = instance.CFrame
		local reflected = ReflectPart(instance, axis, replacementPartMap, 0, "MODEL")
		oldCFrameMap[reflected] = oldCFrame
	elseif instance:IsA("Model") then
		modelPrimaryPartMap[instance] = instance.PrimaryPart
		instance.WorldPivot = ReflectCFrame(instance.WorldPivot, axis, false, false)
	end
	for _, ch in ipairs(instance:GetChildren()) do
		ReflectPartsAndModelsRecursive(ch, axis, oldCFrameMap, modelPrimaryPartMap, replacementPartMap)
	end
end

local function patchProperty(instance: Instance, replacementPartMap: {BasePart: BasePart}, property: string)
	local value = (instance :: any)[property]
	if value and replacementPartMap[value] then
		(instance :: any)[property] = replacementPartMap[value]
	end
end

-- Reflecting parts may require destoying and recreating them in the case where
-- they're UnionOperations (CSG parts), in this case we need to fix up properties
-- that refered to those parts.
-- We won't do all properties, but only the ones that typically matter (Part0
-- and Part1 of welds)
function PatchReplacementPartsRecursive(instance: Instance, replacementPartMap: {BasePart: BasePart}, primaryPartMap: {Model: BasePart})
	tooLongCheck()
	if instance:IsA("WeldConstraint") or instance:IsA("JointInstance") or instance:IsA("NoCollisionConstraint") then
		patchProperty(instance, replacementPartMap, "Part0")
		patchProperty(instance, replacementPartMap, "Part1")
	elseif instance:IsA("ObjectValue") then
		patchProperty(instance, replacementPartMap, "Value")
	elseif instance:IsA("Model") then
		local oldPrimary = primaryPartMap[instance]
		if oldPrimary and replacementPartMap[oldPrimary] then
			instance.PrimaryPart = replacementPartMap[oldPrimary]
		end
	end
	for _, ch in ipairs(instance:GetChildren()) do
		PatchReplacementPartsRecursive(ch, replacementPartMap, primaryPartMap)
	end	
end

function ReflectPartRelativeInstancesRecursive(instance: Instance, axis: CFrame, oldCFrameMap: {BasePart: CFrame})
	tooLongCheck()
	if instance:IsA("Attachment") then
		local part = instance.Parent
		if part then
			local oldWorldCFrame = oldCFrameMap[part]:ToWorldSpace(instance.CFrame)
			instance.CFrame = part.CFrame:ToObjectSpace(ReflectCFrame(oldWorldCFrame, axis, false, true))
		end
	elseif instance:IsA("JointInstance") then
		local joint = instance
		local part0 = joint.Part0
		local part1 = joint.Part1
		if part0 and part1 then
			local c0World = oldCFrameMap[part0]:ToWorldSpace(joint.C0)
			joint.C0 = part0.CFrame:ToObjectSpace(ReflectCFrame(c0World, axis, false, false))
			--
			local c1World = oldCFrameMap[part1]:ToWorldSpace(joint.C1)
			joint.C1 = part1.CFrame:ToObjectSpace(ReflectCFrame(c1World, axis, false, false))
		end
	end
	for _, ch in ipairs(instance:GetChildren()) do
		ReflectPartRelativeInstancesRecursive(ch, axis, oldCFrameMap)
	end
end

function DisableJointsRecursive(instance: Instance, reenableJoints: {Instance: boolean})
	tooLongCheck()
	if instance:IsA("WeldConstraint") or instance:IsA("JointInstance") or instance:IsA("Constraint") then
		if instance.Enabled then
			-- The cast is to silence a warning thanks to Luau not understanding
			-- properties on a union between two nominal types that have the same
			-- property.
			(instance :: JointInstance).Enabled = false
			if instance:IsA("JointInstance") then
				local part0, part1 = instance.Part0, instance.Part1
				if part0 and part1 then
					reenableJoints[instance] = {part0.CFrame, part1.CFrame}
				else
					reenableJoints[instance] = true
				end
			else
				reenableJoints[instance] = true
			end
		end
	end
	for _, ch in ipairs(instance:GetChildren()) do
		DisableJointsRecursive(ch, reenableJoints)
	end
end

function ReenableJoints(jointsToReenable: {Instance: boolean})
	for joint, cframes in pairs(jointsToReenable) do
		joint.Enabled = true
	end
end

local function DoReflect(toReflect: {Instance}, ref_point: Vector3, ref_normal: Vector3)
	hasGivenStillWorkingMessage = false
	tooLongStart = os.clock()
	local axis = CFrame.lookAt(ref_point, ref_point + ref_normal)
	local newReflected = {}
	for i, instance in ipairs(toReflect) do
		local copy = instance:Clone()
		copy.Parent = instance.Parent
		newReflected[i] = copy
		local jointsToReenable = {} :: {Instance: boolean}
		local oldCFrameMap = {} :: {BasePart: CFrame}
		local replacementPartMap = {} :: {BasePart: BasePart}
		local primaryPartMap = {} :: {Model: BasePart}
		DisableJointsRecursive(copy, jointsToReenable)
		ReflectPartsAndModelsRecursive(copy, axis, oldCFrameMap, primaryPartMap, replacementPartMap)
		PatchReplacementPartsRecursive(copy, replacementPartMap, primaryPartMap)
		ReflectPartRelativeInstancesRecursive(copy, axis, oldCFrameMap)
		ReenableJoints(jointsToReenable)
	end
	return newReflected
end

local function ShowWarningText(text)
	local screenGui = Instance.new("ScreenGui")
	
	local container = Instance.new("Frame", screenGui)
	container.AutomaticSize = Enum.AutomaticSize.XY
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = UDim2.fromScale(0.5, 0.5)
	container.BackgroundColor3 = Color3.new(0, 0, 0)
	container.BackgroundTransparency = 0.2
	local stroke = Instance.new("UIStroke", container)
	stroke.Thickness = 2
	stroke.Color = Color3.new(0, 0, 0)
	local corner = Instance.new("UICorner", container)
	corner.CornerRadius = UDim.new(0, 8)
	local content = Instance.new("TextLabel", container)
	content.Font = Enum.Font.SourceSansBold
	content.TextSize = 32
	content.TextColor3 = Color3.new(1, 0.701961, 0)
	content.Size = UDim2.fromScale(1, 1)
	content.AutomaticSize = Enum.AutomaticSize.XY
	content.Text = text
	content.BackgroundTransparency = 1
	local padding = Instance.new("UIPadding", content)
	padding.PaddingTop = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.PaddingBottom = UDim.new(0, 16)
	padding.PaddingLeft = UDim.new(0, 16)
	--
	screenGui.Parent = game:GetService("CoreGui")
	container:TweenPosition(UDim2.new(0.5, 0, 0.5, -10), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3)
	wait(0.7)
	screenGui:Destroy()
end

local function createDisplay()
	local folder = Instance.new("Folder")
	local part = Instance.new("Part", folder)
	part.Name = "Display"
	--
	local height = 2
	local width = 4
	--
	local boxHandleAdornment = Instance.new("BoxHandleAdornment", folder)
	boxHandleAdornment.Size = Vector3.new(width, 0.1, width)
	boxHandleAdornment.Transparency = 0.7
	boxHandleAdornment.Adornee = part
	boxHandleAdornment.ZIndex = 0
	boxHandleAdornment.Color3 = Color3.new(1, 0.5, 0)
	--
	local axis = Instance.new("CylinderHandleAdornment", folder)
	axis.CFrame = CFrame.fromEulerAnglesXYZ(math.pi/2, 0, 0) * CFrame.new(0, 0, -0.5 * height)
	axis.Height = height
	axis.Radius = 0.1
	axis.Adornee = part
	axis.ZIndex = 0
	axis.Color3 = Color3.new(1, 0.5, 0)
	--
	local arrow = Instance.new("ConeHandleAdornment", folder)
	arrow.CFrame = CFrame.fromEulerAnglesXYZ(math.pi/2, 0, 0) * CFrame.new(0, 0, -height)
	arrow.Height = 1
	arrow.Radius = 0.3
	arrow.Adornee = part
	arrow.ZIndex = 0
	arrow.Color3 = Color3.new(1, 0.5, 0)
	--
	for x = -2, 2 do
		local axis = Instance.new("CylinderHandleAdornment", folder)
		axis.CFrame = CFrame.new(x, 0, 0)
		axis.Height = width + 0.5
		axis.Radius = 0.05
		axis.Adornee = part
		axis.ZIndex = 0
		axis.Color3 = Color3.new(1, 0.5, 0)
	end
	--
	for x = -2, 2 do
		local axis = Instance.new("CylinderHandleAdornment", folder)
		axis.CFrame = CFrame.fromEulerAnglesXYZ(0, math.pi/2, 0) * CFrame.new(x, 0, 0)
		axis.Height = width + 0.5
		axis.Radius = 0.05
		axis.Adornee = part
		axis.ZIndex = 0
		axis.Color3 = Color3.new(1, 0.5, 0)
	end
	--
	return folder
end

function clickedButton()
	Plugin:Activate(true)
	sharedToolbarSettings.Button:SetActive(true)
	local toReflect = game.Selection:Get()
	if #toReflect > 0 then
		Dialog.Visible = true
		--
		local waitOn = Instance.new('BindableEvent')
		local wasCancel = false
		local ref_point;
		local ref_normal;
		--
		local cn1 = CancelButton.MouseButton1Down:Connect(function()
			wasCancel = true
			waitOn:Fire()
		end)
		local cn2 = Plugin.Deactivation:Connect(function()
			wasCancel = true
			waitOn:Fire()
		end)
		local cnButton = sharedToolbarSettings.Button.Click:Connect(function()
			wasCancel = true
			waitOn:Fire()
		end)
		--
		local dispPart = createDisplay()
		--
		local Mouse = Plugin:GetMouse()
		local function updateHover()
			local hit, at, normal = 
				workspace:FindPartOnRayWithIgnoreList(
					Ray.new(Mouse.UnitRay.Origin,
						Mouse.UnitRay.Direction*9999),
					{},
					false)
			if hit then
				dispPart.Parent = CoreGui
				dispPart.Display.CFrame =
					CFrameFromTopBack(at,
						normal,
						Spin(normal):Cross(normal).unit)
				ref_point = at
				ref_normal = normal
			else
				dispPart.Parent = nil
			end
		end	
		local cn3 = Mouse.Move:Connect(updateHover)
		local cn4 = Mouse.Idle:Connect(updateHover)
		local cn5 = Mouse.Button1Up:Connect(function()
			waitOn:Fire()
		end)
		--
		waitOn.Event:wait()
		--
		Dialog.Visible = false
		dispPart.Parent = nil
		--
		cn1:Disconnect()
		cn2:Disconnect()
		cn3:Disconnect()
		cn4:Disconnect()
		cn5:Disconnect()
		cnButton:Disconnect()
		--
		if not wasCancel then
			local newToReflect = DoReflect(toReflect, ref_point, ref_normal)
			game.Selection:Set(newToReflect)
			ChangeHistoryService:SetWaypoint("Reflected objects")
		end
	else
		ShowWarningText("Must have at least one object selected!")
	end
	sharedToolbarSettings.Button:SetActive(false)
end

return true
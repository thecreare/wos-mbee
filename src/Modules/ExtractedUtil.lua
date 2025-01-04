local ChangeHistoryService = game:GetService("ChangeHistoryService")

local Logger = require(script.Parent.Logger)

local Util = {}

--https://devforum.roblox.com/t/how-does-roblox-calculate-the-bounding-boxes-on-models-getextentssize/216581/8
function Util.GetBoundingBox(model, orientation)
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
function Util.HistoricEvent(name: string, display_name: string?, callback: ()->(), ...:any): (boolean, string?)
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

function Util.BindToEventWithUndo(event: RBXScriptSignal, name: string, display_name: string?, callback: (...any)->())
	event:Connect(function(...)
		Util.HistoricEvent(name, display_name, callback, ...)
	end)
end

return Util
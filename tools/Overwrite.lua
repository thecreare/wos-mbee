--[[
This tool is used to generate a new parts folder that is a composition of both MB and MBEE

First it creates a set of every part name between both folders
Then merges them together based on the following rules
- Parts in the `EXCLUDE` list are always taken from MBEE
- Parts that only exist in MBEE are taken from MBEE
- Parts that only exist in MB are taken from MB
- Parts that exist in both MB and MBEE are taken from MB
]]

-- Parts that exist in both but have been otherwise modified by MBEE
local EXCLUDE = {
	"GravityGenerator", -- Gravity [1 > 0.15]
	"Light", -- Added `PointLight` instance to light

	-- Changed size from 6x1x1 to 8x1x1 to match other logistic cable types.
	"Pipe",
	"Chute",
	"HeatPipe",
}

local Selection = game:GetService("Selection")

function DeselectAll()
	Selection:Set({})
end

function AwaitClick()
	while true do
		local selected = Selection:Get()[1]
		if selected then
			DeselectAll()
			return selected
		end
		task.wait()
	end
end

DeselectAll()
print(`Please select MB parts folder`)
local baseline = AwaitClick()
print(`Please select MBEE parts folder`)
local customs = AwaitClick()

local OUTPUT_FOLDER = Instance.new("Folder")
OUTPUT_FOLDER.Name = `SyncedPartsFolder_{os.time()}`
OUTPUT_FOLDER.Parent = workspace

local all_parts = {}

for _, v in baseline:GetChildren() do
	if not table.find(all_parts, v.Name) then
		table.insert(all_parts, v.Name)
	end
end

for _, v in customs:GetChildren() do
	if not table.find(all_parts, v.Name) then
		table.insert(all_parts, v.Name)
	end
end

print(all_parts)

for _, part_name in all_parts do
	local baseline_part = baseline:FindFirstChild(part_name) -- MB
	local custom_part = customs:FindFirstChild(part_name) -- MBEE

	local part

	if table.find(EXCLUDE, part_name) then
		-- If part has been modified and should not be overwrote by MB's parts
		part = custom_part:Clone()
	elseif baseline_part and not custom_part then
		-- Part exists in MB but doesn't exist in MBEE
		-- Aka new part was added to wos
		part = baseline_part:Clone()
	elseif custom_part and not baseline_part then
		-- Part exists in MBEE but doesn't exist in MB
		-- Aka developer only part thats not listed in MB or a part was removed from wos
		part = custom_part:Clone()
	elseif custom_part and baseline_part then
		-- Part exists in both MBEE and MB
		-- Take from MB (for updated config reasons)
		part = baseline_part:Clone()
	else
		error("This shouldn't happen")
	end

	part.Parent = OUTPUT_FOLDER
end
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
print(`Please select Source folder`)
local source = AwaitClick()
print(`Please select Destination folder`)
local destination = AwaitClick()

local missing = {}

for _, part in source:GetChildren() do
	-- Check if the destination already has this
	local match = destination:FindFirstChild(part.Name)
	
	if not match then
		print(part)
		table.insert(missing, part)
	end
end

Selection:Set(missing)
print(`There are {#missing} missing parts. They have automatically been selected.`)
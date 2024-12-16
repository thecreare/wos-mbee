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

local to_steal_from_custom = {}

for _, part in all_parts do
	local baseline_part = baseline:FindFirstChild(part)
	local custom_part = customs:FindFirstChild(part)
	
	if baseline_part and not custom_part then
		print(`MB has part {part} and MBEE does not`)
	end
	
	if custom_part and not baseline_part then
		print(`MBEE has part {part} and MB does not`)
	end
	
	if not baseline_part and custom_part then
		table.insert(to_steal_from_custom, custom_part)
	end
end


Selection:Set(to_steal_from_custom)
print(`There are {#to_steal_from_custom} parts that only exist in mbee. They have automatically been selected.`)
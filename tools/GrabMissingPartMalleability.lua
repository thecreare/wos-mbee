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
local source = AwaitClick()

local malleabilities = require(source:Clone())

local wantedKeys = {
	'ProximityButton',
	'FactionHub',
	'Piston',
	'Stanlium',
	'Furnace',
	'TemperatureGate',
	'Transistor',
	'Spheroid',
	'Block',
	'Router',
	'Scanner',
	'HeatValve',
	'SmoothReinforcedGlass',
	'Tank',
	'Insulation',
	'SmoothGlass',
	'TractorBeam',
}

local output = ""
for part, malleability in malleabilities do
	if table.find(wantedKeys, part) then
		if typeof(malleability) == "number" then
			output ..= `{part} = {malleability},\n`
		else
			output ..= `{part} = Vector3.new({malleability}),\n`
		end
	end
end

print(output)
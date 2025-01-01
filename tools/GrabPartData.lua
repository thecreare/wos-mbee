local parts: {BasePart} = game.Selection:Get()[1]:GetChildren()

local PART_DATA = "local PART_DATA = {"
local PART_AMOUNTS = "local WANTED_PARTS = {\n"
for _, part in parts do
	-- Ignore templates
	if part.Color == Color3.fromRGB(248, 248, 248) and part.Material == Enum.Material.Concrete then continue end
	
	-- Deal with 100K and names with spaces
	local name = part.Name
	if name:find(" ") or name:sub(1,1):find("[0123456789]") then
		name = `["{name}"]`
	end
	
	PART_DATA ..= `{name}=\{Color=Color3.new({part.Color})\},`
	PART_AMOUNTS ..= `	{name} = 10,\n`
end

PART_DATA ..= "}"
PART_AMOUNTS ..= "}"

local final = `{PART_DATA}\n\n{PART_AMOUNTS}\n`

local sc = Instance.new("Script")
sc.Source = final
sc.Name = "Export"
sc.Parent = game.ReplicatedStorage
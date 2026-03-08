--[[
	Uses lune to split an rbxmx's children into separate rbxmx files.
	I ran this once to initially export all of the parts into src/Parts
	I doubt it will be needed again but I've included it anyways
]]

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local raw_parts_container = roblox.deserializeModel(fs.readFile("raw_parts.rbxmx"))[1]

for _, instance in raw_parts_container:GetChildren() do
	local serialized_part = roblox.serializeModel({ instance }, true)
	fs.writeFile(`src/Parts/{instance.Name}.rbxmx`, serialized_part)
end

local Util = {}

function Util.GetPartConfig(Part)
	local Configurables = {}
	
	for _, valueObj in pairs(Part:GetChildren()) do
		if valueObj:IsA("ValueBase") then
			local name, val = valueObj.Name, valueObj.Value
			if name == "SDATA" then
				Configurables[1] = val
			else
				Configurables[name] = val
			end
		end
	end
	
	return Configurables
end

return Util

local Logger = require(script.Parent.Logger)

return function(Object: BasePart?)
	if not Object then
        Logger.warn("COLOR COPY FAIL, NO OBJECT")
        return
    end

	for _, v in pairs(Object:GetChildren()) do
		if v.Name ~= "ColorCopy" and not Object:HasTag("ColorTexture") then continue end
		if v:IsA("SpecialMesh") then v.VertexColor = Vector3.new(Object.Color.R, Object.Color.G, Object.Color.B) end
		if v:IsA("Texture") or v:IsA("Decal") then (v :: any).Color3 = Object.Color end
	end
end
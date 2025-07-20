local Selection = game:GetService("Selection")

local Constants = require(script.Parent.Constants)

return function(): { BasePart }
    local list = {}

    local function Handle(child: Instance)
        if not child:IsA("BasePart") then return end
        if Constants.IS_LOCAL and child:FindFirstAncestor(script.Parent.Parent.Name) then return end
        table.insert(list, child)
    end

    for _, v: Instance in Selection:Get() do
        Handle(v)
        for _, child: Instance in v:GetDescendants() do
            Handle(child)
        end
    end

    return list
end
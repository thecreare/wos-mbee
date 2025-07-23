local Selection = game:GetService("Selection")

local AllParts = require(script.Parent.AllParts)
local Constants = require(script.Parent.Constants)
local PluginSettings = require(script.Parent.PluginSettings)

return function(): { BasePart }
    local IGNORE_NON_WOS_PARTS = PluginSettings.Get("IgnoreNonWosParts")
    local IS_LOCAL = Constants.IS_LOCAL
    local list = {}

    local function Handle(child: Instance)
        -- Ignore deleted parts
        if child.Parent == nil then return end
        -- Ignore anything thats not a part
        if not child:IsA("BasePart") then return end
        -- Ignore the parts folder within the plugin
        if IS_LOCAL and child:FindFirstAncestor(script.Parent.Parent.Name) then return end
        -- Ignore parts that aren't registered
        if IGNORE_NON_WOS_PARTS and not AllParts:IsValid(child.Name) then return end
        -- Ignore "wos parts" named "Handle" that are actually descendants of clothing
        -- (edge case to fully not compile humanoid dummy characters in builds)
        if child.Parent:IsA("Accessory") then return end

        -- Finally, count the part
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
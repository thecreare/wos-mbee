local Compilers = require(script.Parent.Compilers)
local Constants = require(script.Parent.Constants)
local Logger = require(script.Parent.Logger)

local PartsFolder = script.Parent.Parent.Parts

local full_part_hash = {}
local list_of_base_parts = {}

local module = {}

function module.GetPartsHash(self)
    return full_part_hash
end

function module.GetBasePartList(self)
    return list_of_base_parts
end

function module.IsValid(self, part_name: string)
    return full_part_hash[part_name] ~= nil
end

function module.AddPart(self, instance: BasePart, is_template: boolean)
    full_part_hash[instance.Name] = {
        Instance = instance,
        IsTemplate = false
    }
    table.insert(list_of_base_parts, instance)
end

function module.RemovePart(self, name: string)
    table.remove(list_of_base_parts, table.find(list_of_base_parts, full_part_hash[name].Instance))
    full_part_hash[name] = nil
end

-- Add parts from the parts folder
for _, part in PartsFolder:GetChildren() :: {Instance} do
    module:AddPart(part :: BasePart, false)
end

-- Add parts that only exist as data
-- This is kidna buggy and only exists for debugging
if Constants.IS_LOCAL then
    for part_name, malleability in Compilers:GetAllMalleability() do
        if full_part_hash[part_name] then continue end
        Logger.warn(`Missing model for part {part_name}. Inserting placeholder.`)
        local Part = Instance.new("Part")
        Part.Color = BrickColor.Random().Color
        if typeof(malleability) == "Vector3" then
            Part.Size = malleability
        else
            Part.Size = Vector3.one*2
        end
        Part.Name = part_name
        Part.Anchored = true
        Part:AddTag("Placeholder")
        Part.Parent = PartsFolder
        module:AddPart(Part, false)
    end
end

return module
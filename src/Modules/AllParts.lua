local PartData = require(script.Parent.Parent.PartData)
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

--- Returns true if `part_name` is a user-created custom part
function module.IsCustom(self, part_name: string)
    return full_part_hash[part_name].IsCustom
end

function module.GetData(self, part_name: string)
    return PartData.Parts[part_name]
end

function module.IsValid(self, part_name: string)
    return full_part_hash[part_name] ~= nil
end

function module.AddPart(self, instance: BasePart, is_custom: boolean?)
    local part_name = instance.Name
    if full_part_hash[part_name] then
        Logger.warn(`"{part_name}" Already in part list`)
        return
    end
    full_part_hash[part_name] = {
        Instance = instance,
        IsCustom = if is_custom == nil then false else is_custom,
    }
    table.insert(list_of_base_parts, instance)
end

function module.RemovePart(self, name: string)
    table.remove(list_of_base_parts, table.find(list_of_base_parts, full_part_hash[name].Instance))
    full_part_hash[name] = nil
end

-- Add parts from the parts folder
for _, part in PartsFolder:GetChildren() :: {BasePart} do
    -- Force correct malleability size (if applicable)
    local malleability = Compilers:GetAllMalleability()[part.Name]
    if typeof(malleability) == "Vector3" then
        part.Size = malleability
    end

    module:AddPart(part :: BasePart)
end

-- Add parts from the latest compiler's template shapes
for _, part in Compilers:GetShapes() do
    module:AddPart(part)
end

local DEV_SHOULD_ADD_BLACKLIST = {"ShapeRemover", "Hull", "Rice", "Blade", "Door"}

-- Add parts that only exist as data
-- This is kidna buggy and only exists for debugging
if Constants.IS_LOCAL then
    local all_malleability = Compilers:GetAllMalleability()
    local dev_should_add = {}
    for part_name, part_data in PartData.Parts do
        if full_part_hash[part_name] then continue end
        Logger.warn(`Missing model for part {part_name}. Inserting placeholder.`)
        if part_data.ClassType ~= "Tool" and (part_data.Spawnable or part_data.Craftable) and not table.find(DEV_SHOULD_ADD_BLACKLIST, part_name) then
            table.insert(dev_should_add, part_name)
        end
        local Part = Instance.new("Part")
        Part.Color = BrickColor.Random().Color
        local malleability = all_malleability[part_name]
        if typeof(malleability) == "Vector3" then
            Part.Size = malleability
        else
            Part.Size = Vector3.one*2
        end
        Part.Name = part_name
        Part.Anchored = true
        Part:AddTag("Placeholder")
        Part.Parent = PartsFolder
        module:AddPart(Part)
    end

    if #dev_should_add > 0 then
        Logger.warn("Of the missing parts, the following should probably be added:\n-", table.concat(dev_should_add, "\n- "))
    else
        Logger.print("None of the missing parts need to be added.")
    end
end

return module
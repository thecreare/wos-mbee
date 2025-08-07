local plugin = _G.plugin
local HttpService = game:GetService("HttpService")

local AllParts = require(script.Parent.AllParts)
local Logger = require(script.Parent.Logger)
local Settings = require(script.Parent.Settings)

local function AddCustomMaterialToAllPartsData(name, data)
    local part = Instance.new("Part")
    part.Anchored = true
    part.Name = name
    for property, value in data do
        if property == "Color" then part.Color = Color3.fromRGB(value[1], value[2], value[3]); continue end
        if property == "Size" then part.Size = Vector3.new(value[1], value[2], value[3]); continue end
        part[property] = value
    end
    part.Parent = script.Parent.Parent.Parts
    AllParts:AddPart(part)
    table.insert(Settings.SearchCategories.resources, name:lower())
    table.insert(Settings.SearchCategories.templateables, name:lower())
    return part
end

local module = {}

module.CustomMaterials = {} :: {[string]: {[string]: any}}

function Load()
    xpcall(function()
        module.CustomMaterials = HttpService:JSONDecode(plugin:GetSetting("SavedCustomMaterials"))

        for name, data in module.CustomMaterials do
            AddCustomMaterialToAllPartsData(name, data)
        end
    end, function(e)
        Logger.warn(`Error encountered when loading custom materials: {e}`)
        module.Clear()
        Logger.warn("Cleared custom materials")
    end)
end

function Save()
    plugin:SetSetting("SavedCustomMaterials", HttpService:JSONEncode(module.CustomMaterials))
end

function module.Add(name, data)
    module.CustomMaterials[name] = data
    Save()
    Logger.print(`{name} was successfully added.`)
    return AddCustomMaterialToAllPartsData(name, data)
end

function module.Remove(name: string)
    module.CustomMaterials[name] = nil
    AllParts:RemovePart(name)
    Save()
    Logger.print(`{name} was successfully removed.`)
end

function module.Clear()
    module.CustomMaterials = {}
    Save()
end

Load()
return module
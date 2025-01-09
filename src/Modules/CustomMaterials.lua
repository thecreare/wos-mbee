local plugin = _G.plugin
local HttpService = game:GetService("HttpService")

local Logger = require(script.Parent.Logger)

local module = {}

module.CustomMaterials = {}

function Load()
    xpcall(function()
        module.CustomMaterials = HttpService:JSONDecode(plugin:GetSetting("SavedCustomMaterials"))
    end, function()
        module.CustomMaterials = {}
    end)
end

function Save()
    plugin:SetSetting("SavedCustomMaterials", HttpService:JSONEncode(module.CustomMaterials))
end

function module.Add(name, data)
    module.CustomMaterials[name] = data
    Save()
    Logger.print(`{name} Was successfully added.`)
end

function module.Remove(name: string)
    module.CustomMaterials[name] = nil
    Save()
    Logger.print(`{name} Was successfully removed.`)
end

function module.Clear()
    module.CustomMaterials = {}
    Save()
end

Load()
return module
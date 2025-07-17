local plugin = _G.plugin
local is_local = if string.find(plugin.Name, ".rbxm") or string.find(plugin.Name, ".lua") then true else false

if is_local then
    -- Developer environment branding
    return {
        NAME = "Model Builder: Edited Edited [DEV]",
        NAME_ABBREVIATION = "MBEE_DEV",
    }
else
    -- Production branding
    return {
        NAME = "Model Builder: Edited Edited",
        NAME_ABBREVIATION = "MBEE",
    }
end
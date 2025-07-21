local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScriptEditorService = game:GetService("ScriptEditorService")

local Branding = require(script.Parent.Branding)
local Logger = require(script.Parent.Logger)
local PluginSettings = require(script.Parent.PluginSettings)

local URL = "https://github.com/ArvidSilverlock/Pilot.lua-Luau-LSP/releases/latest/download/vanilla-types.luau"
local SCRIPT_NAME = "PilotLua"
local SCRIPT_PARENT = ReplicatedStorage
local DEFAULT_PILOT_LUA = script.DefaultPilotLua
local EDITED_BY_USER_ATTRIBUTE = "EditedByUser"
local HEAD = "-- PilotLua Globals: "
local HEADER_TAG = "--[[MBEE_HEADER__DO_NO_EDIT]]"
local ESCAPED_HEADER_TAG = HEADER_TAG:gsub("%[", "%%["):gsub("%]", "%%]")
local cached_response: string?

local function UpdateHeaderInString(str: string)
    assert(cached_response)
    if str == "" then
        return cached_response
    else
        local replaced = str:gsub(`{ESCAPED_HEADER_TAG}.*{ESCAPED_HEADER_TAG}`, cached_response, 1)
        return replaced
    end
end

local function DetermineRequire(script: ModuleScript)
    local contents = script.Source
    local match = contents:match(HEAD .. ".-\n"):gsub(HEAD, ""):sub(1, -2)
    local response = table.concat({
        HEADER_TAG,
        `if game then`,
        `\tPilotLua = require(game.{script:GetFullName()})`,
        `\t{match} = PilotLua()`,
        `end`,
        `-- Automatically generated header, provides typechecking. Disable "{PluginSettings.Info.InsertPilotTypeChecker.Name}" in advanced settings to remove.`,
        HEADER_TAG,
    }, "\n")
    cached_response = response
    return response
end

local function UpdatePilotTypes(): string
    local output_script = SCRIPT_PARENT:FindFirstChild(SCRIPT_NAME)

    -- Remove outdated script
    if output_script and output_script:GetAttribute(EDITED_BY_USER_ATTRIBUTE) ~= true then
        output_script:Destroy()
        output_script = nil
    end
    
    -- Create new module if not exists
    if not output_script then
        local new_script = DEFAULT_PILOT_LUA:Clone()
        new_script.Name = SCRIPT_NAME
        new_script.Parent = SCRIPT_PARENT
        new_script:SetAttribute(EDITED_BY_USER_ATTRIBUTE, false)
        output_script = new_script
    end
    assert(output_script)

    if not PluginSettings.Get("AutomaticPilotTypeUpdates") then
        return DetermineRequire(output_script)
    end

    Logger.print(`Querying microcontroller type checking file...`)
    local ok, response = pcall(HttpService.GetAsync, HttpService, URL)

    if not ok then
        Logger.warn(table.concat({
            "Failed to fetch PilotLua type checking file from Github.",
            "If permission to access Github was denied, that is likely why it failed.",
            `Permission can be granted by going to \"Manage Plugins\" and clicking the edit permissions button (small pencil icon) for {Branding.NAME_ABBREVIATION}.`,
            `If you would like to keep {Branding.NAME_ABBREVIATION} offline and still get the latest type checking module, download the latest file from {URL} and place it in the module script named "{SCRIPT_NAME}" in {SCRIPT_PARENT}. Make sure to change the "{EDITED_BY_USER_ATTRIBUTE}" attribute to "true"`,
        }, "\n"))
        return DetermineRequire(output_script)
    end

    Logger.print(`Successfully got type checking file, ~{math.round(#response/1024)}KB`)

    -- Update PilotLua types module to latest
    ScriptEditorService:UpdateSourceAsync(output_script, function()
        return response
    end)

    return DetermineRequire(output_script)
end

return {
    UpdatePilotTypes = UpdatePilotTypes,
    UpdateHeaderInString = UpdateHeaderInString,
}
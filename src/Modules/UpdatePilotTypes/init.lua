local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScriptEditorService = game:GetService("ScriptEditorService")

local Branding = require(script.Parent.Branding)
local Logger = require(script.Parent.Logger)
local PluginSettings = require(script.Parent.PluginSettings)
local PrettyFormatByteCount = require(script.Parent.PrettyFormatByteCount)

-- Place to direct users to manually download typechecking file
local VANILLA_TYPES_URL = "https://github.com/ArvidSilverlock/Pilot.lua-Luau-LSP/releases/latest/download/vanilla-types.luau"
-- Where to find metadata about the latest release
local LATEST_RELEASE_URL = "https://api.github.com/repos/ArvidSilverlock/Pilot.lua-Luau-LSP/releases/latest"
-- Name of the file in the latest release to download
local GITHUB_TYPECHECKING_FILE_NAME = "vanilla-types.luau"
-- Name of the module script that stores the typechecking
local SCRIPT_NAME = "PilotLua"
-- Where to put the typechecking module script
local SCRIPT_PARENT = ReplicatedStorage
-- The default typechecking version, distributed with the plugin
local DEFAULT_PILOT_LUA = script.DefaultPilotLua
-- The version (as iso date) of the typechecking module distributed with the plugin
local DEFAULT_PILOT_LUA_VERSION = script.DefaultPilotLuaVersion
-- Attribute to store the current version of `SCRIPT_NAME`
local VERSION_ATTRIBUTE = "Version"
-- What to look for to find the list of global exports in `SCRIPT_NAME`
local HEAD = "-- PilotLua Globals: "
-- When inserting the typechecking header into microcontroller scripts, wrap in this comment
local HEADER_TAG = "--[[MBEE_HEADER__DO_NOT_EDIT]]"
-- Old typechecking headers that should be checked for alongside `HEADER_TAG`
local LEGACY_HEADER_TAGS = {"--[[MBEE_HEADER__DO_NO_EDIT]]"}

-- After this module gets called for the first time, its result is cached until the plugin restarts
local cached_response: string?

local function replace(str: string, match)
    assert(cached_response)
    -- Escape comment brackets
    match = match:gsub("%[", "%%["):gsub("%]", "%%]")
    -- Replace text between comments
    return str:gsub(`{match}.*{match}`, cached_response, 1)
end

local function UpdateHeaderInString(str: string)
    assert(cached_response)
    if str == "" then
        return cached_response
    else
        local replaced, replace_count = replace(str, HEADER_TAG)
        for _, tag in LEGACY_HEADER_TAGS do
            if replace_count >= 1 then
                break
            end
            replaced, replace_count = replace(str, tag)
        end
        return replaced
    end
end

local function GetHeaderFromFile(script: ModuleScript)
    local contents = script.Source
    local match = contents:match(HEAD .. ".-\n"):gsub(HEAD, ""):sub(1, -2)
    local response = table.concat({
        HEADER_TAG,
        `if game then`,
        `\tPilotLua = require(game.{script:GetFullName()})`,
        `\t{match} = PilotLua()`,
        `end`,
        `-- Version {script:GetAttribute(VERSION_ATTRIBUTE)}`,
        `-- Automatically generated header, provides typechecking. Disable "{PluginSettings.Info.InsertPilotTypeChecker.Name}" in advanced settings to remove.`,
        HEADER_TAG,
    }, "\n")
    cached_response = response
    return response
end

local function VersionFromIsoDate(date: string)
    return DateTime.fromIsoDate(date).UnixTimestamp
end

local function UpdatePilotTypes(): string
    local STORED_VERSION = VersionFromIsoDate(DEFAULT_PILOT_LUA_VERSION.Value)
    local output_script = SCRIPT_PARENT:FindFirstChild(SCRIPT_NAME)

    -- Remove existing script if its outdated
    if output_script and (output_script:GetAttribute(VERSION_ATTRIBUTE) or 0) < STORED_VERSION then
        output_script:Destroy()
        output_script = nil
    end
    
    -- Create new module if not exists
    if not output_script then
        local new_script = DEFAULT_PILOT_LUA:Clone()
        new_script.Name = SCRIPT_NAME
        new_script.Parent = SCRIPT_PARENT
        new_script:SetAttribute(VERSION_ATTRIBUTE, STORED_VERSION)
        output_script = new_script
    end
    assert(output_script)

    if not PluginSettings.Get("AutomaticPilotTypeUpdates") then
        return GetHeaderFromFile(output_script)
    end

    Logger.print(`Checking latest microcontroller typechecking release information...`)
    local ok, response = pcall(HttpService.GetAsync, HttpService, LATEST_RELEASE_URL)

    if not ok then
        Logger.warn(table.concat({
            "Failed to fetch PilotLua typechecking information from Github.",
            "  - If permission to access Github was denied, that is likely why it failed.",
            `  - Permission can be granted by going to \"Manage Plugins\" and clicking the edit permissions button (small pencil icon) for {Branding.NAME_ABBREVIATION}.`,
            `  - If you would like to deny {Branding.NAME_ABBREVIATION} access to github, you have a few options`,
            `     1. Turn "AutomaticPilotTypeUpdates" off and do nothing. The latest typechecking file is always included in plugin updates`,
            `     2. Turn "AutomaticPilotTypeUpdates" off and manually download new versions.`,
            `        Download the latest version from`,
            `        {VANILLA_TYPES_URL}`,
            `        and place it's contents in "{output_script:GetFullName()}".`,
            `        (only needs to be done if {Branding.NAME_ABBREVIATION} hasn't been updated in a long time)`
        }, "\n"))
        return GetHeaderFromFile(output_script)
    end

    -- Parse API result
    local latest_release_metadata = HttpService:JSONDecode(response)
    local latest_online_version = VersionFromIsoDate(latest_release_metadata.published_at)

    -- Check if downloaded typechecking file is newer or of the same date
    if output_script:GetAttribute(VERSION_ATTRIBUTE) >= latest_online_version then
        Logger.print("Typechecking file is up to date, no new file will be downloaded.") 
        return GetHeaderFromFile(output_script)
    end
    
    -- Find typechecking file download url
    local typechecking_asset
    for _, asset in latest_release_metadata.assets do
        if asset.name == GITHUB_TYPECHECKING_FILE_NAME then
            typechecking_asset = asset
            break
        end
    end

    -- Probably won't happen unless arvid does a silly
    if typechecking_asset == nil then
        Logger.warn(`{GITHUB_TYPECHECKING_FILE_NAME} was not included in the latest release. Please contact Arvid to fix this.`)
        return GetHeaderFromFile(output_script)
    end

    Logger.print(`Downloading microcontroller typechecking file ({PrettyFormatByteCount(typechecking_asset.size)})...`)
    local url = typechecking_asset.browser_download_url
    local ok, response = pcall(HttpService.GetAsync, HttpService, url)

    if not ok then
        Logger.warn(`Failed to fetch typechecking file from {url}`)
        return GetHeaderFromFile(output_script)
    end

    Logger.print(`Successfully got typechecking file.`)

    -- Update PilotLua types module to latest
    ScriptEditorService:UpdateSourceAsync(output_script, function()
        return response
    end)
    output_script:SetAttribute(VERSION_ATTRIBUTE, latest_online_version)

    return GetHeaderFromFile(output_script)
end

return {
    UpdatePilotTypes = UpdatePilotTypes,
    UpdateHeaderInString = UpdateHeaderInString,
}
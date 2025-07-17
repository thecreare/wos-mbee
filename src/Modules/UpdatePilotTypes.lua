local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScriptEditorService = game:GetService("ScriptEditorService")

local Logger = require(script.Parent.Logger)

local URL = "https://github.com/ArvidSilverlock/Pilot.lua-Luau-LSP/releases/latest/download/vanilla-types.luau"
local SCRIPT_NAME = "PilotLua"

local HEAD = "-- PilotLua Globals: "
local function DetermineRequire(script: ModuleScript)
    local contents = script.Source
    local match = contents:match(HEAD .. ".-\n"):gsub(HEAD, "")
    return `local {match} = require(game.{script:GetFullName()})()\n\n`
end

local response_cache

local function UpdatePilotTypes(): string
    local output_script = ReplicatedStorage:FindFirstChild(SCRIPT_NAME)

    local code
    if response_cache then
        code = response_cache
    else
        Logger.print(`Querying microcontroller type checking file...`)
        local ok, response = pcall(HttpService.GetAsync, HttpService, URL)
        if ok then
            Logger.print(`Successfully got type checking file, ~{math.round(#response/1024)}KB`)
        else
            Logger.warn("Failed to update PilotLua type file with error", code)
            if output_script then
                return DetermineRequire(output_script)
            else
                return "-- Failed to fetch PilotLua type checking file. Try restarting studio, if that fails contact creare\n\n"
            end
        end
        response_cache = response
        code = response
    end

    if not output_script then
        local new_script = Instance.new("ModuleScript")
        new_script.Name = SCRIPT_NAME
        new_script.Parent = ReplicatedStorage
        output_script = new_script
    end
    assert(output_script)

    ScriptEditorService:UpdateSourceAsync(output_script, function()
        return code
    end)

    return DetermineRequire(output_script)
end

return UpdatePilotTypes
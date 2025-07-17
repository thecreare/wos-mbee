local ScriptEditorService = game:GetService("ScriptEditorService")

local Logger = require(script.Parent.Logger)
local PluginSettings = require(script.Parent.PluginSettings)

return function(content: string, scriptName: string?, open: boolean?): Script?
	if content == nil then
		return
	end

	local outputScript = Instance.new("Script")
	outputScript.Name = scriptName or "MBEOutput"
	ScriptEditorService:UpdateSourceAsync(outputScript, function(_)
		return content
	end)
	outputScript.Parent = workspace
	if open and PluginSettings.Values.OpenCompilerScripts then
		local success, err = ScriptEditorService:OpenScriptDocumentAsync(outputScript)
		if not success then
			Logger.warn(`Failed to open script document: {err}`)
		end
	end

	return outputScript
end
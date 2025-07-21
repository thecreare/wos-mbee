local HttpService = game:GetService("HttpService")
local ScriptEditorService = game:GetService("ScriptEditorService")
local Selection = game:GetService("Selection")

local Compatibility = require(script.Parent.Compatibility)
local Compilers = require(script.Parent.Compilers)
local CreateOutputScript = require(script.Parent.CreateOutputScript)
local ExtractedUtil = require(script.Parent.ExtractedUtil)
local Logger = require(script.Parent.Logger)
local Fusion = require(script.Parent.Parent.Packages.fusion)
local PluginSettings = require(script.Parent.PluginSettings)
local CompileUploader = require(script.Parent.Uploader)

local peek = Fusion.peek

local compilerSettings = {
	Offset = Vector3.zero,
	ShowTODO = false,
}

local UploadExpireTypes = {
	["single use"] = "onetime",
	["never expire"] = "never",
	["1 hour"] = "3600",
	["1 week"] = "604800",
	["1 month"] = "2592000",
}

function ClearScriptsOfName(name: string)
	repeat
		local sc = workspace:FindFirstChild(name)
		if sc then sc:Destroy() end
	until not workspace:FindFirstChild(name)
end

local function generateRandId()
	-- Max is 64 https://discord.com/channels/616089055532417036/685118583713562647/1296564993679953931
	local length = 16
	-- inclusive safe utf-8 charcters to use for the antenna ID
	local minchar = 33
	local maxchar = 126

	local id = table.create(length)
	for i = 1, length do
		id[i] = string.char(math.random(minchar, maxchar))
	end
	return table.concat(id)
end

local function GetSelection()
	local SelectionParts = {}
	local SelectionVectors = {}
	local SelectionCFrames = {}
	--add selection descendants to table
	for _,s in pairs(Selection:Get()) do
		if s:IsA("BasePart") then --parts
			SelectionParts[#SelectionParts+1] = s
			SelectionVectors[#SelectionVectors+1] = s.Position
			table.insert(SelectionCFrames, s.CFrame)
		else --models
			for _,p in pairs(s:GetDescendants()) do
				if p:IsA("BasePart") then
					SelectionParts[#SelectionParts+1] = p
					SelectionVectors[#SelectionVectors+1] = p.Position
					table.insert(SelectionCFrames, p.CFrame)
				end
			end
		end
	end
	return SelectionParts, SelectionVectors, SelectionCFrames
end

return function()
	ExtractedUtil.HistoricEvent("Compile", "Compile Model", function()
		if peek(PluginSettings.Values.ReplaceCompiles) then
			ClearScriptsOfName("MBEOutput")
			ClearScriptsOfName("MBEEOutput")
		end

		if peek(PluginSettings.Values.ReplaceUploads) then
			ClearScriptsOfName("MBEOutput_Upload")
			ClearScriptsOfName("MBEEOutput_Upload")
		end

		Logger.print("COLLECTING PARTS...")
		local SelectionParts, SelectionVectors, SelectionCFrames = GetSelection()
		Logger.print(`{#SelectionParts} PARTS COLLECTED`)

		-- Get Model Offset (currently unused ingame?)
		local components = string.split(peek(PluginSettings.Values.ModelOffset):gsub("%s+", ""), ",")
		local offset = Vector3.new(tonumber(components[1]), tonumber(components[2]), tonumber(components[3]))
		-- Calculate center of selection
		local origin = ExtractedUtil.AverageVector3s(SelectionVectors)
		-- Set final origin of compiled model
		compilerSettings.Offset = origin + offset

		local alreadyMadeIds = {}

		compilerSettings.Overrides = {
			-- Fill in randomized configs
			function(key: string, value: any)
				-- format: `%<number>` eg: %2
				if typeof(value) ~= "string" then return end	-- Only run on string values
				if value:sub(1, 1) ~= "%" then return end -- Only run on ones that match format

				if alreadyMadeIds[value] then
					return alreadyMadeIds[value]
				end

				local randId = generateRandId()
				alreadyMadeIds[value] = randId
				return randId
			end,

			-- Handle compat updates
			function(key: string, value: any)
				local values = Compatibility.COMPAT_CONFIG_REPLACEMENTS[key]
				if values then
					local replace = values[value]
					if replace then
						return replace
					end
				end
			end
		}

		--show result
		Logger.print("COMPILE STARTED...")
		local startCompile = os.clock()
		local encoded = Compilers:GetSelectedCompiler():Compile(SelectionParts, compilerSettings)
		local Compilation = HttpService:JSONEncode(encoded)

		local COMPILE_LEN = #Compilation

		Logger.print("FIXING PARTSHIFT")

		-- Hacky solution to fix part shift & unanchored parts
		local fixedCount = 0
		for i, part in SelectionParts do
			if part.CFrame ~= SelectionCFrames[i] then
				fixedCount += 1
			end
			-- Remove any snaps
			for _, snap in part:GetChildren() do
				if snap:IsA("Snap") then
					snap:Destroy()
				end
			end
			-- Reset parts to correct state
			part.Anchored = true
			part.CFrame = SelectionCFrames[i]
		end

		if fixedCount > 0 then
			Logger.warn(`Reverted compiler induced part shift on {fixedCount} parts`)
		end

		local elapsed = string.format("%.3f", os.clock() - startCompile)
		Logger.print(`COMPILE FINISHED IN: {elapsed} s.`)
		Logger.print(`COMPILE SIZE: {COMPILE_LEN} CHARACTERS (~{string.format("%.1f", COMPILE_LEN/1024)}KB)`)

		local compile_host = peek(PluginSettings.Values.CompileHost)

		-- Gist uploads
		if compile_host:lower() == 'gist' then
			local upload_name = peek(PluginSettings.Values.UploadName)
            local key = peek(PluginSettings.Values.APIKey)
			local url = CompileUploader.GistUpload(Compilation, key, upload_name)
            assert(url, "Gist upload failed")
			CreateOutputScript(url, "MBEEOutput_Upload", true)
			return
		
		-- dpaste.org uploads
		elseif compile_host:lower() == 'hastebin' then
			local expires = UploadExpireTypes[peek(PluginSettings.Values.UploadExpireTime)] or "3600"
			local url = CompileUploader.HastebinUpload(Compilation, expires)
            assert(url, "Hastebin upload failed")
			CreateOutputScript(url, "MBEEOutput_Upload", true)
			return
		
		-- Standard offline output
		elseif COMPILE_LEN <= 200000 then
			CreateOutputScript(Compilation, "MBEEOutput", true)

		-- Split offline output for huge compiles
		else
			Logger.warn(`COMPILE EXCEEDS 200000 CHARACTERS ({COMPILE_LEN}). AUTOMATICALLY SPLIT INTO MULTIPLE SCRIPTS.`)

			local folder = Instance.new("Folder")
			folder.Name = "MBEEOutput_" .. tostring(math.round(tick()))
			folder.Parent = workspace

			for i=0, math.ceil(COMPILE_LEN / 200000) - 1 do
				local source = string.sub(Compilation, 1 + 199999 * i, COMPILE_LEN >= (199999 + 199999 * i) and 199999 + 199999 * i or COMPILE_LEN)
				local OutputScript = CreateOutputScript(source, "Output #" .. i + 1, false)
                assert(OutputScript, `Failed to create output script #{i}`)
				OutputScript.Parent = folder
				if peek(PluginSettings.Values.OpenCompilerScripts) then
					local success, err = ScriptEditorService:OpenScriptDocumentAsync(OutputScript)
					if not success then
						Logger.warn(`Failed to open script document: {err}`)
					end
				end
			end
		end

	end)
end
local http = game:GetService("HttpService")

local Log = require(script.Parent.Logger)

local module = {}

function module.HastebinUpload(content: string, expires: string): string
	local dataFields = {
		content = content,
		--content = "test",
		--lexer = "Plain Text",
		expires = expires,
		format =  "url", -- How dpaste.org should return the url
	}
	
	local data = ""
	for k, v in pairs(dataFields) do
		-- Im worried :UrlEncode() might be slow for large compiles
		data = data .. ("&%s=%s"):format(http:UrlEncode(k), http:UrlEncode(v))
	end
	data = data:sub(2) -- Remove the first &
	
	
	local success, response, err = pcall(function()
		return http:PostAsync("https://dpaste.org/api/", data, Enum.HttpContentType.ApplicationUrlEncoded, false)
	end)
	
	if not success then
		warn("[MB:E:E] HASTEBIN AUTO PUBLISH ERROR: " .. (err or response or 'UNKNOWN'))
		print(response)
		return nil
	else
		warn("[MB:E:E] SUCCESSFULLY AUTO PUBLISHED AS A HASTE. EXPIRE TIME: " .. expires)
		return response:sub(1, -2) .. "/raw"
	end

end

function module.GistUpload(content: string, APIKey: string, uploadName: string?): string
	uploadName = uploadName or "MBEE_Upload"
	
	local FormattedCompilation = content:gsub("\\\"", "\""):gsub('"', '\\"')
	local success, response, err = pcall(function()
		local body = '{"description":"Roblox Studio creation auto-uploaded by MBEE", "public":false,"files":{"' .. uploadName .. '.json":{"content":"' .. FormattedCompilation .. '"}}}'
		local response = http:PostAsync("https://api.github.com/gists", body, Enum.HttpContentType.ApplicationJson, false, {Authorization = "token " .. APIKey})
		return http:JSONDecode(response)
	end)

	if not success then
		warn("[MB:E:E] GIST AUTO PUBLISH ERROR: " .. (err or response or 'UNKNOWN'))
	else
		warn("[MB:E:E] SUCCESSFULLY AUTO PUBLISHED AS A GIST")
		--for _, v in response.files do
		--	local GistScript = Instance.new("Script")
		--	GistScript.Name = "MBEOutput_Upload"
		--	GistScript.Source = v.raw_url
		--	GistScript.Parent = workspace
		--	plugin:OpenScript(GistScript)
		--	table.insert(createdScripts, GistScript)
		--end
		return response.files[1].raw_url
	end
end

return module

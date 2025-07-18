local http = game:GetService("HttpService")

local Log = require(script.Parent.Logger)
local warn = Log.warn

local module = {}

function module.HastebinUpload(content: string, expires: string): string?
	local data_fields = {
		content = content,
		lexer = "json",
		expires = expires,
		format =  "url", -- How dpaste.org should return the url
	}

	local data = ""
	for k, v in pairs(data_fields) do
		-- Im worried :UrlEncode() might be slow for large compiles
		data = data .. ("&%s=%s"):format(http:UrlEncode(k), http:UrlEncode(v))
	end
	data = data:sub(2) -- Remove the first &

	local success, response = pcall(function()
		return http:PostAsync("https://dpaste.org/api/", data, Enum.HttpContentType.ApplicationUrlEncoded, false)
	end)

	if not success then
		warn("HASTEBIN AUTO PUBLISH ERROR: " .. (response or 'UNKNOWN'))
		return nil
	else
		warn("SUCCESSFULLY AUTO PUBLISHED AS A HASTE. EXPIRE TIME: " .. expires)
		return response:sub(1, -2) .. "/raw"
	end

end

function module.GistUpload(content: string, APIKey: string, upload_name: string): string?
	local FormattedCompilation = content:gsub("\\\"", "\""):gsub('"', '\\"')
	local success, response = pcall(function()
		local body = '{"description":"Roblox Studio creation auto-uploaded by MBEE", "public":false,"files":{"' .. upload_name .. '.json":{"content":"' .. FormattedCompilation .. '"}}}'
		local response = http:PostAsync("https://api.github.com/gists", body, Enum.HttpContentType.ApplicationJson, false, {Authorization = "token " .. APIKey})
		return http:JSONDecode(response)
	end)

	if not success then
		warn("GIST AUTO PUBLISH ERROR: " .. (response or 'UNKNOWN'))
		return nil
	else
		warn("SUCCESSFULLY AUTO PUBLISHED AS A GIST")
		return response.files[1].raw_url
	end
end

return module

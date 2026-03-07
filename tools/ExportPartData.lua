--[[
	Go to http://webhook.site/ and paste "Your unique URL" into HOOK_URL
	Run in a Microcontroller with attached Modem
	Copy the json in the newly received POST request on your webhook.site panel
]]

local HOOK_URL = "http://webhook.site/xxxxxxxx"

GetPart("Modem"):RequestAsync({
	Url = HOOK_URL,
	Method = "POST",
	Body = JSONEncode(require("partdata")),
	Headers = {["Content-Type"] = "application/json"},
})

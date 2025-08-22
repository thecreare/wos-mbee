--[[
    This script is intended for Microcontrollers
    Export ingame partdata to a webhook
    Place acquired json in `src/PartData/RawData.json`
]]--

-- Replace this with your own https://webhook.site webhook
local URL = "https://webhook.site/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

local PART_DATA = require("partdata")

local Modem = assert(GetPart("Modem"), "Missing Modem")

Modem:RequestAsync({
    Url = URL,
    Method = "POST",
    Headers = {["content-type"] = "application/json"},
    Body = JSONEncode(PART_DATA),
    Compress = Enum.HttpCompression.None,
})

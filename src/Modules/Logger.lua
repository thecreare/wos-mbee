local Branding = require(script.Parent.Branding)

local WARN_TRACEBACK = false
local PREFIX = `[{Branding.NAME_ABBREVIATION}]:`

local function CleanTraceback(traceback: string): string
	return traceback:gsub("user_MBEE.rbxmx.MBEE.MBEE", "MBEE")
end

local module = {}

function module.print(...)
	warn(PREFIX, ...)
end

function module.warn(...)
	if WARN_TRACEBACK then
		warn(PREFIX, ..., CleanTraceback(debug.traceback()))
	else
		warn(PREFIX, ...)
	end
end

function module.error(...)
	warn(PREFIX, ..., CleanTraceback(debug.traceback()))
end

return module

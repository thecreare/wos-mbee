local WARN_TRACEBACK = false
local PREFIX_BASE = "MBEE"

local function GetPrefix()
	return `[{PREFIX_BASE}]:`
end

local module = {}

function module.print(...)
	warn(GetPrefix(), ...)
end

function module.warn(...)
	if WARN_TRACEBACK then
		warn(GetPrefix(), ..., debug.traceback())
	else
		warn(GetPrefix(), ...)
	end
end

function module.error(...)
	warn(GetPrefix(), ..., debug.traceback())
end

return module

local WARN_TRACEBACK = false
local PREFIX_BASE = "MBEE"

local function GetPrefix(): string
	return `[{PREFIX_BASE}]:`
end

local function CleanTraceback(traceback: string): string
	return traceback:gsub("user_MBEE.rbxmx.MBEE.MBEE")
end

local module = {}

function module.print(...)
	warn(GetPrefix(), ...)
end

function module.warn(...)
	if WARN_TRACEBACK then
		warn(GetPrefix(), ..., CleanTraceback(debug.traceback()))
	else
		warn(GetPrefix(), ...)
	end
end

function module.error(...)
	warn(GetPrefix(), ..., CleanTraceback(debug.traceback()))
end

return module

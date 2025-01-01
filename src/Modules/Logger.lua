local module = {}
function module.print(...)
	warn("[MBEE]:", ...)
end
function module.warn(...)
	warn("[MBEE]:", ..., debug.traceback())
end
return module

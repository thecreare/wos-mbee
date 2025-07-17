local ENUM_NAMES_CACHE = {}
return function(enum: Enum): {string}
	if ENUM_NAMES_CACHE[enum] then return ENUM_NAMES_CACHE[enum] end

	local names = {}

	for _, name in enum:GetEnumItems() do
		table.insert(names, name.Name)
	end

	ENUM_NAMES_CACHE[enum] = names
	return names
end
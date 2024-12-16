-- Written by Joe, didn't do any benchmarks so it's probably slow
local B64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local PAD_CHAR = "="
local b64lookup = {}
for i = 0, 63 do
	local c = B64_CHARS:sub(i + 1, i + 1)
	b64lookup[i] = c
	b64lookup[c] = i
end
local function b64encode(str)
	local result = {}
	local i = 1
	while i <= #str do
		local a, b, c = string.byte(str, i, i+2)

		result[#result + 1] = table.concat({
			b64lookup[bit32.band(0b11111100, a)/4],
			b64lookup[bit32.band(0b00000011, a)*16 + bit32.band(0b11110000, b or 0)/16],
			b and b64lookup[bit32.band(0b00001111, b)*4 + bit32.band(0b11000000, c or 0)/64] or PAD_CHAR,
			c and b64lookup[bit32.band(0b00111111, c)] or PAD_CHAR
		}, "")

		i = i + 3
	end
	return table.concat(result, "")
end
local function b64decode(str)
	local result = {}
	for i = 1, #str, 4 do
		local a, b, c, d = b64lookup[str:sub(i, i)], b64lookup[str:sub(i+1, i+1)], b64lookup[str:sub(i+2, i+2)], b64lookup[str:sub(i+3, i+3)]

		result[#result + 1] = string.char(unpack({
			a*4 + bit32.band(0b00110000, b)/16,
			c and (bit32.band(0b00001111, b)*16 + bit32.band(0b00111100, c)/4) or nil,
			d and (bit32.band(0b00000011, c)*64 + d) or nil
		}))
	end
	return table.concat(result, "")
end
return {b64encode, b64decode}
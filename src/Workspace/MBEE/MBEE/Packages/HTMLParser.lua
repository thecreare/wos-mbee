-- HTML Parsing Object
-- @author Validark


local function _Load_Library_(Name)
	return require(script.Parent[Name])
end
local Table = _Load_Library_("Table")

local HTMLParser = {}
HTMLParser.__index = {Position = 0}

function HTMLParser.new(HTML)
	return setmetatable({
		HTML = HTML:gsub("%s+", " "):gsub("> <", "><"):gsub(" >", ">"):gsub("< ", "<");
	}, HTMLParser)
end

function HTMLParser.__index:Next()
	local StartPosition
	StartPosition, self.Position = self.HTML:find("<([^>]+)>([^<]*)", self.Position + 1)

	if StartPosition then
		self.Tag, self.Data = self.HTML:sub(StartPosition, self.Position):match("<([^>]+)>([^<]*)")
	else
		self.Tag, self.Data = nil, nil
	end

	return self
end

return Table.Lock(HTMLParser)

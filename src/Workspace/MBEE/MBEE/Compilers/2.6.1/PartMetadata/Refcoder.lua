local Refcoder = {}

local function minByteSize(maxInt: number)
    return math.max(1, math.ceil(math.log(maxInt + 1, 256)))
end

local UNPACK_STEP_SIZE = 1000 -- How many array items can be unpacked at once
local function getMaxValue(values: { number })
    local maxValue = 0
    local count = #values
    for i = 0, math.ceil(count / UNPACK_STEP_SIZE) - 1 do
        local from = i * UNPACK_STEP_SIZE + 1
        local to = math.min(from + UNPACK_STEP_SIZE, count)
        maxValue = math.max(maxValue, table.unpack(values, from, to))
    end
    return maxValue
end

local function packArrayOf<T>(array: { T }, itemFormat: string)
    itemFormat = `<{itemFormat}`

    local arraySize = #array
    local sectionCount = math.ceil(arraySize / UNPACK_STEP_SIZE)

    local sections = table.create(sectionCount)
    for i = 0, sectionCount - 1 do
        local from = i * UNPACK_STEP_SIZE + 1
        local to = math.min(from + UNPACK_STEP_SIZE, arraySize)
        local size = to - from + 1

        table.insert(sections, string.pack(string.rep(itemFormat, size), table.unpack(array, from, to)))
    end
    return table.concat(sections)
end

local function unpackArrayOf<T>(data: string, arraySize: number, itemFormat: string, pointer: number?)
    itemFormat = `<{itemFormat}`

    local sectionCount = math.ceil(arraySize / UNPACK_STEP_SIZE)

    local output = table.create(sectionCount)
    for i = 0, sectionCount - 1 do
        local from = i * UNPACK_STEP_SIZE + 1
        local to = math.min(from + UNPACK_STEP_SIZE, arraySize)
        local size = to - from + 1

        local results = table.pack(string.unpack(string.rep(itemFormat, size), data, pointer))
        pointer = table.remove(results, results.n)

        table.move(results, 1, results.n - 1, from, output)
    end
    return output, pointer
end

local function encodeRefId(refId: number)
    local refSize = minByteSize(math.max(0, refId))
    return string.pack(`<BI{refSize}`, refSize, refId)
end
local function decodeRefId(data: string, readStart: number?)
    local refSize, pointer = string.unpack("<B", data, readStart)
    return string.unpack(`I{refSize}`, data, pointer)
end

local function encodeRefArray(refs: { number })
    local refSize = minByteSize(getMaxValue(refs))
    return `{string.pack("<I4B", #refs, refSize)}{packArrayOf(refs, `I{refSize}`)}`
end
local function decodeRefArray(data: string, readStart: number?)
    local length, refSize, pointer = string.unpack("<I4B", data, readStart)
    return unpackArrayOf(data, length, `I{refSize}`, pointer)
end

local function encodeStringArray(strings: { string })
    return `{string.pack("<I4", #strings)}{packArrayOf(strings, "s8")}`
end
local function decodeStringArray(data: string, readStart: number?)
    local length, pointer = string.unpack("<I4", data, readStart)
    return unpackArrayOf(data, length, "s8", pointer)
end

local function encodeRefTable(indices: { number }, values: { number })
    return `{encodeRefArray(indices)}{encodeRefArray(values)}`
end
local function decodeRefTable(data: string, readStart: number?)
    local indices, pointer = decodeRefArray(data, readStart)
    local values
    values, pointer = decodeRefArray(data, pointer)

    return indices, values, pointer
end

local VALID_TYPES = { "string", "number", "boolean", "table", "Vector3", "CFrame", "static", "copy_of", "symbol" }
local TYPE_STATIC = assert(table.find(VALID_TYPES, "static"))
local TYPE_COPY_OF = assert(table.find(VALID_TYPES, "copy_of"))
local TYPE_SYMBOL = assert(table.find(VALID_TYPES, "symbol"))

-- Symbols
local SYMBOLS = {}
local function Symbol(identifier: any)
    local symbol = SYMBOLS[identifier]
    if not symbol then
        symbol = newproxy()
        SYMBOLS[identifier] = symbol
        SYMBOLS[symbol] = identifier
    end
    return symbol
end

local SYMBOL_NAN = Symbol("nan")
local SYMBOL_DATA = Symbol("data")

type EncodeState = {
    References: { [any]: number },
    Encodings: { [number]: any },
    EncodingsToRefs: { [string]: number },
    Top: number,
    Statics: { [any]: any },
}
type DecodeState = {
    Decodings: { [number]: any },
    Encodings: { [number]: any },
    Statics: { [any]: any },
}

local encode
local function encodeValue(encoded: string, typeIndex: number)
    return `{string.pack("<B", typeIndex or 0)}{encoded or ""}`
end

-- Uses top & increments it by 1
local function reserveRefId(state: EncodeState)
    -- Select the next reference ID
    local refId = state.Top
    state.Top += 1
    return refId
end

-- Stores an encoded value, but checks if it is possible to store a copy_of instead
local function storeDataUnique(state: EncodeState, refId: number, encoded: string?)
    if not encoded then
        return
    end

    -- Look for a ref with duplicate data
    local encodingId = state.EncodingsToRefs[encoded]
    if encodingId then
        -- Replace with a copy_of for the encoded data
        encoded = encodeValue(encodeRefId(encodingId), TYPE_COPY_OF)
    else
        -- Store the ref ID of this data
        state.EncodingsToRefs[encoded] = refId
    end
    state.Encodings[refId] = encoded
end

-- Clones while ignoring __metatable non-intrusively, additionally returning the metatable if succeessful
local function clone_safe(tab)
    local success, clone = pcall(table.clone, tab)
    return if success then clone else nil, if success then getmetatable(clone) else nil
end

-- Gets or creates metadata in the given table
local function getMetadata(value)
    local metadata = value[SYMBOL_DATA]
    if not metadata then
        metadata = {}
        value[SYMBOL_DATA] = metadata
    end
    return metadata
end

local function writeRef(refId: number, value: any, state: EncodeState, isStatic: boolean?)
    -- Insert the encoding & ref ID
    state.References[value] = refId

    -- Look for an unlocked metatable
    if refId ~= 1 and type(value) == "table" then
        local clone, metatable = clone_safe(value)
        if metatable then
            -- Write the metatable into the metadata
            local metadata = getMetadata(clone)
            metadata.metatable = metatable

            -- Replace the value with the clone
            value = clone
        end
    end

    -- Store packed data for the ref ID
    storeDataUnique(state, refId, encodeValue(encode(value, state, isStatic)))
end

local function getRefId(value: any, state: EncodeState, isStatic: boolean?)
    -- nil
    if value == nil then
        return nil
    end

    -- NaN
    if value ~= value then
        value = SYMBOL_NAN
    end

    -- Look for an existing ID by reference
    local refId = state.References[value]
    if not refId then
        -- One doesn't exist, so reserve a new one
        refId = reserveRefId(state)

        -- Write the data at the reserved ref ID
        writeRef(refId, value, state, isStatic)
    end
    return refId
end

function encode(value: any, state: EncodeState, isStatic: boolean?)
    local typeIndex = table.find(VALID_TYPES, typeof(value)) or table.find(VALID_TYPES, type(value))

    local statics = state.Statics
    if isStatic and statics[value] ~= nil then
        return encodeRefId(getRefId(statics[value], state, true)), TYPE_STATIC
    elseif type(value) == "userdata" and SYMBOLS[value] then
        return encodeRefId(getRefId(SYMBOLS[value], state, true)), TYPE_SYMBOL
    elseif type(value) == "string" then
        return value, typeIndex
    elseif type(value) == "number" then
        return string.pack("<n", value), typeIndex
    elseif type(value) == "boolean" then
        return if value then "\0" else "", typeIndex
    elseif typeof(value) == "Vector3" then
        return string.pack("<nnn", value.X, value.Y, value.Z), typeIndex
    elseif typeof(value) == "CFrame" then
        return string.pack(`<{string.rep("nnn", 4)}`, value:GetComponents()), typeIndex
    elseif type(value) == "table" then
        -- Count all entries
        local size = 0
        for _index, _value in value do
            size += 1
        end

        -- Collect all index/value refs into an indices/values list
        local indices = table.create(size)
        local values = table.create(size)
        for subIndex, subValue in value do
            table.insert(indices, getRefId(subIndex, state))
            table.insert(values, getRefId(subValue, state))
        end

        -- Encode the keys/values
        return encodeRefTable(indices, values), typeIndex
    end
    return nil
end

local decodeByRefId
local function decode(refId: number, encoded: string, state: DecodeState)
    local valueTypeId, pointer = string.unpack("<B", encoded)
    local valueType = VALID_TYPES[valueTypeId]
    if not valueType then
        return nil
    end

    local value = string.sub(encoded, pointer)
    if valueType == "static" then
        return state.Statics[decodeByRefId(decodeRefId(value), state)]
    elseif valueType == "string" then
        return value
    elseif valueType == "number" then
        return string.unpack("<n", value)
    elseif valueType == "boolean" then
        return value == "\0"
    elseif valueType == "Vector3" then
        return Vector3.new(string.unpack("<nnn", value))
    elseif valueType == "CFrame" then
        return CFrame.new(string.unpack(`<{string.rep("nnn", 4)}`, value))
    elseif valueType == "table" then
        local decoded = {}
        state.Decodings[refId] = decoded

        local indices, values = decodeRefTable(value)

        for i, indexRefId in ipairs(indices) do
            local valueRefId = values[i]
            local index = decodeByRefId(indexRefId, state)
            local value = decodeByRefId(valueRefId, state)

            if index == nil or value == nil then
                continue
            end

            -- Special table metadata
            if refId ~= 1 and index == SYMBOL_DATA then
                -- Load the stored metatable
                local metatable = value.metatable
                if metatable then
                    setmetatable(decoded, metatable)
                end
                continue
            end
            decoded[index] = value
        end
        return decoded
    elseif valueType == "copy_of" then
        local encodingId = decodeRefId(value)
        if not encodingId then
            return nil
        end

        -- Grab the data stored for the target ref directly, and decode it
        return decode(refId, state.Encodings[encodingId], state)
    elseif valueType == "symbol" then
        local symbol = SYMBOLS[decodeByRefId(decodeRefId(value), state)]
        if symbol == SYMBOL_NAN then
            return 0 / 0
        end
        return symbol
    end
    return nil
end

function decodeByRefId(refId: number, state: DecodeState)
    -- Look up the decoded value, and return it if it already exists
    local decoded = state.Decodings[refId]
    if decoded ~= nil then
        return decoded
    end

    -- Look up the encoded value, if it is defined
    local encoded = state.Encodings[refId]
    if not encoded then
        return nil
    end

    -- Decode the encoded value
    decoded = decode(refId, encoded, state)
    state.Decodings[refId] = decoded

    return decoded
end

local function invertTable<K, V>(tab: { [K]: V }): { [V]: K }
    local out = table.create(#tab)
    for index, value in tab do
        out[value] = index
    end
    return out
end

function Refcoder.encode<K, V>(data, statics: { [K]: V }?)
    -- Define state
    local state = {
        References = {},
        Encodings = {},
        EncodingsToRefs = {},
        Top = 2, -- ID 1 is reserved for the header
        Statics = statics or {},
    }

    -- Write the header, ignoring statics
    writeRef(1, {
        [SYMBOL_DATA] = data,
    }, state, true)

    return encodeStringArray(state.Encodings)
end

function Refcoder.decode<K, V>(data, statics: { [K]: V }?, readStart: number?)
    -- Define state
    local state = {
        Encodings = decodeStringArray(data, readStart),
        Decodings = {},
        Statics = invertTable(statics or {}),
    }

    -- Decode header
    local header = decodeByRefId(1, state)

    -- Return the decoded data
    return header[SYMBOL_DATA]
end

return Refcoder

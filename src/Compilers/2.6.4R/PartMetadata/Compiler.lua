local Refcoder = require(script.Parent.Refcoder)

local COMPILER_VERSION = 0

local Compiler = {}

local V3_X_OFFSET = 0
local V3_Y_OFFSET = V3_X_OFFSET + 4
local V3_Z_OFFSET = V3_Y_OFFSET + 4

local VECTOR3_SIZE = 3 * 4

local function readVector3(data: buffer, offset: number)
    return Vector3.new(
        buffer.readf32(data, offset + V3_X_OFFSET),
        buffer.readf32(data, offset + V3_Y_OFFSET),
        buffer.readf32(data, offset + V3_Z_OFFSET)
    )
end

local function writeVector3(data: buffer, offset: number, vector3: Vector3)
    buffer.writef32(data, offset + V3_X_OFFSET, vector3.X)
    buffer.writef32(data, offset + V3_Y_OFFSET, vector3.Y)
    buffer.writef32(data, offset + V3_Z_OFFSET, vector3.Z)
end

local CF_POSITION_OFFSET = 0
local CF_XVECTOR_OFFSET = CF_POSITION_OFFSET + VECTOR3_SIZE
local CF_YVECTOR_OFFSET = CF_XVECTOR_OFFSET + VECTOR3_SIZE

local CFRAME_SIZE = VECTOR3_SIZE * 3

local function readCFrame(data: buffer, offset: number)
    return CFrame.fromMatrix(
        readVector3(data, offset + CF_POSITION_OFFSET),
        readVector3(data, offset + CF_XVECTOR_OFFSET),
        readVector3(data, offset + CF_YVECTOR_OFFSET)
    )
end

local function writeCFrame(data: buffer, offset: number, cframe: CFrame)
    writeVector3(data, offset + CF_POSITION_OFFSET, cframe.Position)
    writeVector3(data, offset + CF_XVECTOR_OFFSET, cframe.XVector)
    writeVector3(data, offset + CF_YVECTOR_OFFSET, cframe.YVector)
end

local C3_R_OFFSET = 0
local C3_G_OFFSET = C3_R_OFFSET + 1
local C3_B_OFFSET = C3_G_OFFSET + 1

local COLOR3_SIZE = 3

local function readColor3(data: buffer, offset: number)
    return Color3.fromRGB(
        buffer.readu8(data, offset + C3_R_OFFSET),
        buffer.readu8(data, offset + C3_G_OFFSET),
        buffer.readu8(data, offset + C3_B_OFFSET)
    )
end

local function writeColor3(data: buffer, offset: number, color: Color3)
    local r = color.R * 255
    local g = color.G * 255
    local b = color.B * 255

    buffer.writeu8(data, offset + C3_R_OFFSET, r)
    buffer.writeu8(data, offset + C3_G_OFFSET, g)
    buffer.writeu8(data, offset + C3_B_OFFSET, b)
end

local SURFACES_SIZE = 3

local function readSurfaces(data: buffer, offset: number)
    local lower = buffer.readu16(data, offset)
    local upper = buffer.readu8(data, offset + 2)

    return lower + upper * 2 ^ 16
end

local function writeSurfaces(data: buffer, offset: number, surfaces: number)
    local lower = surfaces % 2 ^ 16
    local upper = surfaces // 2 ^ 16

    buffer.writeu16(data, offset, lower)
    buffer.writeu8(data, offset + 2, upper)
end

local USERID_SIZE = 8

local function readUserId(data: buffer, offset: number)
    local lower = buffer.readu32(data, offset)
    local upper = buffer.readu32(data, offset + 4)

    return lower + upper * 2 ^ 32
end

local function writeUserId(data: buffer, offset: number, userId: number)
    local lower = userId % 2 ^ 32
    local upper = userId // 2 ^ 32

    buffer.writeu32(data, offset, lower)
    buffer.writeu32(data, offset + 4, upper)
end

local PART_CFRAME_OFFSET = 0
local PART_SIZE_OFFSET = PART_CFRAME_OFFSET + CFRAME_SIZE
local PART_COLOR_OFFSET = PART_SIZE_OFFSET + VECTOR3_SIZE
local PART_SURFACES_OFFSET = PART_COLOR_OFFSET + COLOR3_SIZE
local PART_LOCK_OFFSET = PART_SURFACES_OFFSET + SURFACES_SIZE
local PART_CREATED_OFFSET = PART_LOCK_OFFSET + USERID_SIZE
local PART_CONFIGURED_OFFSET = PART_CREATED_OFFSET + USERID_SIZE
local PART_PERMS_OFFSET = PART_CONFIGURED_OFFSET + USERID_SIZE
local PART_HEALTH_OFFSET = PART_PERMS_OFFSET + 1

local PART_DATA_SIZE = CFRAME_SIZE + VECTOR3_SIZE + COLOR3_SIZE + SURFACES_SIZE
local PART_META_SIZE = USERID_SIZE * 3 + 1 + 4

local function readPart(data: buffer, offset: number, config: SaveConfig, metadata: { HealthFixed: boolean? })
    local cframe = readCFrame(data, offset + PART_CFRAME_OFFSET)
    local size = readVector3(data, offset + PART_SIZE_OFFSET)
    local color = readColor3(data, offset + PART_COLOR_OFFSET)
    local surfaces = readSurfaces(data, offset + PART_SURFACES_OFFSET)

    local partData = {
        CFrame = cframe,
        Size = size,
        Color = color,
        Surfaces = surfaces,
    }

    if config.UseStateData then
        local partLocked = readUserId(data, offset + PART_LOCK_OFFSET)
        local partCreator = readUserId(data, offset + PART_CREATED_OFFSET)
        local partConfigurer = readUserId(data, offset + PART_CONFIGURED_OFFSET)

        local lockGroup = buffer.readu8(data, offset + PART_PERMS_OFFSET)
        local health = buffer.readu32(data, offset + PART_HEALTH_OFFSET) / (2 ^ 32 - 1)

        if not metadata.HealthFixed then
            health = 1
        end

        partData.LockedBy = if partLocked ~= 0 then partLocked else nil
        partData.CreatedBy = if partCreator ~= 0 then partCreator else nil
        partData.ConfiguredBy = if partConfigurer ~= 0 then partConfigurer else nil

        partData.LockGroup = lockGroup
        partData.Health = health
    end

    return partData
end

local function writePart(data: buffer, offset: number, partData: PartDataSparse, config: SaveConfig)
    writeCFrame(data, offset + PART_CFRAME_OFFSET, partData.CFrame)
    writeVector3(data, offset + PART_SIZE_OFFSET, partData.Size)
    writeColor3(data, offset + PART_COLOR_OFFSET, partData.Color)
    writeSurfaces(data, offset + PART_SURFACES_OFFSET, partData.Surfaces)

    if config.UseStateData then
        writeUserId(data, offset + PART_LOCK_OFFSET, partData.LockedBy or 0)
        writeUserId(data, offset + PART_CREATED_OFFSET, partData.CreatedBy or 0)
        writeUserId(data, offset + PART_CONFIGURED_OFFSET, partData.ConfiguredBy or 0)

        buffer.writeu8(data, offset + PART_PERMS_OFFSET, partData.LockGroup or 0)
        buffer.writeu32(data, offset + PART_HEALTH_OFFSET, (partData.Health or 0) * (2 ^ 32 - 1))
    end
end

local VERSION_OFFSET = 0
local CONSTANT_LENGTH_OFFSET = 2
local VARIABLE_LENGTH_OFFSET = 6

export type PartData = {
    Assembly: AssemblyData,

    -- Encoded data
    ClassName: string,
    Properties: { [string]: unknown },
    Configuration: { unknown },

    -- Binary data
    CFrame: CFrame,
    Size: Vector3,
    Color: Color3,
    Surfaces: number,

    -- Metadata
    LockedBy: number?,
    CreatedBy: number?,
    ConfiguredBy: number?,

    LockGroup: number?,
    Health: number?,

    -- Joint data
    Welds: { unknown },
    Constraints: { unknown },
    Hinges: { unknown },
    Grounded: boolean?,
}

export type PartDataSparse = {
    -- Encoded data
    ClassName: string,
    Properties: { [string]: unknown },
    Configuration: { unknown },

    -- Binary data
    CFrame: CFrame,
    Size: Vector3,
    Color: Color3,
    Surfaces: number,

    -- Metadata
    LockedBy: number?,
    CreatedBy: number?,
    ConfiguredBy: number?,

    LockGroup: number?,
    Health: number?,

    -- Joint data
    Welds: { unknown },
    Constraints: { unknown },
    Hinges: { unknown },
    Grounded: boolean?,
}

export type AssemblyData = {
    PartCount: number,
    Parts: { PartData },
    CFrame: CFrame,
}

export type AssemblyDataSparse = {
    Parts: { PartData | PartDataSparse },
    CFrame: CFrame,
}

export type SectionDataSparse = {
    Parts: { PartData },
    Assemblies: { AssemblyData },
    Metadata: { [any]: any },
}

export type SectionData = SectionDataSparse & {
    Version: number,
    Offset: number,
}

export type SaveData = {
    Sections: { SectionData },
}

export type SaveDataSparse = {
    Assemblies: { AssemblyData | AssemblyDataSparse },
}

export type SaveConfig = {
    UseStateData: boolean?, -- Load/save special part properties, health, creator, etc
    Throttle: (() -> ())?,
}

local NO_DATA_STRING = "NO_DATA"

export type PartQueryInfo = {
    ClassName: string,
    Configuration: any,
    Properties: any,
    Joints: any,
}

local function querySaveData(saveData: buffer): { PartQueryInfo }
    local length = buffer.len(saveData)

    local offset = 0

    local allPartsData = {}

    while offset < length do
        local constantLength = buffer.readu32(saveData, offset + CONSTANT_LENGTH_OFFSET)
        local variableLength = buffer.readu32(saveData, offset + VARIABLE_LENGTH_OFFSET)
        offset += VARIABLE_LENGTH_OFFSET + 4 + constantLength

        -- Load the variable (refcoder) data
        local encodedData = buffer.readstring(saveData, offset, variableLength)
        local partsData = Refcoder.decode(encodedData) or {}

        offset += variableLength

        -- Copy all of the part data
        table.move(partsData, 1, #partsData, #allPartsData + 1, allPartsData)
    end

    for index, partData in allPartsData do
        local className = partData[1]

        if type(className) ~= "string" then
            continue
        end

        local partInfo = {}

        partInfo.ClassName = className
        partInfo.Configuration = partData[2] or {}
        partInfo.Properties = partData[3] or {}
        partInfo.Joints = partData[4] or {}

        allPartsData[index] = partInfo
    end

    return allPartsData
end

local function decodeSaveData(saveData: string | buffer, config: SaveConfig): SaveData?
    local throttle = config.Throttle or function() end

    if not saveData then
        return nil
    end

    local data = if type(saveData) ~= "buffer" then buffer.fromstring(saveData) else saveData

    if buffer.len(data) == #NO_DATA_STRING and buffer.tostring(data) == NO_DATA_STRING then
        return nil
    end

    local length = buffer.len(data)

    local offset = 0

    local decoded = {}
    decoded.Sections = {}

    local section = 1
    while offset < length do
        throttle()

        local formatVersion = buffer.readu16(data, offset + VERSION_OFFSET)
        local constantLength = buffer.readu32(data, offset + CONSTANT_LENGTH_OFFSET)
        local variableLength = buffer.readu32(data, offset + VARIABLE_LENGTH_OFFSET)
        offset += VARIABLE_LENGTH_OFFSET + 4

        local sectionData: SectionData = {
            Parts = {};
            Assemblies = {};
            Metadata = {};

            Version = formatVersion;
            Offset = offset;
        }

        decoded.Sections[section] = sectionData

        section += 1

        -- Start & end of the constant data
        local variableDataOffset = offset + constantLength

        -- Load the variable (refcoder) data
        local encodedData = buffer.readstring(data, variableDataOffset, variableLength)
        local allPartData = Refcoder.decode(encodedData) or {}

        local metadata = allPartData.Metadata or {}
        sectionData.Metadata = metadata

        local partIndex = 1
        local partAssemblyIndex = 1
        local assemblyParts
        local function loadPart(assembly: AssemblyData, offset: number)
            throttle()

            -- Load part fields
            local part = readPart(data, offset, config, metadata)

            part.Assembly = assembly

            -- Load part data
            local partData = allPartData[partIndex] or {}

            part.ClassName = partData[1]
            part.Configuration = partData[2] or {}
            part.Properties = partData[3] or {}

            -- Grab joint data
            local joints = partData[4] or {}

            part.Welds = joints[1] or {}
            part.Constraints = joints[2] or {}
            part.Hinges = joints[3] or {}
            part.Grounded = joints[4] or false

            -- Add the part to the parts list & assembly
            sectionData.Parts[partIndex] = part
            assemblyParts[partAssemblyIndex] = part

            -- Increase the part indices
            partIndex += 1
            partAssemblyIndex += 1
        end

        -- Load all assemblies
        while offset < variableDataOffset do
            throttle()

            -- Load the part count & assembly CFrame
            local partCount = buffer.readu16(data, offset)
            local assemblyCFrame = readCFrame(data, offset + 2)

            offset += 2 + CFRAME_SIZE

            -- Create assembly parts list
            partAssemblyIndex = 1
            assemblyParts = table.create(partCount)

            -- Create assembly
            local assembly = {
                PartCount = partCount,
                Parts = assemblyParts,
                CFrame = assemblyCFrame,
            }

            -- Load all of the parts
            local partSize = if config.UseStateData then PART_DATA_SIZE + PART_META_SIZE else PART_DATA_SIZE
            for i = 0, partCount - 1 do
                loadPart(assembly, offset + partSize * i)
            end
            offset += partSize * partCount

            -- Add the assembly
            table.insert(sectionData.Assemblies, assembly)
        end

        offset += variableLength
    end

    return decoded
end

local function encodeSaveData(saveData: SaveDataSparse, saveConfig: SaveConfig): buffer
    local throttle = saveConfig.Throttle or function() end

    local partSize = if saveConfig.UseStateData then PART_DATA_SIZE + PART_META_SIZE else PART_DATA_SIZE

    -- Create variable data
    local variableData = {}

    -- Define header size
    local headerSize = 2 + 4 + 4

    -- Compute constant data size
    local constantDataSize = 0

    -- Tally up assembly sizes
    constantDataSize += (2 + CFRAME_SIZE) * #saveData.Assemblies

    -- Tally up part sizes
    for _, assembly: AssemblyDataSparse in saveData.Assemblies do
        throttle()

        constantDataSize += #assembly.Parts * partSize

        -- Collect variable data
        for _, partData: PartDataSparse in assembly.Parts do
            throttle()

            table.insert(variableData, {
                partData.ClassName,
                partData.Configuration,
                partData.Properties,
                {
                    partData.Welds,
                    partData.Constraints,
                    partData.Hinges,
                    partData.Grounded,
                },
            })
        end
    end

    throttle()

    -- Assign metadata
    variableData.Metadata = {
        UseStateData = if saveConfig.UseStateData then true else nil,
        Timestamp = if workspace then workspace:GetServerTimeNow() else os.time(),

        HealthFixed = true,
    }

    -- Encode variable data & compute size
    local encodedData = Refcoder.encode(variableData)
    local variableDataSize = #encodedData

    throttle()

    -- Create save buffer
    local data = buffer.create(headerSize + constantDataSize + variableDataSize)

    -- Write the version number
    buffer.writeu16(data, VERSION_OFFSET, COMPILER_VERSION)

    -- Write the constant & variable data size
    buffer.writeu32(data, CONSTANT_LENGTH_OFFSET, constantDataSize)
    buffer.writeu32(data, VARIABLE_LENGTH_OFFSET, variableDataSize)

    -- Define the data offset
    local offset = VARIABLE_LENGTH_OFFSET + 4

    -- Write the variable data
    buffer.writestring(data, offset + constantDataSize, encodedData)

    -- Save all the assembly & part data
    for _, assembly: AssemblyDataSparse in saveData.Assemblies do
        throttle()

        -- Determine the assembly part count
        local partCount = #assembly.Parts

        -- Write assembly part count & CFrame
        buffer.writeu16(data, offset, partCount)
        writeCFrame(data, offset + 2, assembly.CFrame)

        offset += 2 + CFRAME_SIZE

        -- Write all part data
        for i, partData: PartDataSparse in assembly.Parts do
            throttle()

            writePart(data, offset + partSize * (i - 1), partData, saveConfig)
        end
        offset += partSize * partCount
    end

    throttle()

    return data
end

function Compiler:Decode(saveData: string | buffer, saveConfig: SaveConfig): SaveData?
    return decodeSaveData(saveData, saveConfig)
end

function Compiler:Encode(saveData: SaveData | SaveDataSparse, saveConfig: SaveConfig): buffer
    return encodeSaveData(saveData :: SaveDataSparse, saveConfig)
end

function Compiler:Query(saveData: buffer)
    return querySaveData(saveData)
end

return Compiler

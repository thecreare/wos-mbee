export type Config = {
    Type: string,
    Description: string,
    Default: any,
    Options: {[string]: any} | {string},
    Name: string,
}

export type Component = {
    ConfigData: {Config}?,
    Events: {string}?,
    Conflicts: {string}?,
    Description: string?,
    ClassName: string,
}

export type Part = {
    Categories: {string},
    --- Malleability of the part, 0 if it has fixed size
    Malleability: number,
    ClassState: string,
    Color: nil, -- TODO
    Flammable: boolean,
    Description: string,
    --- If the part can be crafted via crafting menu
    Craftable: boolean,
    --- If the part can be spawned via commands (Disabled for things like Warhead & AdminTool)
    Spawnable: boolean,
    ClassName: string,
    ClassType: string,
    BaseHeatCapacity: number,
    BaseSize: nil, -- TODO
    BaseDurability: number,
    ConfigData: {Config},
    Events: {string}?,
    Recipe: {[string]: number}?,
    DefaultComponents: {string}?,
    ResourceType: string?,
}

export type PartData = {
    Components: {[string]: Component},
    Parts: {[string]: Part},
}

return require(script.RawData) :: PartData
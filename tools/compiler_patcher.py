"""
Is this cursed? Yes.
Is it better than copy-pasting changes for every new compiler? Also yes.
"""
import re

COMPILERS = ["2.6.1", "2.6.1R", "2.6.4", "2.6.4R"]

PATCH_BEGIN = "--[[PB]]"
PATCH_END = "--[[PE]]"

REMOVAL_BEGIN = "--[[RM;"
REMOVAL_END = ";RM]]"

opened_files = {}

MATCH_PATCHES = re.compile(r"--\[\[PB\]\].*?--\[\[PE\]\]", re.S)
def GetContents(path):
    if path in opened_files:
        return opened_files[path]

    # Get contents
    with open(path, "r") as f:
        contents = f.read()

    # Remove old patches
    contents = re.sub(MATCH_PATCHES, "", contents)
    contents = contents.replace(REMOVAL_BEGIN, "", -1).replace(REMOVAL_END, "", -1)

    # Remember the contents for future open attempts and for when contents are written back at the end
    opened_files[path] = contents
    return contents

def GetAllPaths(end):
    out = []
    for compiler in COMPILERS:
        out.insert(0, f"./src/Compilers/{compiler}/{end}")
    return out

# For every opened file write its contents back to its file path.
def WritebackFiles():
    for path, contents in opened_files.items():        
        print("Writing to", path)
        with open(path, "w") as f:
            f.write(contents)

def AppendPatchTo(path, patch, find):
    for full_path in GetAllPaths(path):
        contents = GetContents(full_path)
        index = contents.find(find) + len(find)

        contents = contents[:index] + PATCH_BEGIN + patch + PATCH_END + contents[index:]
        opened_files[full_path] = contents

def PrependPatchTo(path, patch, find):
    for full_path in GetAllPaths(path):
        contents = GetContents(full_path)
        index = contents.find(find)

        contents = contents[:index] + PATCH_BEGIN + patch + PATCH_END + contents[index:]
        opened_files[full_path] = contents

def PatchOver(path, patch, find):
    for full_path in GetAllPaths(path):
        contents = GetContents(full_path)

        amt_to_skip = len(find)+len(patch)+len(PATCH_BEGIN)+len(PATCH_END)+len(REMOVAL_BEGIN)+len(REMOVAL_END)
        index = -amt_to_skip
        while True:
            index = contents.find(find, index+amt_to_skip)
            if index == -1:
                break

            end_of_match = index+len(find)
            contents = contents[:index] + PATCH_BEGIN + patch + PATCH_END + REMOVAL_BEGIN + contents[index:end_of_match] + REMOVAL_END + contents[end_of_match:]
            opened_files[full_path] = contents

### Patch :GetShape() to support base parts with `SpecialMesh`'s
### Request: https://discord.com/channels/616089055532417036/1047587493693886547/1324649555526025278
PART_METADATA = "PartMetadata/init.lua"
CONFIG_DATA = "PartMetadata/ConfigData.lua"
MALLEABILITY_DATA = "PartMetadata/Malleability.lua"
GET_SHAPE_ROOT = 'elseif part:IsA("Part") then'
# Things that use MeshType
# for mesh, return_value in {"Brick": "nil", "Wedge": "Wedge", "Cylinder": "Cylinder"}.items():
#     PrependPatchTo(
#         PART_METADATA,
#         f'elseif mesh and mesh.MeshType == Enum.MeshType.{mesh} then\n\t\treturn "{return_value}"\n\t',
#         GET_SHAPE_ROOT,
#     )
    
# # Things that use MeshId
# PrependPatchTo(
#     PART_METADATA,
#     'elseif mesh and shapesByMeshId[mesh.MeshId] then\n\t\treturn shapesByMeshId[mesh.MeshId]\n\t',
#     GET_SHAPE_ROOT,
# )
# # Edge case for CornerWedge
# PrependPatchTo(
#     PART_METADATA,
#     'elseif mesh and mesh.MeshId == "http://www.roblox.com/asset/?id=11294911" then\n\t\treturn "CornerWedge"\n\t',
#     GET_SHAPE_ROOT,
# )

### Sorters missing TriggerQuantity
PrependPatchTo(
    CONFIG_DATA,
    '\n\t\t\t{\n\t\t\t\t["Type"] = "number",\n\t\t\t\t["Default"] = "1",\n\t\t\t\t["Name"] = "TriggerQuantity"\n\t\t\t},',
    '\n\t\t},\n\t\t["ProximityButton"] = {', # I know it says proximity button but its because sorter is the config before it
)

### Fix packages path
PatchOver(
    "init.lua",
    "MBEPackages",
    "Packages",
)

### Fix compiler not handling RotateV correctly or something
### I really don't understand this
## All this does is ports some code from the 2.6.1 compiler into the 2.6.4 compiler that was removed for some reason
PatchOver(
    "init.lua",
    """
					if joint:IsA("DynamicRotate") or joint:IsA("Rotate") then
						if joint.Parent ~= primaryPart then
							continue
						end

						local c0, c1 = joint.C0, joint.C1

						local face = GetClosestFace(-c0.LookVector)

						local hingeData = hinges[face.Value] or {}
						hinges[face.Value] = hingeData

						local otherFace = GetClosestFace(-c1.LookVector)
						local look = CFrame.lookAt(Vector3.zero, Vector3.FromNormalId(otherFace))
						local rotation = math.acos(look.UpVector:Dot(c1.RightVector)) * math.sign(look.RightVector:Dot(c1.RightVector))

						table.insert(hingeData, {otherPartIndex, c1.Position.X, c1.Position.Y, c1.Position.Z, otherFace.Value, rotation})
						continue
					end
""",
"""
					if joint:IsA("DynamicRotate") or joint:IsA("Rotate") then
						continue
					end
"""
)

## Add a compiler feature to override configs based on a list of callbacks
## Used for microcontroller typing removal, randomized antenna ids, and backwards compatible config values
PatchOver("init.lua",
"""
			local configurables = PartMetadata:GetConfigurables(part)
			for key, value in configurables do
				for _, override in saveConfig.Overrides do
					local new = override(key, value)
					if new ~= nil then
						configurables[key] = new
					end
				end
			end
""",
"""
			local configurables = PartMetadata:GetConfigurables(part)
""")

## Fix sign color default being in hex when the compiler doesn't actually use hex (what??)
PatchOver(CONFIG_DATA,
"""
			{
				["Name"] = "TextColor",
				["Type"] = "Color3",
				["Description"] = "The color of the text on the sign.",
				["Default"] = "1,1,1",
			},
""",
"""
			{
				["Name"] = "TextColor",
				["Type"] = "Color3",
				["Description"] = "The color of the text on the sign.",
				["Default"] = "ffffff",
			},
""")

## Fix servos missing Angle config
PatchOver(CONFIG_DATA,
"""
				["Name"] = "Responsiveness",
			},
            {
				["Type"] = "number",
				["Default"] = 0,
				["Description"] = "Determines the angle the servo will attempt to rotate to when spawned.",
				["Name"] = "Angle",
			},
""",
"""
				["Name"] = "Responsiveness",
			},
""")

## Fix Solenoid missing Resource config & having wrong Range config
PatchOver(CONFIG_DATA,
"""
			{
				["Name"] = "Range",
				["Type"] = "NumberRange",
				["Description"] = "The resource range the state will be active for.",
				["Default"] = {
					0,
					"inf",
				},
			},
			{
				["Name"] = "Resource",
				["Type"] = "string",
				["Description"] = "The kind of resource to check for.",
				["Default"] = "Power",
			},
""",
"""
			{
				["Name"] = "PowerRange",
				["Type"] = "NumberRange",
				["Description"] = "The power range the state will be active for.",
				["Default"] = {
					0,
					"inf",
				},
			},
""")

## Fix Solenoid missing Resource config & having wrong Range config
PatchOver(CONFIG_DATA,
"""
			{
				["Name"] = "Anchored",
				["Type"] = "boolean",
				["Description"] = "Determines whether the anchor is active or not.",
				["Default"] = false,
			},
            {
				["Name"] = "AnchorOnWarp",
				["Type"] = "boolean",
				["Description"] = "Determines whether the anchor will automatically activate after warp. Helps prevent runaway ships.",
				["Default"] = true,
			},
""",
"""
			{
				["Name"] = "Anchored",
				["Type"] = "boolean",
				["Description"] = "Determines whether the anchor is active or not.",
				["Default"] = false,
			},
""")

## Hack in new malleability data because MB still hasn't updated
PatchOver(MALLEABILITY_DATA, "EnergyBomb = Vector3.new(2, 4, 2),", "EnergyBomb = Vector3.new(3, 6, 3),")
PatchOver(MALLEABILITY_DATA, "Transporter = Vector3.new(3, 4, 3),", "Transporter = Vector3.new(3, 5, 3),")

WritebackFiles()
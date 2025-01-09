"""
Is this cursed? Yes.
Is it better than copy-pasting changes for every new compiler? Also yes.
"""
import re
import datetime

COMPILER = "2.6.1"
FILE_PATH = f"./src/Compilers/{COMPILER}"

PATCH_BEGIN = "--[[PB]]"
PATCH_END = "--[[PE]]"

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

    # Remember the contents for future open attempts and for when contents are written back at the end
    opened_files[path] = contents
    return contents

# For every opened file write its contents back to its file path.
def WritebackFiles():
    for path, contents in opened_files.items():        
        with open(path, "w") as f:
            f.write(contents)

def AppendPatchTo(path, patch, find):
    full_path = f"{FILE_PATH}/{path}"

    contents = GetContents(full_path)
    index = contents.find(find) + len(find)

    contents = contents[:index] + PATCH_BEGIN + patch + PATCH_END + contents[index:]
    opened_files[full_path] = contents

def PrependPatchTo(path, patch, find):
    full_path = f"{FILE_PATH}/{path}"

    contents = GetContents(full_path)
    index = contents.find(find)

    contents = contents[:index] + PATCH_BEGIN + patch + PATCH_END + contents[index:]
    opened_files[full_path] = contents

### Patch :GetShape() to support base parts with `SpecialMesh`'s
### Request: https://discord.com/channels/616089055532417036/1047587493693886547/1324649555526025278
PART_METADATA = "PartMetadata/init.lua"
CONFIG_DATA = "PartMetadata/ConfigData.lua"
GET_SHAPE_ROOT = 'elseif part:IsA("Part") then'
# Things that use MeshType
for mesh, return_value in {"Brick": "nil", "Wedge": "Wedge", "Cylinder": "Cylinder"}.items():
    PrependPatchTo(
        PART_METADATA,
        f'elseif mesh and mesh.MeshType == Enum.MeshType.{mesh} then\n\t\treturn "{return_value}"\n\t',
        GET_SHAPE_ROOT,
    )
    
# Things that use MeshId
PrependPatchTo(
    PART_METADATA,
    'elseif mesh and shapesByMeshId[mesh.MeshId] then\n\t\treturn shapesByMeshId[mesh.MeshId]\n\t',
    GET_SHAPE_ROOT,
)
# Edge case for CornerWedge
PrependPatchTo(
    PART_METADATA,
    'elseif mesh and mesh.MeshId == "http://www.roblox.com/asset/?id=11294911" then\n\t\treturn "CornerWedge"\n\t',
    GET_SHAPE_ROOT,
)

### Sorters missing TriggerQuantity
PrependPatchTo(
    CONFIG_DATA,
    '\n\t\t\t{\n\t\t\t\t["Type"] = "number",\n\t\t\t\t["Default"] = "1",\n\t\t\t\t["Name"] = "TriggerQuantity"\n\t\t\t},',
    '\n\t\t},\n\t\t["ProximityButton"] = {', # I know it says proximity button but its because sorter is the config before it
)

WritebackFiles()
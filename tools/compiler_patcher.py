"""
Is this cursed? Yes.
Is it better than copy-pasting changes for every new compiler? Also yes.
"""
import re
import datetime

COMPILER = "2.6.1"
FILE_PATH = f"./src/Compilers/{COMPILER}"

FILE_PATCH_HEADER = f"""--[[
This file was automatically modified by tools/compiler_patcher.py
{datetime.date.today()}
]]
"""

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
# Add a header as well
def WritebackFiles():
    for path, contents in opened_files.items():        
        contents = PATCH_BEGIN + FILE_PATCH_HEADER + PATCH_END + contents

        with open(path, "w") as f:
            f.write(contents)

def PrependPatchTo(path, after, find):
    full_path = f"{FILE_PATH}/{path}"

    contents = GetContents(full_path)
    index = contents.find(find)

    # Check if patch was already done
    if contents.find(PATCH_BEGIN, index, index+len(PATCH_BEGIN)) != -1:
        print(f"Not applying patch to {path} because already done")
        return

    contents = contents[:index] + PATCH_BEGIN + after + PATCH_END + contents[index:]
    opened_files[full_path] = contents

# Patch :GetShape() to support base parts with `SpecialMesh`'s
# Request: https://discord.com/channels/616089055532417036/1047587493693886547/1324649555526025278
PART_METADATA = "PartMetadata/init.lua"
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

WritebackFiles()
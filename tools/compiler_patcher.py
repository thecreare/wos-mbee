import time

COMPILER = "2.6.1"
FILE_PATH = f"./src/Compilers/{COMPILER}"

FILE_PATCH_HEADER = """--[[
This file was automatically modified by tools/compiler_patcher.py
]]
"""

PATCH_BEGIN = "--[[PB]]"
PATCH_END = "--[[PE]]"

opened_files = {}

def GetContents(path):
    if path in opened_files:
        return opened_files[path]

    # Get contents
    with open(path, "r") as f:
        contents = f.read()
    opened_files[path] = contents
    return contents

def WritebackFiles():
    for path, contents in opened_files.items():        
        if contents.find(FILE_PATCH_HEADER) == -1:
            contents = FILE_PATCH_HEADER + "\n\n" + contents

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
PrependPatchTo(
    "PartMetadata/init.lua",
    'elseif mesh and shapesByMeshId[mesh.MeshId] then\n\t\treturn shapesByMeshId[mesh.MeshId]\n\t',
    'elseif part:IsA("Part") then',
)

WritebackFiles()
"""
Fetches the latest version of arvid's typechecking file
and places it in the correct folder.
"""

import requests

response = requests.get("https://api.github.com/repos/ArvidSilverlock/Pilot.lua-Luau-LSP/releases/latest")

response = response.json()

for asset in response["assets"]:
    if asset["name"] == "vanilla-types.luau":
        types = requests.get(asset["browser_download_url"])

UPDATE_PILOT_TYPES_PATH = "src/Modules/UpdatePilotTypes/"
with open(UPDATE_PILOT_TYPES_PATH + "DefaultPilotLua.lua", "w") as f:
    f.write(types.text)

with open(UPDATE_PILOT_TYPES_PATH + "DefaultPilotLuaVersion.txt", "w") as f:
    f.write(response["published_at"])
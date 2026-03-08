# MBEE: Model Builder Edited Edited

A roblox studio plugin that compiles models for [Waste of Space](https://www.roblox.com/games/4490046941)

The plugin can be found here: <https://create.roblox.com/store/asset/11707735968>

## Features

- Automatic ~~dpaste.org~~ ([currently down](https://github.com/DarrenOfficial/dpaste/issues/274#issuecomment-3553595409)) & GitHub Gist uploading
- Faster compile times
- 3D Part surface type editor
- Automatic wireless ID securing. Prefix any `Antenna`/`Router`/etc ID with % to automatically randomize its ID at compile time.
- Builtin mirror tool (fork of stravant's, edited to work with wos parts)
- Range and capacity visualizations for parts like `EnergyShield` & `PowerCell`
- Edit `Microcontroller` code in a script with type checking from [Arvid's documentation](https://github.com/ArvidSilverlock/Pilot.lua-Luau-LSP)
- Part name & config autocomplete
- Support for decompiling pre-2024-wipe model codes
- Get resource cost of a model in LUA, JSON, or human-readable text
- Extra developer parts like `DevSource`, `DevSink`, and more that aren't shown in the official tools
- Customizable UI colors
- Support for adding and configuring part components like `Blade` and `Door`
- Dropdowns for multiple-choice configurations like `Polysilicon`, `Apparel`, `Extractor`, and more
- Currently more up-to-date than the official tools
- Warning symbols for parts that can't be loaded in testing zone (blue), can't be crafted in the universe (orange), or both (red)
- Change part types in bulk, ie, replacing `Iron` with `Titanium`
- Spawn wedges and other templates with a template material
- Ignores non-wos parts by default, it won't accidentally compile random parts like Handles in rigs
- Overlap & Malleability checking
- Create and add custom ("randmat") materials from the universe

## History

The original [MBTools](https://create.roblox.com/store/asset/6724254977) was developed by Austism and later by [Hexcede](https://www.roblox.com/users/35904028/profile).
[MBE](https://www.roblox.com/library/10075508989/WoS-MBTools-EDITED) is a fork of Austism's MBTools, created by [Crenbow](https://www.roblox.com/users/306951138/profile/). It added quite a few quality of life features but was unfortunately retried when Crenbow left. [MBEE](https://create.roblox.com/store/asset/11707735968) is the latest iteration and is primarily developed by [creare](https://www.roblox.com/users/857491600/profile).

## Contributing

[`tools/`](https://github.com/thecreare/wos-mbee/tree/main/tools) contains partially documented tools used to keep mbee up to date.

### Setting up a local environment

1. [Fork](https://github.com/thecreare/wos-mbee/fork) this repository
2. [git clone](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) your new repository
3. Navigate into the `wos-mbee/` directory
4. Run `rokit install` to install the development tools
5. Run `wally install` to install the dependencies
6. Run `rojo serve` to start the Rojo server
7. If you don't have the Rojo plugin installed in Roblox Studio, run `rojo plugin` to install it
8. Create a new place in Roblox Studio & click the "Connect" button in the Rojo menu

### Saving as a local plugin

1. Right click the `MBEE` folder and in the `Save / Export` option select `Save as Local Plugin...`

### Adding new parts

1. Run `tools/ExportPartData.lua` in wos & paste the result into `src/PartData/RawData.json`
2. Save the plugin locally & check the console. It will print out what parts are missing
3. Create new models for the missing parts in studio. Give them the correct names, visuals, & sizes then save them as `.rbxmx` files in `src/Parts/`

### Adding a new compiler version

1. Copy the new compiler into Compilers folder
2. Set `Default` to `false` in old compiler (and make sure its `true` in the new one)
3. Set all Shape MeshPart's `CollisionFidelity` to `Box`
4. Run `tools/compiler_patcher` on correct version

### Updating type definition header

1. Run `FetchLatestDefaultPilotLuau.py`

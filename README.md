# MBEE: Model Builder Edited Edited

A roblox studio plugin that compiles models for [Waste of Space](https://www.roblox.com/games/4490046941)

The plugin can be found here: <https://create.roblox.com/store/asset/11707735968>

## Features

- Automatic dpaste.org/gist uploading
- Faster compile times
- 3D Part surface type editor
- Automatic wireless ID securing. Prefix any `Antenna`/`Router`/etc ID with % to automatically randomize its ID at compile time.
- Builtin mirror tool (fork of stravant's, edited to work with wos parts)
- Range and capacity visualizations for parts like `EnergyShield` & `PowerCell`
- Microcontroller type checking (from arvid's documentation https://github.com/ArvidSilverlock/Pilot.lua-Luau-LSP)
- Part name & config autocomplete
- Support for decompiling pre 2024 wipe model codes
- Automatically open `Microcontroller` code as script
- Get resource cost of model
- Extra developer parts that aren't shown in the classic model builder tools
- Customizable UI
- Support for components in UI
- Part list UI shows miniature part icon
- UI Dropdown for enum configs

## History

The original [MBTools](https://create.roblox.com/store/asset/6724254977) was developed by Austism and later by [Hexcede](https://www.roblox.com/users/35904028/profile).
[MBE](https://www.roblox.com/library/10075508989/WoS-MBTools-EDITED) is a fork of Austism's MBTools, created by [Crenbow](https://www.roblox.com/users/306951138/profile/). It added quite a few quality of life features but was unfortunately retried when Crenbow left. [MBEE](https://create.roblox.com/store/asset/11707735968) is the latest iteration and is primarily developed by [creare](https://www.roblox.com/users/857491600/profile).

## Contributing

[Tools](https://github.com/1-creare-1/wos-mbee/tree/main/tools) contains mostly undocumented tools used to keep mbee up to date.

### Setting up a local workspace

1. Download the plugin source from here: <https://assetdelivery.roblox.com/v1/asset/?id=11707735968>
2. Rename downloaded file to include the extension `.rbxm`
3. Import the rbxm into a new place file
4. Move the local script named `MBEE` into a folder named `MBEE`
5. Sync rojo

### Saving as a local plugin

1. Right click the `MBEE` folder and in the `Save / Export` option select `Save as Local Plugin...`

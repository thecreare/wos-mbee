local module = {}

module.MaterialDecals = {
    ['DiamondPlate'] = 'rbxassetid://6199640978',
    ['Pebble'] = 'rbxassetid://6199682801',
    ['Concrete'] = 'rbxassetid://6199640497',
    ['Grass'] = 'rbxassetid://6199644850',
    ['Slate'] = 'rbxassetid://6199684472',
    ['Sand'] = 'rbxassetid://6199683944',
    ['WoodPlanks'] = 'rbxassetid://6199685792',
    ['Brick'] = 'rbxassetid://6199592405',
    ['Foil'] = 'rbxassetid://6199591431',
    ['Fabric'] = 'rbxassetid://6199641888',
    ['Wood'] = 'rbxassetid://6199685137',
    ["CorrodedMetal"] = 'rbxassetid://6199683451',
    ['Granite'] = 'rbxassetid://6199643524',
    ['Metal'] = 'rbxassetid://6199682276',
    ['Cobblestone'] = 'rbxassetid://6199592990',
    ['ForceField'] = 'rbxassetid://4611376175',
    ['Neon'] = 'rbxassetid://4611376175',
}

module.Uncompressable = {
    ["Cannon"] = true;
    ["Gun"] = true;
    ["Laser"] = true;
    ["BurstLaser"] = true;
    ["EnergyShield"] = true;
    ["EnergyBomb"] = true;
    ["Artillery"] = true;
    ["AutomaticLaser"] = true;
    ["EnergyGun"] = true;
    ["Flamethrower"] = true;
    ["ImpulseCannon"] = true;
    ["MiningLaser"] = true;
    ["Missile"] = true;
    ["PlasmaCannon"] = true;
    ["PowerCell"] = true;
    ["RailGun"] = true;
    ["Bin"] = true;
    ["Rocket"] = true;
    ["Shotgun"] = true;
    ["StasisField"] = true;
    ["Warhead"] = true;
    ["Cooler"] = true;
    ["WaterCooler"] = true;
    ["Heater"] = true;
    ["SolarPanel"] = true;
    ["BurnerGenerator"] = true;
    ["Reactor"] = true;
    ["Battery"] = true;
    ["Pump"] = true;
    ["DarkReactor"] = true;
    ["DarkConverter"] = true;
    ["Extractor"] = true;
    ["Refinery"] = true;
    ["Container"] = true;
    ["SteamTurbine"] = true;
}

module.SearchCategories = {
    ['templateables'] = {
        'ruby',
        'lead',
        'aliencore',
        'beryllium',
        'sand',
        'neutronium',
        'iron',
        'darkmatter',
        'magnesium',
        'copper',
        'diamond',
        'quartz',
        'snow',
        'exoticmatter',
        'perfectium',
        'stick',
        'water',
        'silicon',
        'coal',
        'wood',
        'glass',
        'sulfur',
        'aluminum',
        'ruby',
        'jade',
        'ice',
        'flint',
        'stone',
        'gold',
        'grass',
        'titanium',
        'uranium',
        'nuclearwaste',
        'snow',
        'water',
        'lava',
        'hydrogen',
        'helium',
        'plasma',
        'steam',
        'petroleum',
        'mustardgas',
        'nitrogenoxide',
        'plasma',
        'oil',
        'neon',
        'reinforcedglass',
        'melter'
    },

    ['resources'] = {
        'ruby',
        'lead',
        'aliencore',
        'beryllium',
        'sand',
        'neutronium',
        'iron',
        'darkmatter',
        'magnesium',
        'copper',
        'diamond',
        'quartz',
        'snow',
        'exoticmatter',
        'perfectium',
        'stick',
        'water',
        'silicon',
        'coal',
        'wood',
        'glass',
        'sulfur',
        'aluminum',
        'ruby',
        'jade',
        'ice',
        'flint',
        'stone',
        'gold',
        'grass',
        'titanium',
        'uranium',
        'nuclearwaste',
        'snow',
        'water',
        'lava',
        'hydrogen',
        'helium',
        'plasma',
        'steam',
        'petroleum',
        'mustardgas',
        'nitrogenoxide',
        'plasma',
        'oil',
        'neon',
        'reinforcedglass',
    },

    ['logic'] = {
        'switch',
        'microcontroller',
        'Capacitysensor',
        'microphone',
        'touchsensor',
        'triggerwire',
        'transformer',
        'zapwire',
        'controller',
        'port',
        'instrument',
        'screen',
        'triggerswitch',
        'igniter',
        'keyboard',
        'deleteswitch',
        'electromagnet'
    },

    ['propulsion'] = {
        'propeller',
        'thruster',
        'rocket',
        'hyperdrive',
        'rotor'
    },

    ['electrical'] = {
        'scrapper',
        'extractor',
        'light',
        'cooler',
        'cloningbay',
        'darkreactor',
        'regioncloaker',
        'pulverizer',
        'laser',
        'watercooler',
        'burnergenerator',
        'servo',
        'thruster',
        'combustionturbine',
        'touchscreen',
        'electricfence',
        'pump',
        'assembler',
        'diode',
        'modem',
        'stasisfield',
        'lightbridge',
        'wire',
        'mininglaser',
        'darkconverter',
        'lighttube',
        'beacon',
        'steamturbine',
        'starmap',
        'kiln',
        'transformer',
        'automaticlaser',
        'solarscoop',
        'ionrocket',
        'melter',
        'freezer',
        'spotlight',
        'hydroponic',
        'studaligner',
        'railgun',
        'treads',
        'switch',
        'airsupply',
        'speaker',
        'energyshield',
        'motor',
        'zapwire',
        'obelisk',
        'gravitygenerator',
        'refinery',
        'gyro',
        'telescope',
        'rtg',
        'conveyorbelt',
        'hologram',
        'screen',
        'floatdevice',
        'heater',
        'solarpanel',
        'boombox',
        'electromagnet',
        'blackbox'
    },

    ['templates'] = {
        'cornertetra',
        'wedge',
        'cone',
        'tetrahedron',
        'cylinder',
        'cornerroundwedge2',
        'cornerroundwedge',
        'door',
        'ball',
        'halfsphere',
        'hull',
        'truss',
        'roundwedge',
        'blade',
        'cornerwedge',
        'roundwedge2'
    },

    ['weapons'] = {
        'burstlaser',
        'laser',
        'energybomb',
        'energygun',
        'cannon',
        'impulsecannon',
        'warhead',
        'automaticlaser',
        'fireworks',
        'gun',
        'plasmacannon',
        'railgun',
        'zapwire',
        'explosive'
    }
}
return module

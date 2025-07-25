return {
	["Components"] = {
		["KeyButton"] = {
			{
				["Type"] = "string",
				["Default"] = "",
				["Description"] = "The name of the key that will trigger this button when the key is pressed by players in connected seats.",
				["Options"] = {
					["MaxLength"] = 16,
				},
				["Name"] = "Key",
			},
			{
				["Type"] = "Selection",
				["Default"] = 0,
				["Description"] = "Determines the type of key event to trigger this button on.",
				["Options"] = {
					"KeyDown",
					"KeyUp",
					"KeyPress",
				},
				["Name"] = "PressMode",
			},
			{
				["Type"] = "Selection",
				["Default"] = 0,
				["Description"] = "Determines how trigger signals will be emitted. Emit mode sends trigger signals to attached parts. Self mode only triggers the part internally.",
				["Options"] = {
					"Emit",
					"Self",
					"None",
				},
				["Name"] = "SignalMode",
			},
		},
		["Door"] = {
			{
				["Description"] = "Determines if the door is open.",
				["Type"] = "boolean",
				["Name"] = "Switch",
				["Default"] = false,
			},
		},
		["ClickButton"] = {
			{
				["Type"] = "Selection",
				["Default"] = 0,
				["Description"] = "Determines how trigger signals will be emitted. Emit mode sends trigger signals to attached parts. Self mode only triggers the part internally.",
				["Options"] = {
					"Emit",
					"Self",
					"None",
				},
				["Name"] = "SignalMode",
			},
		},
	},
	["Parts"] = {
		["Rocket"] = {
			{
				["Type"] = "number",
				["Default"] = 30,
				["Description"] = "Determines the speed traveled at, 0 being standstill. Affects fuel consumption.",
				["Options"] = {
					0,
					100,
				},
				["Name"] = "Propulsion",
			},
		},
		["DelayWire"] = {
			{
				["Type"] = "number",
				["Default"] = 1,
				["Description"] = "The time in seconds that it takes for signals to pass through this wire.",
				["Options"] = {
					0,
					360,
				},
				["Name"] = "DelayTime",
			},
		},
		["Hatch"] = {
			{
				["Name"] = "SwitchValue",
				["Type"] = "boolean",
				["Description"] = "Determines whether the switch is active or not.",
				["Default"] = false,
			},
		},
		["Screen"] = {
			{
				["Type"] = "number",
				["Default"] = 0,
				["Description"] = "The ID of the camera feed being to be viewed, or 0 for none.",
				["Options"] = {
					0,
					10000000000,
					1,
				},
				["Name"] = "VideoID",
			},
		},
		["Coupler"] = {
			{
				["Type"] = "string",
				["Default"] = "C1",
				["Description"] = "The ID of this coupler.",
				["Options"] = {
					["MaxLength"] = 64,
				},
				["Name"] = "CouplerID",
			},
			{
				["Name"] = "AutoTrigger",
				["Type"] = "boolean",
				["Description"] = "Whether or not the coupler should emit trigger signals while in range of another valid coupler.",
				["Default"] = false,
			},
		},
		["TemperatureGate"] = {
			{
				["Description"] = "The range of temperatures (°F) within which the gate will be open.",
				["Type"] = "NumberRange",
				["Name"] = "TemperatureRange",
				["Default"] = {
					140,
					"inf",
				},
			},
			{
				["Description"] = "Whether or not the state will be inverted.",
				["Type"] = "boolean",
				["Name"] = "Inverted",
				["Default"] = false,
			},
			{
				["Name"] = "SwitchValue",
				["Type"] = "boolean",
				["Description"] = "Determines whether the switch is active or not.",
				["Default"] = false,
			},
		},
		["DevTeleporter"] = {
			{
				["Type"] = "string",
				["Default"] = "",
				["Description"] = "The ID of the teleporter at the goal coordinates to teleport directly to.",
				["Options"] = {
					["MaxLength"] = 64,
				},
				["Name"] = "TeleporterID",
			},
		},
		["RemoteControl"] = {
			{
				["Type"] = "number",
				["Default"] = 120,
				["Description"] = "The range in studs at which signals will be transmitted.",
				["Options"] = {
					1,
					500,
				},
				["Name"] = "RemoteControlRange",
			},
			{
				["Type"] = "Selection",
				["Default"] = 0,
				["Description"] = "The way in which trigger signals should be transmitted. This setting only affects parts that are connective to trigger signals (e.g. TriggerWire).",
				["Options"] = {
					"EmitFromTarget",
					"SendDirectly",
				},
				["Name"] = "RemoteControlMode",
			},
		},
		["Transformer"] = {
			{
				["Type"] = "number",
				["Default"] = 1,
				["Description"] = "The time in seconds between triggers.",
				["Options"] = {
					0,
					360,
				},
				["Name"] = "LoopTime",
			},
		},
		["Light"] = {
			{
				["Type"] = "number",
				["Default"] = 1,
				["Description"] = "The brightness of the light.",
				["Options"] = {
					0,
					2,
				},
				["Name"] = "Brightness",
			},
			{
				["Type"] = "number",
				["Default"] = 60,
				["Description"] = "The range of the light.",
				["Options"] = {
					1,
					60,
				},
				["Name"] = "LightRange",
			},
			{
				["Name"] = "Shadows",
				["Type"] = "boolean",
				["Description"] = "Whether or not the light will cast shadows.",
				["Default"] = false,
			},
		},
		["CloningBay"] = {
			{
				["Type"] = "string",
				["Default"] = "CloningBay",
				["Description"] = "The name of the cloning bay.",
				["Options"] = {
					["MaxLength"] = 40,
				},
				["Name"] = "Name",
			},
		},
		["Balloon"] = {
			{
				["Type"] = "number",
				["Default"] = 0,
				["Description"] = "The buoyancy of this Balloon, 0 being neutral.",
				["Options"] = {
					-10,
					10,
				},
				["Name"] = "Buoyancy",
			},
		},
		["Valve"] = {
			{
				["Name"] = "SwitchValue",
				["Type"] = "boolean",
				["Description"] = "Determines whether the switch is active or not.",
				["Default"] = false,
			},
		},
		["Filter"] = {
			{
				["Type"] = "string",
				["Default"] = "",
				["Description"] = "The name of the material allowed to pass through.",
				["Options"] = {
					["MaxLength"] = 24,
				},
				["Name"] = "Filter",
			},
			{
				["Description"] = "Whether or not to invert the filter.",
				["Type"] = "boolean",
				["Name"] = "Invert",
				["Default"] = false,
			},
		},
		["Antenna"] = {
			{
				["Type"] = "string",
				["Default"] = "A1",
				["Description"] = "The ID of this antenna, to transmit to others with the same ID.",
				["Options"] = {
					["MaxLength"] = 64,
				},
				["Name"] = "AntennaID",
			},
		},
		["Instrument"] = {
			{
				["Type"] = "Selection",
				["Default"] = 0,
				["Description"] = "The type of instrument readout to display on the instrument.",
				["Options"] = {
					"Speed",
					"AngularSpeed",
					"Temperature",
					"Time",
					"Power",
					"Size",
					"Position",
					"TemperatureF",
					"Orientation",
					"TemperatureC",
					"AirTemperatureF",
					"AirTemperatureC",
				},
				["Name"] = "Type",
			},
		},
		["ARController"] = {
			{
				["Type"] = "number",
				["Default"] = 0,
				["Description"] = "The transparency of the AR display.",
				["Options"] = {
					0,
					1,
					0.1,
				},
				["Name"] = "Transparency",
			},
		},
		["Transistor"] = {
			{
				["Name"] = "Inverted",
				["Type"] = "boolean",
				["Description"] = "Whether or not the state will be inverted.",
				["Default"] = false,
			},
		},
		["Polysilicon"] = {
			{
				["Type"] = "Selection",
				["Default"] = 0,
				["Description"] = "The mode of the Polysilicon. Each mode results in different behaviors for objects.",
				["Options"] = {
					"Activate",
					"Deactivate",
					"FlipFlop",
				},
				["Name"] = "PolysiliconMode",
			},
			{
				["Type"] = "number",
				["Default"] = 1,
				["Description"] = "The amount of times to activate the Polysilicon from a single trigger.",
				["Options"] = {
					1,
					10,
					1,
				},
				["Name"] = "Frequency",
			},
		},
		["Dispenser"] = {
			{
				["Type"] = "string",
				["Default"] = "",
				["Description"] = "Which kinds of resources to drop, separated by commas.",
				["Options"] = {
					["MaxLength"] = 256,
				},
				["Name"] = "Filter",
			},
		},
		["BallastTank"] = {
			{
				["Type"] = "number",
				["Default"] = 0,
				["Description"] = "The buoyancy of this BallastTank, 0 being neutral.",
				["Options"] = {
					-10,
					10,
				},
				["Name"] = "Buoyancy",
			},
		},
		["Laser"] = {
			{
				["Name"] = "DamageOnlyPlayers",
				["Type"] = "boolean",
				["Description"] = "Determines if this laser is only allowed to damage players and not materials.",
				["Default"] = false,
			},
		},
		["Switch"] = {
			{
				["Name"] = "SwitchValue",
				["Type"] = "boolean",
				["Description"] = "Determines whether the switch is active or not.",
				["Default"] = false,
			},
		},
		["SteamEngine"] = {
			{
				["Type"] = "number",
				["Default"] = 10,
				["Description"] = "Determines the speed at which the engine is driven.",
				["Options"] = {
					-20,
					20,
				},
				["Name"] = "EngineSpeed",
			},
		},
		["TemperatureSensor"] = {
			{
				["Name"] = "TemperatureRange",
				["Type"] = "NumberRange",
				["Description"] = "The range of temperatures (°F) which this sensor will trigger at.",
				["Default"] = {
					140,
					"inf",
				},
			},
		},
		["DevSource"] = {
			{
				["Name"] = "Resource",
				["Type"] = "ResourceString",
				["Description"] = "The name of the object to produce a source for.",
				["Default"] = "",
			},
		},
		["Microcontroller"] = {
			{
				["Name"] = "Code",
				["Type"] = "string",
				["Description"] = "The code to be executed on this microcontroller.",
				["Default"] = "",
			},
			{
				["Name"] = "StartOnSpawn",
				["Type"] = "boolean",
				["Description"] = "Whether or not to start the Microcontroller when it spawns.",
				["Default"] = false,
			},
		},
		["Constructor"] = {
			{
				["Name"] = "ModelCode",
				["Type"] = "string",
				["Description"] = "The model data of the model to be created by the Constructor.",
				["Default"] = "",
			},
			{
				["Name"] = "Autolock",
				["Type"] = "boolean",
				["Description"] = "Determines if the created model should be locked by the owner of the Constructor.",
				["Default"] = false,
			},
			{
				["Name"] = "RelativeToConstructor",
				["Type"] = "boolean",
				["Description"] = "Determines if the created model should be loaded in relative to the orientation of the Constructor.",
				["Default"] = false,
			},
		},
		["TractorBeam"] = {
			{
				["Type"] = "number",
				["Default"] = 100,
				["Description"] = "Determines the percentage of total available force (depending on size) used by the beam.",
				["Options"] = {
					0,
					100,
				},
				["Name"] = "PowerPercent",
			},
		},
		["HeatPump"] = {
			{
				["Type"] = "number",
				["Default"] = 4000,
				["Description"] = "How many kW of heat energy to pump.",
				["Options"] = {
					0,
					4000,
				},
				["Name"] = "TransferRate",
			},
		},
		["Speaker"] = {
			{
				["Type"] = "string",
				["Default"] = "5289642056",
				["Description"] = "The audio asset ID to be played.",
				["Options"] = {
					["MaxLength"] = 64,
				},
				["Name"] = "Audio",
			},
			{
				["Type"] = "number",
				["Default"] = 1,
				["Description"] = "The pitch at which to play the audio.",
				["Options"] = {
					0,
					3,
				},
				["Name"] = "Pitch",
			},
			{
				["Type"] = "number",
				["Default"] = 1,
				["Description"] = "The volume the audio plays at. The maximum volume is determined by the size of the speaker.",
				["Options"] = {
					0,
					1,
				},
				["Name"] = "Volume",
			},
		},
		["Faucet"] = {
			{
				["Type"] = "string",
				["Default"] = "",
				["Description"] = "Which kinds of resources to drop, separated by commas.",
				["Options"] = {
					["MaxLength"] = 256,
				},
				["Name"] = "Filter",
			},
		},
		["DevGravityGenerator"] = {
			{
				["Description"] = "Whether or not the gravity generator is enabled.",
				["Type"] = "boolean",
				["Name"] = "Enabled",
				["Default"] = true,
			},
			{
				["Type"] = "number",
				["Default"] = 196.2,
				["Description"] = "The amount of gravity within the influence of the GravityGenerator as a force.",
				["Options"] = {
					0,
					"inf",
				},
				["Name"] = "Gravity",
			},
			{
				["Type"] = "number",
				["Default"] = 588.6,
				["Description"] = "The radius of the generated gravity field.",
				["Options"] = {
					0,
					"inf",
				},
				["Name"] = "Radius",
			},
		},
		["Scanner"] = {
			{
				["Type"] = "number",
				["Description"] = "The default range to scan for parts within.",
				["Options"] = {
					0,
					1024,
				},
				["Default"] = 64,
				["Name"] = "Range",
			},
		},
		["Winch"] = {
			{
				["Type"] = "number",
				["Default"] = 1,
				["Description"] = "The length change in studs when triggered by Polysilicon.",
				["Options"] = {
					0,
					100,
				},
				["Name"] = "DeltaLength",
			},
			{
				["Type"] = "number",
				["Default"] = 0,
				["Description"] = "The minimum length in studs of the rope.",
				["Options"] = {
					0,
					100,
				},
				["Name"] = "MinLength",
			},
			{
				["Type"] = "number",
				["Default"] = 100,
				["Description"] = "The maximum length in studs of the rope.",
				["Options"] = {
					0,
					100,
				},
				["Name"] = "MaxLength",
			},
		},
		["EnergyShield"] = {
			{
				["Type"] = "number",
				["Default"] = 100,
				["Description"] = "The size of the entire shield. The shield exponentially consumes more power the higher this is.",
				["Options"] = {
					50,
					1000,
				},
				["Name"] = "ShieldRadius",
			},
			{
				["Type"] = "number",
				["Default"] = 5,
				["Description"] = "Determines how fast the shield regenerates after being hit.",
				["Options"] = {
					1,
					10,
				},
				["Name"] = "RegenerationSpeed",
			},
			{
				["Type"] = "number",
				["Default"] = 5,
				["Description"] = "Determines the shield's resistance to damage.",
				["Options"] = {
					1,
					10,
				},
				["Name"] = "ShieldStrength",
			},
		},
		["Servo"] = {
			{
				["Type"] = "number",
				["Default"] = 10,
				["Description"] = "Determines the speed at which the servo is driven.",
				["Options"] = {
					0,
					20,
				},
				["Name"] = "ServoSpeed",
			},
			{
				["Type"] = "number",
				["Default"] = 5,
				["Description"] = "Determines the change in angle when a pulse is received by Polysilicon.",
				["Options"] = {
					-180,
					180,
				},
				["Name"] = "AngleStep",
			},
			{
				["Type"] = "number",
				["Default"] = 45,
				["Description"] = "Determines how fast the servo attempts to correct its angle.",
				["Options"] = {
					0,
					90,
				},--[[PB]]
				["Name"] = "Responsiveness",
			},
            {
				["Type"] = "number",
				["Default"] = 0,
				["Description"] = "Determines the angle the servo will attempt to rotate to when spawned.",
				["Name"] = "Angle",
			},
--[[PE]]--[[RM;
				["Name"] = "Responsiveness",
			},
;RM]]		},
		["DriveBox"] = {
			{
				["Name"] = "Reversal",
				["Type"] = "boolean",
				["Description"] = "Determines whether the output should be reversed.",
				["Default"] = false,
			},
			{
				["Type"] = "number",
				["Default"] = 100,
				["Description"] = "The ratio of speed from 1 (1:100) to 100 (100:100) between this DriveBox and the source motor.",
				["Options"] = {
					1,
					100,
					1,
				},
				["Name"] = "Ratio",
			},
		},
		["HyperspaceRadar"] = {
			{
				["Name"] = "ViewCoordinates",
				["Type"] = "Coordinate",
			},
		},
		["FluidProjector"] = {
			{
				["Type"] = "Vector3",
				["Default"] = {
					10,
					10,
					10,
				},
				["Description"] = "The size in studs of the projected fluid field.",
				["Options"] = {
					1,
					75,
				},
				["Name"] = "Size",
			},
			{
				["Type"] = "string",
				["Default"] = "Water",
				["Description"] = "The name of the fluid being projected.",
				["Options"] = {
					["MaxLength"] = 64,
				},
				["Name"] = "Fluid",
			},
		},
		["Thruster"] = {
			{
				["Type"] = "number",
				["Default"] = 50,
				["Description"] = "Determines the percentage of thrust (speed). Affects fuel consumption.",
				["Options"] = {
					0,
					100,
				},
				["Name"] = "Propulsion",
			},
		},
		["Port"] = {
			{
				["Type"] = "number",
				["Default"] = 1,
				["Description"] = "The ID of this port used to utilize this port by connected microcontrollers.",
				["Options"] = {
					0,
					10000000000,
					1,
				},
				["Name"] = "PortID",
			},
		},
		["TimeSensor"] = {
			{
				["Type"] = "string",
				["Default"] = "7:30",
				["Description"] = "The time at which this sensor will trigger.",
				["Options"] = {
					["MaxLength"] = 5,
				},
				["Name"] = "Time",
			},
		},
		["Teleporter"] = {
			{
				["Type"] = "Coordinate",
				["Name"] = "Coordinates",
				["Description"] = "The coordinates to your Destination.",
			},
			{
				["Type"] = "number",
				["Default"] = 1,
				["Description"] = "The ID of the teleporter at the goal coordinates to teleport directly to.",
				["Options"] = {
					1,
					999,
					1,
				},
				["Name"] = "TeleporterID",
			},
			{
				["Name"] = "ForceLocalTeleport",
				["Type"] = "boolean",
				["Description"] = "Whether to only attempt to teleport to teleporters within the same region, ignoring the \"Coordinates\" configuration.",
				["Default"] = false,
			},
		},
		["Blade"] = {
			{
				["Type"] = "Selection",
				["Default"] = 0,
				["Description"] = "The shape of the blade.",
				["Options"] = {
					"Block",
					"Spheroid",
					"Cone",
				},
				["Name"] = "Shape",
			},
		},
		["TouchScreen"] = {
			{
				["Type"] = "number",
				["Default"] = 0,
				["Description"] = "The ID of the camera feed being to be viewed, or 0 for none.",
				["Options"] = {
					0,
					10000000000,
					1,
				},
				["Name"] = "VideoID",
			},
		},
		["Handle"] = {
			{
				["Type"] = "Selection",
				["Default"] = 1,
				["Description"] = "What the tool should do when clicking. Point mode will aim the handle at the mouse cursor.",
				["Options"] = {
					"None",
					"Swing",
					"Point",
				},
				["Name"] = "Swing",
			},
			{
				["Type"] = "Selection",
				["Default"] = 0,
				["Description"] = "Determines when this Handle should send trigger signals.",
				["Options"] = {
					"MouseDown",
					"MouseUp",
					"Both",
				},
				["Name"] = "TriggerMode",
			},
			{
				["Type"] = "string",
				["Default"] = "Handle",
				["Description"] = "The name of the tool.",
				["Options"] = {
					["MaxLength"] = 64,
				},
				["Name"] = "ToolName",
			},
		},
		["Transporter"] = {
			{
				["Type"] = "string",
				["Default"] = "T1",
				["Description"] = "The ID of this transporter, to transmit to others with the same ID.",
				["Options"] = {
					["MaxLength"] = 64,
				},
				["Name"] = "TransporterID",
			},
		},
		["ARGlasses"] = {
			{
				["Name"] = "Code",
				["Type"] = "string",
				["Description"] = "The code to be executed on this microcontroller.",
				["Default"] = "",
			},
			{
				["Type"] = "number",
				["Default"] = 0,
				["Description"] = "The transparency of the AR display.",
				["Options"] = {
					0,
					1,
					0.1,
				},
				["Name"] = "Transparency",
			},
			{
				["Type"] = "string",
				["Default"] = "A1",
				["Description"] = "The ID of the antenna network to connect to.",
				["Options"] = {
					["MaxLength"] = 16,
				},
				["Name"] = "AntennaID",
			},
			{
				["Type"] = "string",
				["Default"] = "R1",
				["Description"] = "The ID of the router network to connect to.",
				["Options"] = {
					["MaxLength"] = 16,
				},
				["Name"] = "RouterID",
			},
		},
		["Pump"] = {
			{
				["Type"] = "string",
				["Default"] = "Water",
				["Description"] = "The name of the liquid to extract using the pump.",
				["Options"] = {
					["MaxLength"] = 24,
				},
				["Name"] = "LiquidToPump",
			},
		},
		["Motor"] = {
			{
				["Type"] = "number",
				["Default"] = 0.5,
				["Description"] = "Determines the amount of power used to drive the motor. This affects the torque and power consumption. Negative values are reverse.",
				["Options"] = {
					-1,
					1,
				},
				["Name"] = "Power",
			},
			{
				["Type"] = "number",
				["Default"] = 1,
				["Description"] = "Determines the gear ratio applied to the motor in terms of the multiplier on the RPM. A value of 0.1 indicates a 10:1 ratio, where RPM is 1/10th and torque is 10x when compared to the default setting of 1.",
				["Options"] = {
					0.001,
					10,
				},
				["Name"] = "Ratio",
			},
		},
		["DevSink"] = {
			{
				["Name"] = "Resource",
				["Type"] = "ResourceString",
				["Description"] = "The name of the object to produce a sink for.",
				["Default"] = "",
			},
		},
		["Gyro"] = {
			{
				["Type"] = "string",
				["Default"] = "",
				["Description"] = "The seek commands.",
				["Options"] = {
					["MaxLength"] = 512,
				},
				["Name"] = "Seek",
			},
			{
				["Name"] = "DisableWhenUnpowered",
				["Type"] = "boolean",
				["Description"] = "Determines whether this gyro should be disabled while it does not have power.",
				["Default"] = false,
			},
			{
				["Type"] = "number",
				["Default"] = 10000000000,
				["Description"] = "The maximum force in each axis the gyro can exert.",
				["Options"] = {
					0,
					10000000000,
				},
				["Name"] = "MaxTorque",
			},
			{
				["Name"] = "TriggerWhenSeeked",
				["Type"] = "boolean",
				["Description"] = "Determines whether to send out a trigger signal when the gyro detects something to seek as determined by the Seek configurable.",
				["Default"] = false,
			},
		},
		["Telescope"] = {
			{
				["Type"] = "Coordinate",
				["Name"] = "ViewCoordinates",
				["Description"] = "The coordinates to view.",
			},
		},
		["Extractor"] = {
			{
				["Type"] = "Selection",
				["Default"] = "Any",
				["Description"] = "Determines the material to extract from connected natural surfaces. Disables the extractor if blank.",
				["Options"] = "Natural",
				["Name"] = "MaterialToExtract",
			},
		},
		["Assembler"] = {
			{
				["Name"] = "Assemble",
				["Type"] = "string",
				["Description"] = "The name of the object to be assembled.",
				["Default"] = "",
			},
		},
		["Sign"] = {
			{
				["Type"] = "string",
				["Default"] = "Text",
				["Description"] = "The text to display on the front of the sign. Rich text is allowed.",
				["Options"] = {
					["MaxLength"] = 256,
				},
				["Name"] = "SignText",
			},--[[PB]]
			{
				["Name"] = "TextColor",
				["Type"] = "Color3",
				["Description"] = "The color of the text on the sign.",
				["Default"] = "1,1,1",
			},
--[[PE]]--[[RM;
			{
				["Name"] = "TextColor",
				["Type"] = "Color3",
				["Description"] = "The color of the text on the sign.",
				["Default"] = "ffffff",
			},
;RM]]			{
				["Type"] = "Selection",
				["Default"] = {
					["Kind"] = "EnumItem",
					["EnumType"] = "Font",
					["Name"] = "SciFi",
				},
				["Description"] = "The font of the text on the sign.",
				["Options"] = {
					["Kind"] = "Enum",
					["Enum"] = "Font",
				},
				["Name"] = "TextFont",
			},
		},
		["Apparel"] = {
			{
				["Type"] = "Selection",
				["Default"] = 2,
				["Description"] = "The name of the limb that this Apparel is for.",
				["Options"] = {
					"Head",
					"Torso",
					"Left Arm",
					"Right Arm",
					"Left Leg",
					"Right Leg",
					"HumanoidRootPart",
				},
				["Name"] = "Limb",
			},
			{
				["Type"] = "number",
				["Default"] = 1,
				["Description"] = "The transparency of this Apparel.",
				["Options"] = {
					0,
					1,
				},
				["Name"] = "Transparency",
			},
		},
		["ConveyorBelt"] = {
			{
				["Type"] = "number",
				["Default"] = 10,
				["Description"] = "Determines the speed at which the conveyor will move items on top of it.",
				["Options"] = {
					-30,
					30,
				},
				["Name"] = "ConveyorBeltSpeed",
			},
		},
		["Hydroponic"] = {
			{
				["Type"] = "string",
				["Default"] = "Wood",
				["Description"] = "The material to grow from the Hydroponic.",
				["Options"] = {
					["MaxLength"] = 64,
				},
				["Name"] = "Grow",
			},
		},
		["HeatValve"] = {
			{
				["Name"] = "SwitchValue",
				["Type"] = "boolean",
				["Description"] = "Determines whether the switch is active or not.",
				["Default"] = false,
			},
		},
		["Reactor"] = {
			{
				["Name"] = "Alarm",
				["Type"] = "boolean",
				["Description"] = "Determines whether the reactor alarm system is enabled for when the reactor is near meltdown temperature.",
				["Default"] = true,
			},
			{
				["Name"] = "TriggerWhenEmpty",
				["Type"] = "boolean",
				["Description"] = "Determines whether or not the reactor will emit a trigger signal when its fuel is empty.",
				["Default"] = false,
			},
		},
		["GravityGenerator"] = {
			{
				["Type"] = "number",
				["Default"] = 1,
				["Description"] = "The amount of gravity within the influence of the GravityGenerator, measured in Gs.",
				["Options"] = {
					0.15,
					1.5,
				},
				["Name"] = "Gravity",
			},
		},
		["Hologram"] = {
			{
				["Type"] = "number",
				["Default"] = 1,
				["Description"] = "The UserId of the player for the Hologram to display.",
				["Options"] = {
					1,
					10000000000,
					1,
				},
				["Name"] = "UserId",
			},
		},
		["Prosthetic"] = {
			{
				["Type"] = "Selection",
				["Default"] = 2,
				["Description"] = "The name of the limb that this Prosthetic is for.",
				["Options"] = {
					"Head",
					"Torso",
					"Left Arm",
					"Right Arm",
					"Left Leg",
					"Right Leg",
					"HumanoidRootPart",
				},
				["Name"] = "Limb",
			},
		},
		["Rail"] = {
			{
				["Type"] = "number",
				["Default"] = 0,
				["Description"] = "Determines the position of the first state of the rail.",
				["Options"] = {
					0,
					100,
				},
				["Name"] = "Position1",
			},
			{
				["Type"] = "number",
				["Default"] = 100,
				["Description"] = "Determines the position of the second state of the rail.",
				["Options"] = {
					0,
					100,
				},
				["Name"] = "Position2",
			},
			{
				["Type"] = "number",
				["Default"] = 1,
				["Description"] = "Determines the time it takes for the rail to change positions.",
				["Options"] = {
					0.5,
					60,
				},
				["Name"] = "TweenTime",
			},
		},
		["Engine"] = {
			{
				["Type"] = "number",
				["Default"] = 10,
				["Description"] = "Determines the speed at which the engine is driven.",
				["Options"] = {
					-20,
					20,
				},
				["Name"] = "EngineSpeed",
			},
		},
		["LightBridge"] = {
			{
				["Description"] = "The color of the bridge's beam.",
				["Type"] = "Color3",
				["Name"] = "BeamColor",
				["Default"] = "0096ff",
			},
		},
		["Piston"] = {
			{
				["Type"] = "number",
				["Default"] = 0,
				["Description"] = "Determines the position of the first state of the piston.",
				["Options"] = {
					0,
					100,
				},
				["Name"] = "Position1",
			},
			{
				["Type"] = "number",
				["Default"] = 100,
				["Description"] = "Determines the position of the second state of the piston.",
				["Options"] = {
					0,
					100,
				},
				["Name"] = "Position2",
			},
			{
				["Type"] = "number",
				["Default"] = 10,
				["Description"] = "Determines the speed of the piston.",
				["Options"] = {
					0,
					50,
				},
				["Name"] = "Speed",
			},
		},
		["Anchor"] = {
			{
				["Name"] = "Anchored",
				["Type"] = "boolean",
				["Description"] = "Determines whether the anchor is active or not.",
				["Default"] = false,
			},
		},
		["Sorter"] = {
			{
				["Type"] = "string",
				["Default"] = "Power",
				["Description"] = "The kind of resource to push. May be a special or generic type like Gas, Solid, etc.",
				["Options"] = {
					["MaxLength"] = 24,
				},
				["Name"] = "Resource",
			},
			{
				["Type"] = "number",
				["Default"] = "inf",
				["Description"] = "How much of the resource to push per second. May be inf (or math.huge in a Microcontroller).",
				["Options"] = {
					0,
					"inf",
					1,
				},
				["Name"] = "Rate",
			},--[[PB]]
			{
				["Type"] = "number",
				["Default"] = "1",
				["Name"] = "TriggerQuantity"
			},--[[PE]]
		},
		["ProximityButton"] = {
			{
				["Type"] = "Selection",
				["Default"] = {
					["Kind"] = "EnumItem",
					["EnumType"] = "KeyCode",
					["Name"] = "E",
				},
				["Description"] = "The name of the key that will trigger the proximity prompt on a keyboard.",
				["Options"] = {
					["Kind"] = "Enum",
					["Enum"] = "KeyCode",
				},
				["Name"] = "KeyboardKeyCode",
			},
			{
				["Type"] = "Selection",
				["Default"] = {
					["Kind"] = "EnumItem",
					["EnumType"] = "KeyCode",
					["Name"] = "ButtonX",
				},
				["Description"] = "The name of the key that will trigger the proximity prompt on a gamepad.",
				["Options"] = {
					["Kind"] = "Enum",
					["Enum"] = "KeyCode",
				},
				["Name"] = "GamepadKeyCode",
			},
			{
				["Type"] = "string",
				["Default"] = "",
				["Description"] = "The text of the proximity prompt.",
				["Options"] = {
					["MaxLength"] = 64,
				},
				["Name"] = "ObjectText",
			},
			{
				["Name"] = "HoldDuration",
				["Type"] = "number",
				["Description"] = "The length of time that the proximity prompt has to be held down for.",
				["Default"] = 0.5,
			},
			{
				["Type"] = "number",
				["Default"] = 5,
				["Description"] = "The range of the prompt, from 0 - 50.",
				["Options"] = {
					0,
					50,
				},
				["Name"] = "MaxActivationDistance",
			},
			{
				["Name"] = "RequiresLineOfSight",
				["Type"] = "boolean",
				["Description"] = "Whether a line of sight to the center of the part is required for the prompt to become visible.",
				["Default"] = true,
			},
		},
		["MiningLaser"] = {
			{
				["Type"] = "Selection",
				["Default"] = "Any",
				["Description"] = "Determines the material to extract from the laser beam. Disables the laser if blank.",
				["Options"] = "Natural",
				["Name"] = "MaterialToExtract",
			},
		},
		["Tank"] = {
			{
				["Type"] = "string",
				["Default"] = "",
				["Description"] = "The kind of resource the bin can hold. You can set this to Any to allow the bin to accept anything.",
				["Options"] = {
					["MaxLength"] = 24,
				},
				["Name"] = "Resource",
			},
			{
				["Name"] = "CanBeCraftedFrom",
				["Type"] = "boolean",
				["Description"] = "Determines whether this Tank can be used by nearby players to craft objects.",
				["Default"] = true,
			},
		},
		["Bin"] = {
			{
				["Type"] = "string",
				["Default"] = "",
				["Description"] = "The kind of resource the bin can hold. You can set this to Any to allow the bin to accept anything.",
				["Options"] = {
					["MaxLength"] = 24,
				},
				["Name"] = "Resource",
			},
			{
				["Name"] = "CanBeCraftedFrom",
				["Type"] = "boolean",
				["Description"] = "Determines whether this bin can be used by nearby players to craft objects.",
				["Default"] = true,
			},
		},
		["Modem"] = {
			{
				["Type"] = "string",
				["Default"] = "M1",
				["Description"] = "The ID of the network this modem should connect to.",
				["Options"] = {
					["MaxLength"] = 64,
				},
				["Name"] = "NetworkID",
			},
		},
		["HyperDrive"] = {
			{
				["Type"] = "Coordinate",
				["Name"] = "Coordinates",
				["Description"] = "The coordinates to warp to.",
			},
		},
		["IonRocket"] = {
			{
				["Type"] = "number",
				["Default"] = 50,
				["Description"] = "Determines the speed traveled at, 0 being standstill. Affects fuel consumption.",
				["Options"] = {
					0,
					100,
				},
				["Name"] = "Propulsion",
			},
		},
		["VehicleSeat"] = {
			{
				["Type"] = "number",
				["Default"] = 1,
				["Description"] = "The speed at which the seat will rotate.",
				["Options"] = {
					0,
					10,
				},
				["Name"] = "Speed",
			},
			{
				["Type"] = "Selection",
				["Default"] = 1,
				["Description"] = "The control mode of the seat. Horizontal: Rotate horizontally with A/D. Full: Rotate horizontally and vertically with W/A/S/D. Mouse: point towards the player's mouse when holding click.",
				["Options"] = {
					"Horizontal",
					"Yaw/Pitch",
					"Full",
					"Mouse",
				},
				["Name"] = "Mode",
			},
			{
				["Name"] = "Enabled",
				["Type"] = "boolean",
				["Description"] = "Determines whether this seat should control its rotation. Turning this off results in a regular seat.",
				["Default"] = true,
			},
		},
		["Beacon"] = {
			{
				["Type"] = "string",
				["Default"] = "",
				["Description"] = "The name of the beacon.",
				["Options"] = {
					["MaxLength"] = 20,
				},
				["Name"] = "BeaconName",
			},
			{
				["Name"] = "ShowOnMap",
				["Type"] = "boolean",
				["Description"] = "Whether this beacon should be shown on StarMaps.",
				["Default"] = false,
			},
		},
		["TriggerSwitch"] = {
			{
				["Name"] = "SwitchValue",
				["Type"] = "boolean",
				["Description"] = "Determines whether the switch is active or not.",
				["Default"] = false,
			},
		},
		["StorageSensor"] = {
			{
				["Name"] = "QuantityRange",
				["Type"] = "NumberRange",
				["Description"] = "The range of item quantities within which this sensor will trigger.",
				["Default"] = {
					0,
					10,
				},
			},
		},
		["Boombox"] = {
			{
				["Name"] = "Audio",
				["Type"] = "number",
				["Description"] = "The audio asset ID to be played.",
				["Default"] = 142376088,
			},
		},
		["Turbofan"] = {
			{
				["Type"] = "number",
				["Default"] = 5,
				["Description"] = "Determines the speed at which the turbofan is driven, or the speed at which it travels.",
				["Options"] = {
					0,
					100,
				},
				["Name"] = "TurboFanSpeed",
			},
		},
		["Camera"] = {
			{
				["Type"] = "number",
				["Default"] = 0,
				["Description"] = "The ID to transmit the camera feed over, received by screens of the same ID.",
				["Options"] = {
					0,
					10000000000,
					1,
				},
				["Name"] = "VideoID",
			},
		},
		["Router"] = {
			{
				["Type"] = "string",
				["Default"] = "R1",
				["Description"] = "The ID of this router, to transmit to others with the same ID.",
				["Options"] = {
					["MaxLength"] = 64,
				},
				["Name"] = "RouterID",
			},
		},
		["Relay"] = {
			{
				["Type"] = "Selection",
				["Default"] = 0,
				["Description"] = "The mode of the relay. Send outputs materials to other receiving relays; Receive receives materials from sending relays.",
				["Options"] = {
					"Send",
					"Receive",
				},
				["Name"] = "Mode",
			},
			{
				["Type"] = "number",
				["Default"] = 1,
				["Description"] = "The ID of the relay, to send or take materials to or from other relays with the same ID.",
				["Options"] = {
					1,
					10000000000,
					1,
				},
				["Name"] = "LinkerID",
			},
		},
		["Solenoid"] = {
			{
				["Name"] = "Inverted",
				["Type"] = "boolean",
				["Description"] = "Whether or not the state will be inverted.",
				["Default"] = false,
			},
			{
				["Name"] = "PowerRange",
				["Type"] = "NumberRange",
				["Description"] = "The power range the state will be active for.",
				["Default"] = {
					0,
					"inf",
				},
			},
		},
		["ObjectDetector"] = {
			{
				["Type"] = "number",
				["Default"] = 1000,
				["Description"] = "The range that it can detect an object. Must be between 0 and 1000.",
				["Options"] = {
					0,
					1000,
				},
				["Name"] = "MaxDistance",
			},
			{
				["Type"] = "Vector2",
				["Default"] = {
					0,
					1,
				},
				["Description"] = "The range that it will trigger if it detect an object.",
				["Options"] = {
					0,
					1000,
				},
				["Name"] = "TriggerAtDistance",
			},
		},
	},
}
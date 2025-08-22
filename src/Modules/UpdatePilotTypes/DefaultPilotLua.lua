--!nolint UnknownGlobal
-- PilotLua Globals: Beep, FileSystem, GetCPUTime, GetPart, GetPartFromPort, GetParts, GetPartsFromPort, GetPort, GetPorts, JSONDecode, JSONEncode, Microcontroller, Network, RawFileSystem, SandboxID, SandboxRunID, TriggerPort, logError, pilot
type JSONValue = string | number | boolean | buffer
type JSON = {
	[JSONValue]: JSON,
} | { JSON } | JSONValue
export type ComponentName = "Blade" | "KeyButton" | "ClickButton" | "Hull" | "Door"
export type Permission = "Modify" | "Unlock" | "Paint" | "Configure" | "Interact" | "Attach"
export type TemperatureUnit = "K" | "F" | "C"
export type CanvasContext = "2D" | "3D"
export type HandleTriggerMode = "MouseDown" | "MouseUp" | "Both"
export type VehicleSeatMode = "Horizontal" | "Yaw/Pitch" | "Full" | "Mouse"
export type PolysiliconMode = "Activate" | "Deactivate" | "FlipFlop"
export type RelayMode = "Send" | "Receive"
export type InstrumentType = "Speed" | "AngularSpeed" | "Temperature" | "Time" | "Power" | "Size" | "Position" | "TemperatureF" | "Orientation" | "TemperatureC" | "AirTemperatureF" | "AirTemperatureC"
export type PlayerLimb = "Head" | "Torso" | "Left Arm" | "Right Arm" | "Left Leg" | "Right Leg" | "HumanoidRootPart"
export type BladeShape = "Block" | "Spheroid" | "Cone"
export type HandleSwingMode = "None" | "Swing" | "Point"
export type RemoteControlMode = "EmitFromTarget" | "SendDirectly"
export type RegionLog = {
	TimeAgo: number,
	Event: RegionLogType,
	Desc: string,
}
export type RegionLogType = "HyperDrive is warping to" | "Aliens were spawned from an obelisk located at" | "Spawned" | "Death" | "ExitRegion" | "Poison" | "Irradiated" | "Suffocating" | "Freezing" | "Melting"
export type Network = {
	GetPort: (self: Network, port: PortLike?) -> ({ Port }),
	GetPartsFromPort: (self: Network, port: PortLike?, className: string?) -> ({ PilotObject }),
	GetPart: (self: Network, className: string?) -> (PilotObject?),
	GetPartFromPort: (self: Network, port: PortLike?, className: string?) -> (PilotObject?),
	GetSubnet: (self: Network, port: PortLike?) -> (Network),
	GetParts: (self: Network, className: string?) -> ({ PilotObject }),
	GetHistory: (self: Network) -> ({
		[PilotObject]: true,
	}),
	GetPorts: (self: Network, port: PortLike?) -> ({ Port }),
	__index: Network,
	new: (rootParts: { PilotObject }, parentNetwork: Network?) -> (Network),
}
export type Range = string
export type ARCamera = {
	FieldOfViewMode: Enum.FieldOfViewMode,
	FieldOfView: number,
	CFrame: CFrame,
	NearPlaneZ: number,
	ViewportSizeUI: Vector2,
	RenderCFrame: CFrame,
	CameraType: Enum.CameraType,
	Focus: CFrame,
	HeadScale: number,
	ViewportSize: Vector2,
	MaxAxisFieldOfView: number,
	DiagonalFieldOfView: number,
}
export type ARCursor = {
	WorldPosition: Vector3,
	Origin: Vector3,
	UserId: number,
	Target: PilotObject,
	Pressed: boolean,
	UnitRay: Ray,
	Camera: ARCamera,
	ScreenPosition: Vector2,
	UserCFrames: {
		RightHand: CFrame,
		LeftHand: CFrame,
		Head: CFrame,
	},
	Y: number,
	Player: string,
	VirtualWorldPosition: Vector3,
	Hit: CFrame,
	X: number,
	VirtualTarget: BasePart,
	MouseDelta: Vector2,
	UserInput: ARInput,
}
type ARInput = {
	Keyboard: { InputObject },
	VREnabled: boolean,
	Mouse: { InputObject },
	GamepadEnabled: boolean,
	LastInputType: Enum.UserInputType,
	Gamepad: {
		[Enum.UserInputType]: { InputObject },
	},
	KeyboardEnabled: boolean,
	TouchEnabled: boolean,
}
export type UserInputObject = {
	KeyName: string,
	UserInputState: Enum.UserInputState,
	UserInputType: Enum.UserInputType,
	KeyCode: Enum.KeyCode,
}
export type Cursor = {
	Y: number,
	Player: string,
	X: number,
	UserId: number,
	Pressed: boolean,
}
export type ObjectDetectorHitNothing = {
	Distance: number,
	Name: never,
	Position: never,
	Color: never,
	isTerrain: true,
	CFrame: never,
	Size: never,
}
export type ObjectDetectorHitTerrain = {
	Distance: number,
	Name: "Head" | "Torso" | "Left Arm" | "Right Arm" | "Left Leg" | "Right Leg" | "Collider" | string,
	Position: Vector3,
	Color: Color3,
	isTerrain: true,
	CFrame: CFrame,
	Size: Vector3,
}
export type ObjectDetectorHitData = ObjectDetectorHitNothing | ObjectDetectorHitTerrain | ObjectDetectorHitObject
export type ObjectDetectorHitObject = {
	Color: Color3,
	LockedBy: number?,
	Distance: number,
	Name: string,
	Position: Vector3,
	Size: Vector3,
	isTerrain: false,
	CFrame: CFrame,
	CreatedBy: number?,
}
export type ResourceString = string
export type PortLike = Port | number
export type ModemRequestResponse = {
	StatusMessage: string,
	Success: boolean,
	StatusCode: number,
	Headers: {
		[string]: any,
	},
	Body: any,
}
export type ModemRequest = {
	Method: ("GET" | "POST" | "PUSH" | "PATCH" | "DELETE")?,
	Compress: Enum.HttpCompression?,
	Url: string,
	Headers: {
		[string]: any,
	}?,
	Body: string?,
}
type MethodParameter = {
	Type: string?,
	Description: string?,
	Name: string?,
}
export type MethodData = {
	Name: string,
	Arguments: { MethodParameter },
	Description: string?,
	Results: { MethodParameter },
}
export type ConfigurableData = {
	Type: string,
	Description: string,
	Options: ({ string } | { number })?,
	DefaultValue: any?,
	Name: string,
}
export type FileSystem = {
	split: (pathname: string) -> ({ string }),
	copy: (self: FileSystem, pathnameFrom: string, pathnameTo: string?) -> (),
	mkdir: (self: FileSystem, pathname: string?) -> (),
	pwd: (self: FileSystem) -> (string),
	readdir: (self: FileSystem, pathname: string) -> ({ string }),
	__index: FileSystem,
	new: (source: (FileSystemRoot | FileSystemDirectory)?) -> (FileSystem),
	separator: string,
	resolve: (pathname: string) -> (string),
	parentdir: (pathname: string) -> (string),
	join: (...string) -> (string),
	filename: (pathname: string) -> (string),
	unlink: (self: FileSystem, pathname: string) -> (),
	readfile: (self: FileSystem, filepath: string) -> (string),
	exists: (pathname: string) -> (boolean),
	moveMerge: (self: FileSystem, pathnameFrom: string, pathnameTo: string?) -> (),
	mklink: (self: FileSystem, linkName: string, targetName: string?) -> (),
	writefile: (self: FileSystem, filepath: string, contents: string) -> (),
	rename: (self: FileSystem, pathnameFrom: string, pathnameTo: string?) -> (),
	chdir: (self: FileSystem, pathname: string) -> (string),
}
export type RawFileSystem = {
	SYSTEM_READONLY: FileAttributes,
	Directory: (contents: {
		[string]: FileSystemFileNode,
	}, attributes: FileAttributes, readonly: boolean?) -> (FileSystemDirectory),
	write: (self: RawFileSystem, root: FileSystemRoot, pathname: string, node: FileSystemFileNode, options: FileSystemOperationOptions?) -> (),
	Link: (pathname: string, attributes: FileAttributes) -> (FileSystemLink),
	Device: (device: any, attributes: FileAttributes) -> (FileSystemDevice),
	SYSTEM_NOACCESS: FileAttributes,
	read: (self: RawFileSystem, root: FileSystemRoot, pathname: string, options: FileSystemOperationOptions?) -> (FileSystemFileNode?),
	readlink: (self: RawFileSystem, root: FileSystemRoot, link: FileSystemLink, options: FileSystemOperationOptions?) -> (FileSystemFileNode?),
	File: (contents: string, attributes: FileAttributes) -> (FileSystemFile),
	Root: (root: FileSystemDirectory, attributes: FileAttributes) -> (FileSystemRoot),
}
type primitive = string | number | boolean | { primitive } | {
	[primitive]: primitive,
}
export type FileSystemDevice = {
	device: any,
	kind: "device",
	attributes: FileAttributes?,
}
export type FileSystemFile = {
	kind: "file",
	attributes: FileAttributes?,
	contents: string,
}
export type FileSystemFileNode = FileSystemDirectory | FileSystemFile | FileSystemLink | FileSystemRoot | FileSystemDevice
export type FileSystemLink = {
	target: string,
	kind: "link",
	attributes: FileAttributes?,
}
export type FileSystemRoot = {
	pwd: string,
	kind: "root",
	attributes: FileAttributes?,
	root: FileSystemDirectory,
}
export type FileSystemDirectory = {
	kind: "directory",
	attributes: FileAttributes?,
	contents: {
		[string]: FileSystemFileNode,
	},
}
export type FileAttributes = {
	permissions: ({
		userPermissions: {
			[number]: FilePermissions,
		}?,
		owner: "system" | number,
	} | FilePermissions)?,
	metadata: {
		[primitive]: primitive,
	}?,
}
export type FilePermissions = {
	write: boolean?,
	read: boolean?,
}
export type FileSystemOperationOptions = {
	ignorePermissions: boolean?,
	ignoreLinks: boolean?,
}
type TerrainData = {
	TreeSettings: {
		branch_size_percentage: {
			max: {
				height: number,
				width: number,
			},
			min: {
				height: number,
				width: number,
			},
		},
		branch_angles: { number },
		trunk_size: {
			max: {
				height: number,
				width: number,
			},
			min: {
				height: number,
				width: number,
			},
		},
		branch_offset: { number },
		amount_of_branches: { number },
		amount_of_splits: { number },
	},
	Slopes: { number },
	Life: boolean,
	Water: boolean,
	Temperature: { number },
	Height: { number },
	RockDensity: { number },
	MountainDensity: { number },
	Roughness: { number },
}
export type CompleteRegionInfo = OrbitRegionInfo | SpaceRegionInfo | BlackHoleRegionInfo | StarRegionInfo | PlanetRegionInfo
export type PlanetRegionInfo = {
	StarType: never,
	BlackHoleSize: never,
	StarSize: never,
	OrbitBody: never,
	PlanetData: {
		DayCycleIncrement: number,
		EnterLocation: RegionEntryLocation,
		PrimaryColor: RegionColor,
		Gravity: number,
		TerrainConfig: TerrainData,
		GenerationHeightScale: number,
		Temperature: number,
		Rings: RingData?,
		PlanetType: PlanetType,
		StartingTime: number,
		Atmosphere: boolean,
		Resources: { string },
		SecondaryColor: RegionColor,
		PlanetMaterial: "Grass" | "Sand" | "Snow" | "Rock1" | "Rock2",
	},
} & PlayableRegionInfo
export type StarRegionInfo = {
	StarType: StarType,
	BlackHoleSize: never,
	EnterLocation: RegionEntryLocation,
	StarSize: number,
	OrbitBody: never,
	PlanetData: never,
} & PlayableRegionInfo
type RegionColor = {
	B: number,
	G: number,
	R: number,
}
export type OrbitRegionInfo = {
	OrbitBody: BlackHoleRegionInfo | StarRegionInfo | PlanetRegionInfo,
	RegionType: "Orbit",
} & PlayableRegionInfo
export type PlayableRegionInfo = {
	Name: string,
	EnterLocation: RegionEntryLocation,
	Coordinate: Coordinates,
	StringCoordinate: string,
	RegionServer: string,
	RegionSeed: number,
}
type RegionEntryLocation = {
	Y: number,
	X: number,
	Z: number,
}
type RingData = {
	RingsAmount: number,
	RingsEnd: number,
	RingsType: "Ice" | "Stone",
	RingStart: number,
}
export type SpaceRegionInfo = {
	RegionType: "Space",
	OrbitBody: never,
} & PlayableRegionInfo
export type BlackHoleRegionInfo = {
	StarSize: never,
	BlackHoleSize: number,
	EnterLocation: RegionEntryLocation,
	StarType: never,
	OrbitBody: never,
	PlanetData: never,
} & PlayableRegionInfo
export type Coordinates = typeof(setmetatable(
	{} :: {
		InPlanet: boolean,
		SolarCoordinates: Vector2,
		UniverseCoordinates: Vector2,
	},
	{} :: CoordinatesMetatable
))
type CoordinatesMetatable = {
	type: "Coordinates",
	__eq: (self: Coordinates, Coordinates) -> (boolean),
	__mul: (self: Coordinates, Coordinates) -> (Coordinates),
	ToArray: (self: Coordinates) -> ({ number | boolean }),
	__add: (self: Coordinates, Coordinates) -> (Coordinates),
	__div: (self: Coordinates, Coordinates) -> (Coordinates),
	Clone: (self: Coordinates) -> (Coordinates),
	GetRandom: (self: Coordinates) -> (Random),
	GetSeed: (self: Coordinates) -> (number),
	CoordStringWithoutPlanet: (self: Coordinates) -> (string),
	__index: CoordinatesMetatable,
	__tostring: (self: Coordinates) -> (string),
}
export type SimplePlanetRegionInfo = {
	HasAtmosphere: boolean,
	Type: "Planet",
	Color: Color3,
	Gravity: number,
	SubType: PlanetType,
	BeaconCount: number,
	Name: string,
	Resources: { string },
	TidallyLocked: boolean,
	HasRings: boolean,
}
export type SimpleSpaceRegionInfo = {
	BeaconCount: number,
	Type: "Planet",
	Name: string,
	HasRings: boolean,
	SubType: never,
	TidallyLocked: boolean,
}
export type SimpleStarRegionInfo = {
	BeaconCount: number,
	Type: "Star",
	Name: string,
	SubType: StarType,
	Size: number,
}
export type RegionInfo = SimpleSpaceRegionInfo | SimplePlanetRegionInfo | SimpleBlackHoleRegionInfo | SimpleStarRegionInfo
export type SimpleBlackHoleRegionInfo = {
	BeaconCount: number,
	Type: "BlackHole",
	Name: string,
	Size: number,
}
export type StarType = "Red" | "Orange" | "Yellow" | "Blue" | "Neutron"
export type CelestialBodyType = "Planet" | "BlackHole" | "Star"
export type PlanetType = "Desert" | "Terra" | "EarthLike" | "Ocean" | "Tundra" | "Forest" | "Exotic" | "Barren" | "Gas" | "RobotDepot" | "RobotFactory"
type EventConnectionMetatable<Name = string, Callback = (...unknown) -> ()> = {
	Unbind: (self: EventConnection<Name, Callback>) -> (),
	__index: EventConnectionMetatable<Name, Callback>,
	Disconnect: (self: EventConnection<Name, Callback>) -> (),
	__mode: "v",
}
export type Event<Name = string, Callback = (...unknown) -> (), Parameters... = ...unknown> = {
	_eventName: Name,
	Connect: (self: Event<Name, Callback, Parameters...>, callback: Callback) -> (EventConnection<Name, Callback>),
}
export type EventConnection<Name = string, Callback = (...unknown) -> ()> = typeof(setmetatable(
	{} :: {
		_eventName: Name,
		Callback: Callback,
	},
	{} :: EventConnectionMetatable<Name, Callback>
))
export type TouchScreen = Screen & {
	CursorReleased: Event<"CursorReleased", (Cursor: Cursor) -> ()>,
	CursorMoved: Event<"CursorMoved", (Cursor: Cursor) -> ()>,
	GetCursor: (self: TouchScreen, username: string) -> (Cursor),
	ClassName: "TouchScreen",
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	GetCursors: (self: TouchScreen) -> ({
		[string]: Cursor,
	}),
	CursorPressed: Event<"CursorPressed", (Cursor: Cursor) -> ()>,
}
export type PilotObject = {
	Durability: number,
	CFrame: CFrame,
	IsDestroyed: (self: PilotObject) -> (boolean),
	Mass: number,
	GetColor: (self: PilotObject) -> (Color3),
	Click: (self: PilotObject) -> (),
	GetNameOfOwnerAsync: (self: PilotObject) -> (string?),
	GetConfigurables: (self: PilotObject) -> ({
		[string]: ConfigurableData,
	}),
	AssemblyMass: number,
	AssemblyLinearVelocity: Vector3,
	Health: number,
	ClassName: "PilotObject",
	Orientation: Vector3,
	AssemblyCenterOfMass: Vector3,
	CreatedBy: number?,
	GetComponent: (self: PilotObject, componentName: ComponentName) -> (Component?),
	Heat: number,
	Destroying: Event<"Destroying", () -> ()>,
	Color: Color3,
	CanUninstallComponent: (self: PilotObject, componentName: ComponentName?) -> (boolean),
	HasComponent: (self: PilotObject) -> (boolean),
	Material: Enum.Material,
	PartLocked: number?,
	GetEvents: (self: PilotObject) -> ({ string }),
	CanInstallComponent: (self: PilotObject, componentName: ComponentName?) -> (boolean),
	Anchored: boolean,
	GetOwnerId: (self: PilotObject) -> (number?),
	GetShape: (self: PilotObject) -> (string?),
	Trigger: (self: PilotObject) -> (),
	GetDurability: (self: PilotObject) -> (number),
	GUID: string,
	GetMethods: (self: PilotObject) -> ({
		[string]: MethodData,
	}),
	ListComponents: (self: PilotObject) -> ({ string }),
	Temperature: number,
	HasPermission: (self: PilotObject, permission: Permission) -> (boolean),
	Position: Vector3,
	IsGrounded: (self: PilotObject) -> (boolean),
	Size: Vector3,
	GetSize: (self: PilotObject) -> (Vector3),
	GetTemperature: (self: PilotObject) -> (number),
}
export type Spotlight = PilotObject & {
	ClassName: "Spotlight",
	SetColor: (self: Spotlight, color: Color3) -> (),
}
export type Silicon = PilotObject & {
	ClassName: "Silicon",
}
export type Beacon = PilotObject & {
	ShowOnMap: boolean,
	BeaconName: string,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	ClassName: "Beacon",
	Configure: (self: Beacon, configuration: BeaconConfiguration) -> (),
}
export type Port = PilotObject & {
	PortID: number,
	Configure: (self: Port, configuration: PortConfiguration) -> (),
	Triggered: Event<"Triggered", (otherPart: PilotObject) -> ()>,
	ClassName: "Port",
}
export type Switch = PilotObject & {
	Configure: (self: Switch, configuration: SwitchConfiguration) -> (),
	ClassName: "Switch",
	SwitchValue: boolean,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	OnClick: Event<"OnClick", (clickerId: number) -> ()>,
}
export type Tank = PilotObject & {
	ContainerChanged: Event<"ContainerChanged", (resourceType: "Power" | "Solid" | "Fluid", resourceAmount: number) -> ()>,
	Configure: (self: Tank, configuration: TankConfiguration) -> (),
	Resource: string,
	CanBeCraftedFrom: boolean,
	GetResourceAmount: (self: Tank) -> (number),
	ClassName: "Tank",
	GetAmount: (self: Tank) -> (number),
	OnClick: Event<"OnClick", (clickerId: number) -> ()>,
	GetResource: (self: Tank) -> (string | "nil"),
}
export type NuclearWaste = PilotObject & {
	ClassName: "NuclearWaste",
}
export type HyperspaceRadar = PilotObject & {
	ViewCoordinates: Coordinates,
	Configure: (self: HyperspaceRadar, configuration: HyperspaceRadarConfiguration) -> (),
	ClassName: "HyperspaceRadar",
}
export type Asphalt = PilotObject & {
	ClassName: "Asphalt",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type Boiler = PilotObject & {
	ClassName: "Boiler",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type SMG = PilotObject & {
	ClassName: "SMG",
}
export type Plasma = PilotObject & {
	ClassName: "Plasma",
}
export type Kiln = PilotObject & {
	ClassName: "Kiln",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type Copper = PilotObject & {
	ClassName: "Copper",
}
export type CornerWedge = PilotObject & {
	ClassName: "CornerWedge",
}
export type Propeller = PilotObject & {
	ClassName: "Propeller",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type Bin = PilotObject & {
	ContainerChanged: Event<"ContainerChanged", (resourceType: "Power" | "Solid" | "Fluid", resourceAmount: number) -> ()>,
	Configure: (self: Bin, configuration: BinConfiguration) -> (),
	Resource: string,
	CanBeCraftedFrom: boolean,
	GetResourceAmount: (self: Bin) -> (number),
	ClassName: "Bin",
	GetAmount: (self: Bin) -> (number),
	OnClick: Event<"OnClick", (clickerId: number) -> ()>,
	GetResource: (self: Bin) -> (string | "nil"),
}
export type Refinery = PilotObject & {
	ClassName: "Refinery",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type SolarScoop = PilotObject & {
	ClassName: "SolarScoop",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type Handle = PilotObject & {
	TriggerMode: HandleTriggerMode,
	ClassName: "Handle",
	Configure: (self: Handle, configuration: HandleConfiguration) -> (),
	Swing: HandleSwingMode,
	ToolName: string,
}
export type Door = PilotObject & {
	ComponentsUpdated: Event<"ComponentsUpdated", (...any) -> ()>,
	ClassName: "Door",
}
export type Uranium = PilotObject & {
	ClassName: "Uranium",
}
export type DevBattery = PilotObject & {
	ContainerChanged: Event<"ContainerChanged", (resourceType: "Power" | "Solid" | "Fluid", resourceAmount: number) -> ()>,
	GetAmount: (self: DevBattery) -> (number),
	ClassName: "DevBattery",
	GetResourceAmount: (self: DevBattery) -> (number),
	GetResource: (self: DevBattery) -> (string | "nil"),
}
export type Oil = PilotObject & {
	ClassName: "Oil",
}
export type Transporter = PilotObject & {
	Configure: (self: Transporter, configuration: TransporterConfiguration) -> (),
	ClassName: "Transporter",
	TransporterID: string,
}
export type Relay = PilotObject & {
	LinkerID: number,
	Mode: RelayMode,
	Configure: (self: Relay, configuration: RelayConfiguration) -> (),
	ClassName: "Relay",
}
export type FourthOfJuly = PilotObject & {
	Triggered: Event<"Triggered", (otherPart: PilotObject) -> ()>,
	Damaged: Event<"Damaged", (damage: number, damageType: "Kinetic" | "Energy", damageSource: PilotObject?) -> ()>,
	ClassName: "FourthOfJuly",
}
export type Button = PilotObject & {
	ClassName: "Button",
}
export type Hologram = PilotObject & {
	Configure: (self: Hologram, configuration: HologramConfiguration) -> (),
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	UserId: number,
	ClassName: "Hologram",
}
export type Titanium = PilotObject & {
	ClassName: "Titanium",
}
export type Shotgun = PilotObject & {
	ClassName: "Shotgun",
}
export type Egg = PilotObject & {
	ClassName: "Egg",
}
export type Plastic = PilotObject & {
	ClassName: "Plastic",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type ConveyorBelt = PilotObject & {
	ConveyorBeltSpeed: number,
	Configure: (self: ConveyorBelt, configuration: ConveyorBeltConfiguration) -> (),
	ClassName: "ConveyorBelt",
}
export type Radiator = PilotObject & {
	ClassName: "Radiator",
}
export type Sign = PilotObject & {
	TextFont: string,
	Configure: (self: Sign, configuration: SignConfiguration) -> (),
	ClassName: "Sign",
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	TextColor: Color3,
	SignText: string,
}
export type Cylinder = PilotObject & {
	ClassName: "Cylinder",
}
export type EnergySword = PilotObject & {
	ClassName: "EnergySword",
}
export type WindTurbine = PilotObject & {
	ClassName: "WindTurbine",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type Gyro = PilotObject & {
	Configure: (self: Gyro, configuration: GyroConfiguration) -> (),
	DisableWhenUnpowered: boolean,
	MaxTorque: number,
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	TriggerWhenSeeked: boolean,
	ClassName: "Gyro",
	PointAlong: (self: Gyro, direction: Vector3, up: Vector3?) -> (),
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	PointAt: (self: Gyro, position: Vector3, up: Vector3?) -> (),
	Seek: string,
}
export type Flashlight = PilotObject & {
	ClassName: "Flashlight",
}
export type GravityGenerator = PilotObject & {
	Gravity: number,
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	Configure: (self: GravityGenerator, configuration: GravityGeneratorConfiguration) -> (),
	ClassName: "GravityGenerator",
}
export type FloatDevice = PilotObject & {
	ClassName: "FloatDevice",
}
export type Hydroponic = PilotObject & {
	Grow: string,
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	Configure: (self: Hydroponic, configuration: HydroponicConfiguration) -> (),
	ClassName: "Hydroponic",
}
export type Framewire = PilotObject & {
	ClassName: "Framewire",
}
export type Goo = PilotObject & {
	ClassName: "Goo",
}
export type Sorter = PilotObject & {
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	Sort: (self: Sorter, amount: number?) -> (),
	ClassName: "Sorter",
	Configure: (self: Sorter, configuration: SorterConfiguration) -> (),
	TriggerQuantity: number,
	Rate: number,
	Resource: string,
}
export type Blade = PilotObject & {
	ComponentsUpdated: Event<"ComponentsUpdated", (...any) -> ()>,
	Configure: (self: Blade, configuration: BladeConfiguration) -> (),
	Shape: BladeShape,
	ClassName: "Blade",
}
export type Gun = PilotObject & {
	ClassName: "Gun",
}
export type VintagePlasmaPistol = PilotObject & {
	ClassName: "VintagePlasmaPistol",
}
export type Heater = PilotObject & {
	ClassName: "Heater",
}
export type Hotdog = PilotObject & {
	ClassName: "Hotdog",
}
export type Gold = PilotObject & {
	ClassName: "Gold",
}
export type Microphone = PilotObject & {
	Chatted: Event<"Chatted", (player: number, message: string) -> ()>,
	ClassName: "Microphone",
}
export type Aerogel = PilotObject & {
	ClassName: "Aerogel",
}
export type Katana = PilotObject & {
	ClassName: "Katana",
}
export type Lantern = PilotObject & {
	ClassName: "Lantern",
}
export type Beaker = PilotObject & {
	ClassName: "Beaker",
}
export type StorageSensor = PilotObject & {
	Configure: (self: StorageSensor, configuration: StorageSensorConfiguration) -> (),
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	QuantityRange: Range,
	ClassName: "StorageSensor",
}
export type PDWX44 = PilotObject & {
	ClassName: "PDW-X44",
}
export type TouchSensor = PilotObject & {
	Touched: Event<"Touched", (object: (number | PilotObject)?) -> ()>,
	ClassName: "TouchSensor",
}
export type PlasmaCannon = PilotObject & {
	ClassName: "PlasmaCannon",
}
export type EnergyShield = PilotObject & {
	Configure: (self: EnergyShield, configuration: EnergyShieldConfiguration) -> (),
	GetShieldHealth: (self: EnergyShield) -> (number),
	ShieldStrength: number,
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	CalculateCost: (self: EnergyShield, radius: number?) -> (number),
	ClassName: "EnergyShield",
	ShieldRadius: number,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	RegenerationSpeed: number,
	SetColor: (self: EnergyShield, color: Color3) -> (),
}
export type SmoothReinforcedGlass = PilotObject & {
	ClassName: "SmoothReinforcedGlass",
}
export type Pulverizer = PilotObject & {
	ClassName: "Pulverizer",
}
export type RegionCloaker = PilotObject & {
	ClassName: "RegionCloaker",
}
export type Rice = PilotObject & {
	ClassName: "Rice",
}
export type Hydrogen = PilotObject & {
	ClassName: "Hydrogen",
}
export type EnergyBomb = PilotObject & {
	Triggered: Event<"Triggered", (otherPart: PilotObject) -> ()>,
	Damaged: Event<"Damaged", (damage: number, damageType: "Kinetic" | "Energy", damageSource: PilotObject?) -> ()>,
	ClassName: "EnergyBomb",
}
export type SmoothGlass = PilotObject & {
	ClassName: "SmoothGlass",
}
export type Primer = PilotObject & {
	ClassName: "Primer",
}
export type tinnitus = PilotObject & {
	ClassName: "tinnitus",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type Constructor = PilotObject & {
	CalculateModelRecipe: (self: Constructor, modelCode: string) -> ({
		[string]: number,
	}),
	Configure: (self: Constructor, configuration: ConstructorConfiguration) -> (),
	ModelCode: string,
	ClassName: "Constructor",
	Triggered: Event<"Triggered", (otherPart: PilotObject) -> ()>,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	Autolock: boolean,
	RelativeToConstructor: boolean,
}
export type AirSupply = PilotObject & {
	ClassName: "AirSupply",
}
export type Spheroid = PilotObject & {
	ClassName: "Spheroid",
}
export type HeatValve = PilotObject & {
	Configure: (self: HeatValve, configuration: HeatValveConfiguration) -> (),
	ClassName: "HeatValve",
	SwitchValue: boolean,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	OnClick: Event<"OnClick", (clickerId: number) -> ()>,
}
export type TriggerWire = PilotObject & {
	ClassName: "TriggerWire",
}
export type Truss = PilotObject & {
	ClassName: "Truss",
}
export type StudAligner = PilotObject & {
	ClassName: "StudAligner",
}
export type Artillery = PilotObject & {
	ClassName: "Artillery",
}
export type Tire = PilotObject & {
	ClassName: "Tire",
}
export type HalfSphere = PilotObject & {
	ClassName: "HalfSphere",
}
export type Rifle = PilotObject & {
	ClassName: "Rifle",
}
export type Anchor = PilotObject & {
	Anchored: boolean,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	Configure: (self: Anchor, configuration: AnchorConfiguration) -> (),
	ClassName: "Anchor",
}
export type Flint = PilotObject & {
	ClassName: "Flint",
}
export type Wire = PilotObject & {
	ClassName: "Wire",
}
export type Wing = PilotObject & {
	ClassName: "Wing",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type ZapWire = PilotObject & {
	ClassName: "ZapWire",
}
export type RustedMetal = PilotObject & {
	ClassName: "RustedMetal",
}
export type Dispenser = PilotObject & {
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	Filter: string,
	ClassName: "Dispenser",
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	Configure: (self: Dispenser, configuration: DispenserConfiguration) -> (),
	Dispense: (self: Dispenser) -> (),
}
export type Railgun = PilotObject & {
	Triggered: Event<"Triggered", (otherPart: PilotObject) -> ()>,
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	Damaged: Event<"Damaged", (damage: number, damageType: "Kinetic" | "Energy", damageSource: PilotObject?) -> ()>,
	ClassName: "Railgun",
}
export type AlienCore = PilotObject & {
	ClassName: "AlienCore",
}
export type MustardGas = PilotObject & {
	ClassName: "MustardGas",
}
export type Beryllium = PilotObject & {
	ClassName: "Beryllium",
}
export type ChemicalSynthiser = PilotObject & {
	ClassName: "ChemicalSynthiser",
}
export type Coal = PilotObject & {
	ClassName: "Coal",
}
export type Melter = PilotObject & {
	ClassName: "Melter",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type DarkMatter = PilotObject & {
	ClassName: "DarkMatter",
}
export type Freezer = PilotObject & {
	ClassName: "Freezer",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type Diamond = PilotObject & {
	ClassName: "Diamond",
}
export type CornerRoundWedge = PilotObject & {
	ClassName: "CornerRoundWedge",
}
export type ExoticMatter = PilotObject & {
	ClassName: "ExoticMatter",
}
export type Valve = PilotObject & {
	Configure: (self: Valve, configuration: ValveConfiguration) -> (),
	ClassName: "Valve",
	SwitchValue: boolean,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	OnClick: Event<"OnClick", (clickerId: number) -> ()>,
}
export type Wedge = PilotObject & {
	ClassName: "Wedge",
}
export type Part100k = PilotObject & {
	Triggered: Event<"Triggered", (otherPart: PilotObject) -> ()>,
	OnClick: Event<"OnClick", (clickerId: number) -> ()>,
	ClassName: "100k",
}
export type Glass = PilotObject & {
	ClassName: "Glass",
}
export type ImpulseCannon = PilotObject & {
	ClassName: "ImpulseCannon",
}
export type Seat = PilotObject & {
	OccupantChanged: Event<"OccupantChanged", (newOccupant: number?) -> ()>,
	EjectOccupant: (self: Seat) -> (),
	GetOccupant: (self: Seat) -> (number?),
	ClassName: "Seat",
}
export type PlutoniumCore = PilotObject & {
	ClassName: "PlutoniumCore",
}
export type Grass = PilotObject & {
	ClassName: "Grass",
}
export type HeatSink = PilotObject & {
	ClassName: "HeatSink",
}
export type Heatshield = PilotObject & {
	ClassName: "Heatshield",
}
export type Helium = PilotObject & {
	ClassName: "Helium",
}
export type Rubber = PilotObject & {
	ClassName: "Rubber",
}
export type Mandrillium = PilotObject & {
	ClassName: "Mandrillium",
}
export type Lava = PilotObject & {
	ClassName: "Lava",
}
export type DevTeleporter = PilotObject & {
	TeleporterID: string,
	Configure: (self: DevTeleporter, configuration: DevTeleporterConfiguration) -> (),
	ClassName: "DevTeleporter",
}
export type Jade = PilotObject & {
	ClassName: "Jade",
}
export type Iron = PilotObject & {
	ClassName: "Iron",
}
export type Coupler = PilotObject & {
	Couple: Event<"Couple", () -> ()>,
	Configure: (self: Coupler, configuration: CouplerConfiguration) -> (),
	IsCoupled: (self: Coupler) -> (boolean),
	CouplerID: string,
	ClassName: "Coupler",
	AutoTrigger: boolean,
	Decouple: Event<"Decouple", () -> ()>,
	GetAttachedCoupler: (self: Coupler) -> (Coupler?),
}
export type Neutronium = PilotObject & {
	ClassName: "Neutronium",
}
export type Battery = PilotObject & {
	ContainerChanged: Event<"ContainerChanged", (resourceType: "Power" | "Solid" | "Fluid", resourceAmount: number) -> ()>,
	GetAmount: (self: Battery) -> (number),
	ClassName: "Battery",
	GetResourceAmount: (self: Battery) -> (number),
	GetResource: (self: Battery) -> (string | "nil"),
}
export type NitrogenOxide = PilotObject & {
	ClassName: "NitrogenOxide",
}
export type Turbofan = PilotObject & {
	TurboFanSpeed: number,
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	Configure: (self: Turbofan, configuration: TurbofanConfiguration) -> (),
	ClassName: "Turbofan",
}
export type Obamium = PilotObject & {
	ClassName: "Obamium",
}
export type TractorBeam = PilotObject & {
	PowerPercent: number,
	Configure: (self: TractorBeam, configuration: TractorBeamConfiguration) -> (),
	ClassName: "TractorBeam",
}
export type Perfectium = PilotObject & {
	ClassName: "Perfectium",
}
export type StarMap = PilotObject & {
	GetBodies: (self: StarMap) -> ({
		[string]: {
			PlanetType: PlanetType,
		},
	}),
	GetSystems: (self: StarMap) -> ({ string }),
	ClassName: "StarMap",
}
export type Ice = PilotObject & {
	ClassName: "Ice",
}
export type ObjectDetector = PilotObject & {
	MaxDistance: number,
	ClassName: "ObjectDetector",
	TriggerAtDistance: Vector2,
	Configure: (self: ObjectDetector, configuration: ObjectDetectorConfiguration) -> (),
	GetLastHitPart: (self: ObjectDetector) -> (PilotObject),
	GetLastHitData: (self: ObjectDetector) -> (ObjectDetectorHitData),
}
export type Generator = PilotObject & {
	ClassName: "Generator",
}
export type Explosive = PilotObject & {
	Triggered: Event<"Triggered", (otherPart: PilotObject) -> ()>,
	Damaged: Event<"Damaged", (damage: number, damageType: "Kinetic" | "Energy", damageSource: PilotObject?) -> ()>,
	ClassName: "Explosive",
}
export type Router = PilotObject & {
	RouterID: string,
	Configure: (self: Router, configuration: RouterConfiguration) -> (),
	ClassName: "Router",
}
export type CrossBow = PilotObject & {
	ClassName: "CrossBow",
}
export type Ruby = PilotObject & {
	ClassName: "Ruby",
}
export type Sand = PilotObject & {
	ClassName: "Sand",
}
export type Claymore = PilotObject & {
	ClassName: "Claymore",
}
export type Petroleum = PilotObject & {
	ClassName: "Petroleum",
}
export type BallastTank = PilotObject & {
	ClassName: "BallastTank",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	Configure: (self: BallastTank, configuration: BallastTankConfiguration) -> (),
	Buoyancy: number,
}
export type Snow = PilotObject & {
	ClassName: "Snow",
}
export type Stanlium = PilotObject & {
	ClassName: "Stanlium",
}
export type IonRocket = PilotObject & {
	ClassName: "IonRocket",
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	Configure: (self: IonRocket, configuration: IonRocketConfiguration) -> (),
	Propulsion: number,
}
export type Steam = PilotObject & {
	ClassName: "Steam",
}
export type TintedGlass = PilotObject & {
	ClassName: "TintedGlass",
}
export type Stone = PilotObject & {
	ClassName: "Stone",
}
export type Sulfur = PilotObject & {
	ClassName: "Sulfur",
}
export type MiningLaser = PilotObject & {
	Configure: (self: MiningLaser, configuration: MiningLaserConfiguration) -> (),
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	MaterialToExtract: string,
	ClassName: "MiningLaser",
}
export type Chute = PilotObject & {
	ClassName: "Chute",
}
export type RepairPlate = PilotObject & {
	ClassName: "RepairPlate",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type AdminTool = PilotObject & {
	ClassName: "AdminTool",
}
export type FireWood = PilotObject & {
	ClassName: "FireWood",
}
export type Radar = PilotObject & {
	ClassName: "Radar",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type ImpactPlate = PilotObject & {
	ClassName: "ImpactPlate",
}
export type Engine = PilotObject & {
	Configure: (self: Engine, configuration: EngineConfiguration) -> (),
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	EngineSpeed: number,
	ClassName: "Engine",
}
export type StanSword = PilotObject & {
	ClassName: "StanSword",
}
export type TemperatureSensor = PilotObject & {
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	GetTemp: (self: TemperatureSensor) -> (number),
	ClassName: "TemperatureSensor",
	Configure: (self: TemperatureSensor, configuration: TemperatureSensorConfiguration) -> (),
	TemperatureRange: Range,
}
export type Modem = PilotObject & {
	GetAsync: (self: Modem, url: string, nocache: boolean?, headers: {
		[string]: any,
	}?) -> (string),
	Configure: (self: Modem, configuration: ModemConfiguration) -> (),
	PostAsync: (self: Modem, url: string, data: string, contentType: Enum.HttpContentType?, compress: boolean?, headers: {
		[string]: any,
	}?) -> (string),
	SendLocalMessage: (self: Modem, data: any, id: string?) -> (),
	PostRequest: (self: Modem, domain: string, data: string) -> (),
	UrlEncode: (self: Modem, input: string) -> (string),
	GetRequest: (self: Modem, domain: string) -> (string),
	RealPostRequest: (self: Modem, domain: string, data: string, asyncBool: boolean, transformFunction: (...any) -> (), optionalHeaders: {
		[string]: any,
	}?) -> ({
		success: boolean,
		response: string,
	}),
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	ClassName: "Modem",
	NetworkID: string,
	SendMessage: (self: Modem, data: JSON, id: string?) -> (),
	RequestAsync: (self: Modem, options: ModemRequest) -> (ModemRequestResponse),
	MessageSent: Event<"MessageSent", (data: any) -> ()>,
}
export type SubspaceTripmine = PilotObject & {
	ClassName: "SubspaceTripmine",
}
export type Gasoline = PilotObject & {
	ClassName: "Gasoline",
}
export type Camera = PilotObject & {
	VideoID: number,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	Configure: (self: Camera, configuration: CameraConfiguration) -> (),
	ClassName: "Camera",
}
export type HeatCell = PilotObject & {
	ContainerChanged: Event<"ContainerChanged", (resourceType: "Power" | "Solid" | "Fluid", resourceAmount: number) -> ()>,
	GetAmount: (self: HeatCell) -> (number),
	ClassName: "HeatCell",
	GetResourceAmount: (self: HeatCell) -> (number),
	GetResource: (self: HeatCell) -> (string | "nil"),
}
export type GeigerCounter = PilotObject & {
	ClassName: "GeigerCounter",
}
export type CombustionTurbine = PilotObject & {
	ClassName: "CombustionTurbine",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type Billboardium = PilotObject & {
	ClassName: "Billboardium",
}
export type Thruster = PilotObject & {
	ClassName: "Thruster",
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	Configure: (self: Thruster, configuration: ThrusterConfiguration) -> (),
	Propulsion: number,
}
export type NightVisionGoggles = PilotObject & {
	ClassName: "NightVisionGoggles",
}
export type Faucet = PilotObject & {
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	Filter: string,
	ClassName: "Faucet",
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	Configure: (self: Faucet, configuration: FaucetConfiguration) -> (),
	Dispense: (self: Faucet) -> (),
}
export type AutomaticLaser = PilotObject & {
	ClassName: "AutomaticLaser",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type EthernetCable = PilotObject & {
	ClassName: "EthernetCable",
}
export type Pipe = PilotObject & {
	ClassName: "Pipe",
}
export type Tetrahedron = PilotObject & {
	ClassName: "Tetrahedron",
}
export type CornerRoundWedge2 = PilotObject & {
	ClassName: "CornerRoundWedge2",
}
export type DevSource = PilotObject & {
	Configure: (self: DevSource, configuration: DevSourceConfiguration) -> (),
	GetAmountGenerated: (self: DevSource, ...any) -> (...any),
	ClassName: "DevSource",
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	OnClick: Event<"OnClick", (clickerId: number) -> ()>,
	Resource: ResourceString,
}
export type Cannon = PilotObject & {
	ClassName: "Cannon",
}
export type Furnace = PilotObject & {
	ClassName: "Furnace",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type Gear = PilotObject & {
	ClassName: "Gear",
}
export type CornerTetra = PilotObject & {
	ClassName: "CornerTetra",
}
export type Scanner = PilotObject & {
	CalculateCost: (self: Scanner, range: number?) -> (number),
	Locate: (self: Scanner, part: PilotObject, scanners: { Scanner }) -> (Vector3),
	GetPartsInRange: (self: Scanner, range: number?, className: string?) -> ({ PilotObject }),
	ClassName: "Scanner",
	GetDistance: (self: Scanner, part: PilotObject) -> (number),
	Range: number,
	Configure: (self: Scanner, configuration: ScannerConfiguration) -> (),
}
export type Polysilicon = PilotObject & {
	Configure: (self: Polysilicon, configuration: PolysiliconConfiguration) -> (),
	ClassName: "Polysilicon",
	PolysiliconMode: PolysiliconMode,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	Frequency: number,
}
export type RepairLaser = PilotObject & {
	ClassName: "RepairLaser",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type Rail = PilotObject & {
	SetPosition: (self: Rail, depth: number) -> (),
	Configure: (self: Rail, configuration: RailConfiguration) -> (),
	ClassName: "Rail",
	Position1: number,
	TweenTime: number,
	Position2: number,
}
export type Sail = PilotObject & {
	ClassName: "Sail",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type Extinguisher = PilotObject & {
	ClassName: "Extinguisher",
}
export type DarkReactor = PilotObject & {
	ClassName: "DarkReactor",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type BeamRifle = PilotObject & {
	ClassName: "BeamRifle",
}
export type VitalScanner = PilotObject & {
	ClassName: "VitalScanner",
}
export type Balloon = PilotObject & {
	ClassName: "Balloon",
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	Configure: (self: Balloon, configuration: BalloonConfiguration) -> (),
	Buoyancy: number,
}
export type Light = PilotObject & {
	Shadows: boolean,
	Configure: (self: Light, configuration: LightConfiguration) -> (),
	ClassName: "Light",
	Brightness: number,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	LightRange: number,
	SetColor: (self: Light, color: Color3) -> (),
}
export type Flamethrower = PilotObject & {
	ClassName: "Flamethrower",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type RemoteControl = PilotObject & {
	ClassName: "RemoteControl",
	Configure: (self: RemoteControl, configuration: RemoteControlConfiguration) -> (),
	RemoteControlMode: RemoteControlMode,
	RemoteControlRange: number,
}
export type TemperatureGate = PilotObject & {
	Configure: (self: TemperatureGate, configuration: TemperatureGateConfiguration) -> (),
	Inverted: boolean,
	GetState: (self: TemperatureGate) -> (),
	ClassName: "TemperatureGate",
	GetTemp: (self: TemperatureGate) -> (number),
	SwitchValue: boolean,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	TemperatureRange: Range,
	GetTemperature: (self: TemperatureGate) -> (number),
}
export type Scrapper = PilotObject & {
	ClassName: "Scrapper",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type Rocket = PilotObject & {
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	ClassName: "Rocket",
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	Configure: (self: Rocket, configuration: RocketConfiguration) -> (),
	Propulsion: number,
}
export type SpawnPoint = PilotObject & {
	ClassName: "SpawnPoint",
}
export type Electromagnet = PilotObject & {
	ClassName: "Electromagnet",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type DeleteSwitch = PilotObject & {
	Triggered: Event<"Triggered", (otherPart: PilotObject) -> ()>,
	ClassName: "DeleteSwitch",
}
export type FactionSpawn = PilotObject & {
	ClassName: "FactionSpawn",
}
export type Igniter = PilotObject & {
	Triggered: Event<"Triggered", (otherPart: PilotObject) -> ()>,
	ClassName: "Igniter",
}
export type RepairKit = PilotObject & {
	ClassName: "RepairKit",
}
export type Boombox = PilotObject & {
	Configure: (self: Boombox, configuration: BoomboxConfiguration) -> (),
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	Audio: number,
	ClassName: "Boombox",
}
export type SolarPanel = PilotObject & {
	ClassName: "SolarPanel",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type TriggerSwitch = PilotObject & {
	Configure: (self: TriggerSwitch, configuration: TriggerSwitchConfiguration) -> (),
	ClassName: "TriggerSwitch",
	SwitchValue: boolean,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	OnClick: Event<"OnClick", (clickerId: number) -> ()>,
}
export type Tile = PilotObject & {
	ClassName: "Tile",
}
export type HyperDrive = PilotObject & {
	GetRequiredPower: (self: HyperDrive) -> (),
	Coordinates: Coordinates,
	ClassName: "HyperDrive",
	Triggered: Event<"Triggered", (otherPart: PilotObject) -> ()>,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	Configure: (self: HyperDrive, configuration: HyperDriveConfiguration) -> (),
}
export type DevSink = PilotObject & {
	ContainerChanged: Event<"ContainerChanged", (resourceType: "Power" | "Solid" | "Fluid", resourceAmount: number) -> ()>,
	Configure: (self: DevSink, configuration: DevSinkConfiguration) -> (),
	GetAmount: (self: DevSink) -> (number),
	GetResourceAmount: (self: DevSink) -> (number),
	Resource: ResourceString,
	ClassName: "DevSink",
	GetAmountConsumed: (self: DevSink, ...any) -> (...any),
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	OnClick: Event<"OnClick", (clickerId: number) -> ()>,
	GetResource: (self: DevSink) -> (string | "nil"),
}
export type Solenoid = PilotObject & {
	Configure: (self: Solenoid, configuration: SolenoidConfiguration) -> (),
	PowerRange: Range,
	Inverted: boolean,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	OnClick: Event<"OnClick", (clickerId: number) -> ()>,
	ClassName: "Solenoid",
}
export type Decoupler = PilotObject & {
	Triggered: Event<"Triggered", (otherPart: PilotObject) -> ()>,
	ClassName: "Decoupler",
}
export type RoundWedge2 = PilotObject & {
	ClassName: "RoundWedge2",
}
export type Prosthetic = PilotObject & {
	Limb: PlayerLimb,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	Configure: (self: Prosthetic, configuration: ProstheticConfiguration) -> (),
	ClassName: "Prosthetic",
}
export type Reactor = PilotObject & {
	ClassName: "Reactor",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	GetFuel: (self: Reactor) -> ({ number }),
	GetTemp: (self: Reactor) -> (number),
	GetEfficiency: (self: Reactor) -> (number),
	Configure: (self: Reactor, configuration: ReactorConfiguration) -> (),
	TriggerWhenEmpty: boolean,
	Alarm: boolean,
}
export type BlackBox = PilotObject & {
	GetLogs: (self: BlackBox) -> ({ RegionLog }),
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	OnClick: Event<"OnClick", (clickerId: number) -> ()>,
	ClassName: "BlackBox",
}
export type Telescope = PilotObject & {
	WhenRegionLoads: (self: Telescope, callback: (regionInfo: CompleteRegionInfo) -> ()) -> (),
	Configure: (self: Telescope, configuration: TelescopeConfiguration) -> (),
	GetCurrentCoordinate: (self: Telescope) -> (Coordinates),
	ClassName: "Telescope",
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	GetCoordinate: (self: Telescope) -> (RegionInfo),
	ViewCoordinates: Coordinates,
}
export type Aluminum = PilotObject & {
	ClassName: "Aluminum",
}
export type Motor = PilotObject & {
	Configure: (self: Motor, configuration: MotorConfiguration) -> (),
	Power: number,
	Ratio: number,
	ClassName: "Motor",
	Configured: Event<"Configured", (configurerId: number) -> ()>,
}
export type Obelisk = PilotObject & {
	ClassName: "Obelisk",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type Controller = PilotObject & {
	Triggered: Event<"Triggered", (otherPart: PilotObject) -> ()>,
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	ClassName: "Controller",
}
export type Rotor = PilotObject & {
	ClassName: "Rotor",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type RTG = PilotObject & {
	ClassName: "RTG",
}
export type Insulation = PilotObject & {
	ClassName: "Insulation",
}
export type Winch = PilotObject & {
	Configure: (self: Winch, configuration: WinchConfiguration) -> (),
	ClassName: "Winch",
	AdjustLength: (self: Winch, adjustment: number) -> (),
	DeltaLength: number,
	SetLength: (self: Winch, length: number) -> (),
	MaxLength: number,
	MinLength: number,
}
export type RoundWedge = PilotObject & {
	ClassName: "RoundWedge",
}
export type VehicleSeat = PilotObject & {
	Enabled: boolean,
	Configure: (self: VehicleSeat, configuration: VehicleSeatConfiguration) -> (),
	OccupantChanged: Event<"OccupantChanged", (newOccupant: number?) -> ()>,
	GetOccupant: (self: VehicleSeat) -> (number?),
	ClassName: "VehicleSeat",
	EjectOccupant: (self: VehicleSeat) -> (),
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	Mode: VehicleSeatMode,
	Speed: number,
}
export type Hull = PilotObject & {
	ComponentsUpdated: Event<"ComponentsUpdated", (...any) -> ()>,
	ClassName: "Hull",
}
export type SoundMuffler = PilotObject & {
	ClassName: "SoundMuffler",
}
export type Magnesium = PilotObject & {
	ClassName: "Magnesium",
}
export type Cloth = PilotObject & {
	ClassName: "Cloth",
}
export type Speaker = PilotObject & {
	Pitch: number,
	ClearSounds: (self: Speaker) -> (),
	Audio: string,
	LoadSound: (self: Speaker, soundId: string) -> (Sound),
	Chat: (self: Speaker, message: string) -> (),
	ClassName: "Speaker",
	Volume: number,
	Triggered: Event<"Triggered", (otherPart: PilotObject) -> ()>,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	Configure: (self: Speaker, configuration: SpeakerConfiguration) -> (),
	PlaySound: (self: Speaker, soundId: string?) -> (),
}
export type HeatPump = PilotObject & {
	Configure: (self: HeatPump, configuration: HeatPumpConfiguration) -> (),
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	TransferRate: number,
	ClassName: "HeatPump",
}
export type Plutonium = PilotObject & {
	ClassName: "Plutonium",
}
export type Microcontroller = PilotObject & {
	Receive: (self: Microcontroller) -> (Microcontroller, ...any),
	Configure: (self: Microcontroller, configuration: MicrocontrollerConfiguration) -> (),
	Code: string,
	StartOnSpawn: boolean,
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	Shutdown: (self: Microcontroller) -> (),
	ClassName: "Microcontroller",
	OnClick: Event<"OnClick", (clickerId: number) -> ()>,
	Send: (self: Microcontroller, ...any) -> (),
}
export type SteamEngine = PilotObject & {
	Configure: (self: SteamEngine, configuration: SteamEngineConfiguration) -> (),
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	EngineSpeed: number,
	ClassName: "SteamEngine",
}
export type Quartz = PilotObject & {
	ClassName: "Quartz",
}
export type CrudeWing = PilotObject & {
	ClassName: "CrudeWing",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type Marble = PilotObject & {
	ClassName: "Marble",
}
export type Treads = PilotObject & {
	ClassName: "Treads",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type Piston = PilotObject & {
	SetPosition: (self: Piston) -> (),
	Configure: (self: Piston, configuration: PistonConfiguration) -> (),
	ClassName: "Piston",
	Speed: number,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	Position1: number,
	Position2: number,
}
export type Transistor = PilotObject & {
	Configure: (self: Transistor, configuration: TransistorConfiguration) -> (),
	Inverted: boolean,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	OnClick: Event<"OnClick", (clickerId: number) -> ()>,
	ClassName: "Transistor",
}
export type PowerCell = PilotObject & {
	ContainerChanged: Event<"ContainerChanged", (resourceType: "Power" | "Solid" | "Fluid", resourceAmount: number) -> ()>,
	GetAmount: (self: PowerCell) -> (number),
	ClassName: "PowerCell",
	GetResourceAmount: (self: PowerCell) -> (number),
	GetResource: (self: PowerCell) -> (string | "nil"),
}
export type TriggerRelay = PilotObject & {
	Configure: (self: TriggerRelay, configuration: TriggerRelayConfiguration) -> (),
	ClassName: "TriggerRelay",
	SwitchValue: boolean,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	OnClick: Event<"OnClick", (clickerId: number) -> ()>,
}
export type FactionHub = PilotObject & {
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	OnClick: Event<"OnClick", (clickerId: number) -> ()>,
	ClassName: "FactionHub",
}
export type Pistol = PilotObject & {
	ClassName: "Pistol",
}
export type Cleat = PilotObject & {
	ClassName: "Cleat",
}
export type Fireworks = PilotObject & {
	Triggered: Event<"Triggered", (otherPart: PilotObject) -> ()>,
	Damaged: Event<"Damaged", (damage: number, damageType: "Kinetic" | "Energy", damageSource: PilotObject?) -> ()>,
	ClassName: "Fireworks",
}
export type Transformer = PilotObject & {
	Configure: (self: Transformer, configuration: TransformerConfiguration) -> (),
	ClassName: "Transformer",
	Triggered: Event<"Triggered", (otherPart: PilotObject) -> ()>,
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	LoopTime: number,
}
export type AdBoard = PilotObject & {
	ClassName: "AdBoard",
}
export type Warhead = PilotObject & {
	Triggered: Event<"Triggered", (otherPart: PilotObject) -> ()>,
	Damaged: Event<"Damaged", (damage: number, damageType: "Kinetic" | "Energy", damageSource: PilotObject?) -> ()>,
	ClassName: "Warhead",
}
export type Brick = PilotObject & {
	ClassName: "Brick",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type Component = PilotObject & {
	ComponentsUpdated: Event<"ComponentsUpdated", (...any) -> ()>,
	ClassName: "Component",
}
export type SteamTurbine = PilotObject & {
	GetEfficiency: (self: SteamTurbine) -> (number),
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	GetProductionRate: (self: SteamTurbine) -> (number),
	ClassName: "SteamTurbine",
}
export type LifeSensor = PilotObject & {
	ClassName: "LifeSensor",
	GetReading: (self: LifeSensor) -> ({
		[string]: Vector3,
	}),
	ListPlayers: (self: LifeSensor) -> ({ number }),
	GetPlayers: (self: LifeSensor) -> ({
		[number]: CFrame,
	}),
}
export type LightTube = PilotObject & {
	ClassName: "LightTube",
	SetColor: (self: LightTube, color: Color3) -> (),
}
export type Disk = PilotObject & {
	Clear: (self: Disk) -> (),
	Write: (self: Disk, key: any, value: any) -> (),
	Compress: (self: Disk) -> (),
	ReadAll: (self: Disk) -> ({
		[any]: any,
	}),
	WriteAll: (self: Disk, content: {
		[any]: any,
	}) -> (),
	Read: (self: Disk, key: any) -> (any),
	Decompress: (self: Disk) -> (),
	ClassName: "Disk",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	ReadEntireDisk: (self: Disk) -> ({
		[any]: any,
	}),
	ClearDisk: (self: Disk) -> (),
}
export type DarkConverter = PilotObject & {
	ClassName: "DarkConverter",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type WirelessButton = PilotObject & {
	OnClick: Event<"OnClick", (clickerId: number) -> ()>,
	ClassName: "WirelessButton",
}
export type Block = PilotObject & {
	ClassName: "Block",
}
export type ProximityButton = PilotObject & {
	PromptTriggered: Event<"PromptTriggered", () -> ()>,
	GamepadKeyCode: string,
	HoldDuration: number,
	MaxActivationDistance: number,
	ObjectText: string,
	PromptButtonHoldBegan: Event<"PromptButtonHoldBegan", () -> ()>,
	PromptButtonHoldEnded: Event<"PromptButtonHoldEnded", () -> ()>,
	Configure: (self: ProximityButton, configuration: ProximityButtonConfiguration) -> (),
	ClassName: "ProximityButton",
	KeyboardKeyCode: string,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	PromptTriggerEnded: Event<"PromptTriggerEnded", () -> ()>,
	RequiresLineOfSight: boolean,
}
export type Ball = PilotObject & {
	ClassName: "Ball",
}
export type LightBridge = PilotObject & {
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	ClassName: "LightBridge",
	BeamColor: Color3,
	Configure: (self: LightBridge, configuration: LightBridgeConfiguration) -> (),
	Configured: Event<"Configured", (configurerId: number) -> ()>,
}
export type EnergyGun = PilotObject & {
	ClassName: "EnergyGun",
}
export type StasisField = PilotObject & {
	ClassName: "StasisField",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type Cement = PilotObject & {
	ClassName: "Cement",
}
export type Keyboard = PilotObject & {
	TextInputted: Event<"TextInputted", (text: string, player: string) -> ()>,
	ClassName: "Keyboard",
	UserInput: Event<"UserInput", (inputObject: UserInputObject, userId: number) -> ()>,
	SimulateUserInput: (self: Keyboard) -> (),
	SimulateKeyPress: (self: Keyboard, key: string?, player: string) -> (),
	SimulateTextInput: (self: Keyboard, input: string?, player: string) -> (),
	KeyPressed: Event<"KeyPressed", (key: Enum.KeyCode, keyName: string, userId: number) -> ()>,
}
export type Neon = PilotObject & {
	ClassName: "Neon",
}
export type Diode = PilotObject & {
	ClassName: "Diode",
}
export type Assembler = PilotObject & {
	CalculateCraftingRecipe: (self: Assembler, items: { string } | {
		[string]: number,
	}) -> ({
		Power: number,
		[string]: number,
	}),
	Configure: (self: Assembler, configuration: AssemblerConfiguration) -> (),
	CraftItems: (self: Assembler, items: { string } | {
		[string]: number,
	}) -> (),
	Craft: (self: Assembler, itemName: string) -> (boolean),
	GetCraftCooldown: (self: Assembler) -> (number),
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	GetRecipe: (self: Assembler, itemName: string) -> ({
		[string]: number,
	}),
	ClassName: "Assembler",
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	GetInventory: (self: Assembler) -> ({
		[string]: number,
	}),
	Assemble: string,
}
export type Torch = PilotObject & {
	ClassName: "Torch",
}
export type Pump = PilotObject & {
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	ClassName: "Pump",
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	Configure: (self: Pump, configuration: PumpConfiguration) -> (),
	LiquidToPump: string,
}
export type ElectricFence = PilotObject & {
	ClassName: "ElectricFence",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type TimeSensor = PilotObject & {
	Configure: (self: TimeSensor, configuration: TimeSensorConfiguration) -> (),
	Time: string,
	ClassName: "TimeSensor",
}
export type MonsterMashPotion = PilotObject & {
	ClassName: "MonsterMashPotion",
}
export type ScubaMask = PilotObject & {
	ClassName: "ScubaMask",
}
export type FluidProjector = PilotObject & {
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	ClassName: "FluidProjector",
	Fluid: string,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	Configure: (self: FluidProjector, configuration: FluidProjectorConfiguration) -> (),
	Size: Vector3,
}
export type DriveBox = PilotObject & {
	Configure: (self: DriveBox, configuration: DriveBoxConfiguration) -> (),
	ClassName: "DriveBox",
	Reversal: boolean,
	Ratio: number,
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type Servo = PilotObject & {
	SetAngle: (self: Servo, angle: number) -> (),
	Configure: (self: Servo, configuration: ServoConfiguration) -> (),
	ServoSpeed: number,
	ClassName: "Servo",
	Responsiveness: number,
	Angle: number,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	AngleStep: number,
}
export type Fence = PilotObject & {
	ClassName: "Fence",
}
export type DevGravityGenerator = PilotObject & {
	Enabled: boolean,
	Radius: number,
	ClassName: "DevGravityGenerator",
	Gravity: number,
	Configure: (self: DevGravityGenerator, configuration: DevGravityGeneratorConfiguration) -> (),
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type TestStarMap = PilotObject & {
	ClassName: "TestStarMap",
}
export type BurnerGenerator = PilotObject & {
	ClassName: "BurnerGenerator",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type ReinforcedGlass = PilotObject & {
	ClassName: "ReinforcedGlass",
}
export type Cone = PilotObject & {
	ClassName: "Cone",
}
export type WaterCooler = PilotObject & {
	ClassName: "WaterCooler",
}
export type DevHeatStorage = PilotObject & {
	ContainerChanged: Event<"ContainerChanged", (resourceType: "Power" | "Solid" | "Fluid", resourceAmount: number) -> ()>,
	GetAmount: (self: DevHeatStorage) -> (number),
	ClassName: "DevHeatStorage",
	GetResourceAmount: (self: DevHeatStorage) -> (number),
	GetResource: (self: DevHeatStorage) -> (string | "nil"),
}
export type Laser = PilotObject & {
	ClassName: "Laser",
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	Configure: (self: Laser, configuration: LaserConfiguration) -> (),
	DamageOnlyPlayers: boolean,
}
export type Stick = PilotObject & {
	ClassName: "Stick",
}
export type Water = PilotObject & {
	ClassName: "Water",
}
export type Teleporter = PilotObject & {
	TeleporterID: number,
	ForceLocalTeleport: boolean,
	Triggered: Event<"Triggered", (otherPart: PilotObject) -> ()>,
	ClassName: "Teleporter",
	Configure: (self: Teleporter, configuration: TeleporterConfiguration) -> (),
	Coordinates: Coordinates,
}
export type ARController = PilotObject & {
	ClearElements: (self: ARController, context: CanvasContext) -> (),
	CreateElement3D: (self: ARController, shape: "Ball" | "Block" | "Cylinder" | "Wedge" | "CornerWedge", properties: {
		[string]: any,
	}) -> (Part),
	CreateElement: (self: ARController, className: string, properties: {
		[string]: any,
	}, context: CanvasContext) -> (Instance),
	OnClick: Event<"OnClick", (clickerId: number) -> ()>,
	CursorReleased: Event<"CursorReleased", (cursor: ARCursor) -> ()>,
	Configure: (self: ARController, configuration: ARControllerConfiguration) -> (),
	CursorMoved: Event<"CursorMoved", (cursor: ARCursor) -> ()>,
	GetCursor: (self: ARController) -> (ARCursor),
	KeyPressed: Event<"KeyPressed", (key: Enum.KeyCode, keyName: string, userId: number) -> ()>,
	GetCanvas: ((self: ARController, context: "2D"?) -> (Folder)) & ((self: ARController, context: "3D") -> (WorldModel)),
	Transparency: number,
	GetCursors: (self: ARController) -> ({
		[number]: ARCursor,
	}),
	ClearElements3D: (self: ARController) -> (),
	ClassName: "ARController",
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	UserInput: Event<"UserInput", (inputObject: UserInputObject, userId: number) -> ()>,
	CursorPressed: Event<"CursorPressed", (cursor: ARCursor) -> ()>,
}
export type ARGlasses = Tool & Router & Antenna & Microcontroller & ARController & {
	ClassName: "ARGlasses",
}
export type Instrument = PilotObject & {
	Type: InstrumentType,
	ClassName: "Instrument",
	GetReading: (self: Instrument, type: (InstrumentType | number)?) -> (number | Vector3 | string),
	Configure: (self: Instrument, configuration: InstrumentConfiguration) -> (),
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
}
export type Antenna = PilotObject & {
	AntennaID: string,
	Configure: (self: Antenna, configuration: AntennaConfiguration) -> (),
	ClassName: "Antenna",
}
export type Filter = PilotObject & {
	ClassName: "Filter",
	Configure: (self: Filter, configuration: FilterConfiguration) -> (),
	Invert: boolean,
	Filter: string,
}
export type HeatPipe = PilotObject & {
	ClassName: "HeatPipe",
}
export type BlastingCap = PilotObject & {
	ClassName: "BlastingCap",
}
export type Lead = PilotObject & {
	ClassName: "Lead",
}
export type Food = PilotObject & {
	OnClick: Event<"OnClick", (clickerId: number) -> ()>,
	ClassName: "Food",
}
export type CloningBay = PilotObject & {
	Configure: (self: CloningBay, configuration: CloningBayConfiguration) -> (),
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	Name: string,
	ClassName: "CloningBay",
}
export type Cooler = PilotObject & {
	ClassName: "Cooler",
}
export type Apparel = PilotObject & {
	Transparency: number,
	ClassName: "Apparel",
	Limb: PlayerLimb,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	OnClick: Event<"OnClick", (clickerId: number) -> ()>,
	Configure: (self: Apparel, configuration: ApparelConfiguration) -> (),
}
export type BurstLaser = PilotObject & {
	ClassName: "BurstLaser",
}
export type DevGenerator = PilotObject & {
	ClassName: "DevGenerator",
}
export type Extractor = PilotObject & {
	Configure: (self: Extractor, configuration: ExtractorConfiguration) -> (),
	Loop: Event<"Loop", (tickInterval: number) -> ()>,
	MaterialToExtract: string,
	ClassName: "Extractor",
}
export type Screen = PilotObject & {
	GetCanvas: (self: Screen) -> (Frame),
	VideoID: number,
	CreateElement: (self: Screen, className: string, properties: {
		[string]: any,
	}) -> (Instance),
	ClassName: "Screen",
	ClearElements: (self: Screen) -> (),
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	Configure: (self: Screen, configuration: ScreenConfiguration) -> (),
	GetDimensions: (self: Screen) -> (Vector2),
}
export type Hatch = PilotObject & {
	Configure: (self: Hatch, configuration: HatchConfiguration) -> (),
	ClassName: "Hatch",
	SwitchValue: boolean,
	Configured: Event<"Configured", (configurerId: number) -> ()>,
	OnClick: Event<"OnClick", (clickerId: number) -> ()>,
}
export type DelayWire = PilotObject & {
	Configure: (self: DelayWire, configuration: DelayWireConfiguration) -> (),
	ClassName: "DelayWire",
	DelayTime: number,
}
export type Wood = PilotObject & {
	ClassName: "Wood",
}
export type HyperspaceRadarConfiguration = {
	[string]: any,
	ViewCoordinates: Coordinates?,
}
export type HeatPumpConfiguration = {
	TransferRate: number?,
	[string]: any,
}
export type TriggerRelayConfiguration = {
	SwitchValue: boolean?,
	[string]: any,
}
export type LightConfiguration = {
	Shadows: boolean?,
	Brightness: number?,
	LightRange: number?,
	[string]: any,
}
export type PortConfiguration = {
	[string]: any,
	PortID: number?,
}
export type SolenoidConfiguration = {
	[string]: any,
	PowerRange: Range?,
	Inverted: boolean?,
}
export type BallastTankConfiguration = {
	Buoyancy: number?,
	[string]: any,
}
export type ValveConfiguration = {
	[string]: any,
	SwitchValue: boolean?,
}
export type TemperatureGateConfiguration = {
	SwitchValue: boolean?,
	TemperatureRange: Range?,
	Inverted: boolean?,
	[string]: any,
}
export type HandleConfiguration = {
	[string]: any,
	Swing: HandleSwingMode?,
	TriggerMode: HandleTriggerMode?,
	ToolName: string?,
}
export type ExtractorConfiguration = {
	MaterialToExtract: string?,
	[string]: any,
}
export type MotorConfiguration = {
	Ratio: number?,
	[string]: any,
	Power: number?,
}
export type TriggerSwitchConfiguration = {
	[string]: any,
	SwitchValue: boolean?,
}
export type DevTeleporterConfiguration = {
	[string]: any,
	TeleporterID: string?,
}
export type PumpConfiguration = {
	LiquidToPump: string?,
	[string]: any,
}
export type PolysiliconConfiguration = {
	[string]: any,
	PolysiliconMode: PolysiliconMode?,
	Frequency: number?,
}
export type ObjectDetectorConfiguration = {
	TriggerAtDistance: Vector2?,
	MaxDistance: number?,
	[string]: any,
}
export type DevSourceConfiguration = {
	[string]: any,
	Resource: ResourceString?,
}
export type DevSinkConfiguration = {
	[string]: any,
	Resource: ResourceString?,
}
export type CameraConfiguration = {
	[string]: any,
	VideoID: number?,
}
export type BalloonConfiguration = {
	[string]: any,
	Buoyancy: number?,
}
export type ThrusterConfiguration = {
	Propulsion: number?,
	[string]: any,
}
export type TransformerConfiguration = {
	LoopTime: number?,
	[string]: any,
}
export type BinConfiguration = {
	[string]: any,
	Resource: string?,
	CanBeCraftedFrom: boolean?,
}
export type LightBridgeConfiguration = {
	[string]: any,
	BeamColor: Color3?,
}
export type FaucetConfiguration = {
	Filter: string?,
	[string]: any,
}
export type TransistorConfiguration = {
	Inverted: boolean?,
	[string]: any,
}
export type CloningBayConfiguration = {
	[string]: any,
	Name: string?,
}
export type TeleporterConfiguration = {
	Coordinates: Coordinates?,
	[string]: any,
	TeleporterID: number?,
	ForceLocalTeleport: boolean?,
}
export type TelescopeConfiguration = {
	ViewCoordinates: Coordinates?,
	[string]: any,
}
export type ProstheticConfiguration = {
	Limb: PlayerLimb?,
	[string]: any,
}
export type HydroponicConfiguration = {
	Grow: string?,
	[string]: any,
}
export type ServoConfiguration = {
	[string]: any,
	ServoSpeed: number?,
	Responsiveness: number?,
	Angle: number?,
	AngleStep: number?,
}
export type TurbofanConfiguration = {
	TurboFanSpeed: number?,
	[string]: any,
}
export type VehicleSeatConfiguration = {
	Speed: number?,
	[string]: any,
	Enabled: boolean?,
	Mode: VehicleSeatMode?,
}
export type ConveyorBeltConfiguration = {
	[string]: any,
	ConveyorBeltSpeed: number?,
}
export type EnergyShieldConfiguration = {
	ShieldRadius: number?,
	ShieldStrength: number?,
	[string]: any,
	RegenerationSpeed: number?,
}
export type CouplerConfiguration = {
	[string]: any,
	CouplerID: string?,
	AutoTrigger: boolean?,
}
export type InstrumentConfiguration = {
	Type: InstrumentType?,
	[string]: any,
}
export type FilterConfiguration = {
	Filter: string?,
	Invert: boolean?,
	[string]: any,
}
export type ModemConfiguration = {
	NetworkID: string?,
	[string]: any,
}
export type HyperDriveConfiguration = {
	[string]: any,
	Coordinates: Coordinates?,
}
export type FluidProjectorConfiguration = {
	Fluid: string?,
	[string]: any,
	Size: Vector3?,
}
export type TemperatureSensorConfiguration = {
	TemperatureRange: Range?,
	[string]: any,
}
export type TankConfiguration = {
	CanBeCraftedFrom: boolean?,
	Resource: string?,
	[string]: any,
}
export type ConstructorConfiguration = {
	[string]: any,
	ModelCode: string?,
	Autolock: boolean?,
	RelativeToConstructor: boolean?,
}
export type WinchConfiguration = {
	DeltaLength: number?,
	MinLength: number?,
	MaxLength: number?,
	[string]: any,
}
export type TransporterConfiguration = {
	TransporterID: string?,
	[string]: any,
}
export type GravityGeneratorConfiguration = {
	Gravity: number?,
	[string]: any,
}
export type RelayConfiguration = {
	[string]: any,
	Mode: RelayMode?,
	LinkerID: number?,
}
export type HologramConfiguration = {
	[string]: any,
	UserId: number?,
}
export type SignConfiguration = {
	TextFont: string?,
	[string]: any,
	SignText: string?,
	TextColor: Color3?,
}
export type PistonConfiguration = {
	Position1: number?,
	Speed: number?,
	[string]: any,
	Position2: number?,
}
export type ReactorConfiguration = {
	Alarm: boolean?,
	[string]: any,
	TriggerWhenEmpty: boolean?,
}
export type ProximityButtonConfiguration = {
	KeyboardKeyCode: string?,
	GamepadKeyCode: string?,
	HoldDuration: number?,
	ObjectText: string?,
	RequiresLineOfSight: boolean?,
	[string]: any,
	MaxActivationDistance: number?,
}
export type GyroConfiguration = {
	[string]: any,
	DisableWhenUnpowered: boolean?,
	TriggerWhenSeeked: boolean?,
	Seek: string?,
	MaxTorque: number?,
}
export type AssemblerConfiguration = {
	Assemble: string?,
	[string]: any,
}
export type RemoteControlConfiguration = {
	[string]: any,
	RemoteControlRange: number?,
	RemoteControlMode: RemoteControlMode?,
}
export type SteamEngineConfiguration = {
	EngineSpeed: number?,
	[string]: any,
}
export type StorageSensorConfiguration = {
	[string]: any,
	QuantityRange: Range?,
}
export type HeatValveConfiguration = {
	[string]: any,
	SwitchValue: boolean?,
}
export type EngineConfiguration = {
	[string]: any,
	EngineSpeed: number?,
}
export type HatchConfiguration = {
	SwitchValue: boolean?,
	[string]: any,
}
export type DispenserConfiguration = {
	[string]: any,
	Filter: string?,
}
export type TractorBeamConfiguration = {
	PowerPercent: number?,
	[string]: any,
}
export type RouterConfiguration = {
	[string]: any,
	RouterID: string?,
}
export type ARControllerConfiguration = {
	Transparency: number?,
	[string]: any,
}
export type IonRocketConfiguration = {
	[string]: any,
	Propulsion: number?,
}
export type MicrocontrollerConfiguration = {
	StartOnSpawn: boolean?,
	[string]: any,
	Code: string?,
}
export type ScreenConfiguration = {
	[string]: any,
	VideoID: number?,
}
export type AnchorConfiguration = {
	Anchored: boolean?,
	[string]: any,
}
export type SwitchConfiguration = {
	SwitchValue: boolean?,
	[string]: any,
}
export type DevGravityGeneratorConfiguration = {
	Enabled: boolean?,
	Gravity: number?,
	[string]: any,
	Radius: number?,
}
export type BoomboxConfiguration = {
	[string]: any,
	Audio: number?,
}
export type DelayWireConfiguration = {
	[string]: any,
	DelayTime: number?,
}
export type DriveBoxConfiguration = {
	Reversal: boolean?,
	Ratio: number?,
	[string]: any,
}
export type BladeConfiguration = {
	[string]: any,
	Shape: BladeShape?,
}
export type BeaconConfiguration = {
	[string]: any,
	ShowOnMap: boolean?,
	BeaconName: string?,
}
export type AntennaConfiguration = {
	[string]: any,
	AntennaID: string?,
}
export type TimeSensorConfiguration = {
	Time: string?,
	[string]: any,
}
export type SpeakerConfiguration = {
	Pitch: number?,
	[string]: any,
	Audio: string?,
	Volume: number?,
}
export type RocketConfiguration = {
	[string]: any,
	Propulsion: number?,
}
export type ApparelConfiguration = {
	Limb: PlayerLimb?,
	Transparency: number?,
	[string]: any,
}
export type MiningLaserConfiguration = {
	[string]: any,
	MaterialToExtract: string?,
}
export type SorterConfiguration = {
	Rate: number?,
	Resource: string?,
	TriggerQuantity: number?,
	[string]: any,
}
export type RailConfiguration = {
	Position1: number?,
	Position2: number?,
	[string]: any,
	TweenTime: number?,
}
export type ScannerConfiguration = {
	[string]: any,
	Range: number?,
}
export type LaserConfiguration = {
	[string]: any,
	DamageOnlyPlayers: boolean?,
}
return setmetatable(
	{
		FileSystem = ( FileSystem :: any ) :: FileSystem,
		RawFileSystem = ( RawFileSystem :: any ) :: RawFileSystem,
		Microcontroller = ( Microcontroller :: any ) :: Microcontroller,
		SandboxRunID = ( SandboxRunID :: any ) :: string,
		SandboxID = ( SandboxID :: any ) :: string,
		Network = ( Network :: any ) :: Network,
		pilot = ( pilot :: any ) :: {
			setTimeout: (timeout: number?, thread: thread?) -> (),
			hasRing: (ring: number, thread: thread?) -> (boolean),
			setInterrupt: (period: number, callback: () -> ()) -> (() -> ()),
			getTimeout: (thread: thread?) -> (number),
			setRing: (ring: number, thread: thread?) -> (),
			claimThread: (thread: thread) -> (boolean),
			getCPUTime: () -> (number),
			getRing: (thread: thread?) -> (number),
			getThreadParent: (thread: thread?) -> (thread?),
			saveRing: (ring: number?) -> (() -> ()),
		},
		GetPorts = ( GetPorts :: any ) :: (id: number?) -> ({ Port }),
		GetPort = ( GetPort :: any ) :: (id: number?) -> (Port?),
		TriggerPort = ( TriggerPort :: any ) :: (port: PortLike) -> (),
		JSONEncode = ( JSONEncode :: any ) :: (data: JSON) -> (string),
		JSONDecode = ( JSONDecode :: any ) :: (data: string) -> (JSON),
		GetPartFromPort = ( GetPartFromPort :: any ) :: ((port: PortLike?, class: "DelayWire") -> (DelayWire?)) & ((port: PortLike?, class: "Hatch") -> (Hatch?)) & ((port: PortLike?, class: "Screen") -> (Screen?)) & ((port: PortLike?, class: "Extractor") -> (Extractor?)) & ((port: PortLike?, class: "Apparel") -> (Apparel?)) & ((port: PortLike?, class: "CloningBay") -> (CloningBay?)) & ((port: PortLike?, class: "Food") -> (Food?)) & ((port: PortLike?, class: "Filter") -> (Filter?)) & ((port: PortLike?, class: "Antenna") -> (Antenna?)) & ((port: PortLike?, class: "Instrument") -> (Instrument?)) & ((port: PortLike?, class: "ARController") -> (ARController?)) & ((port: PortLike?, class: "Teleporter") -> (Teleporter?)) & ((port: PortLike?, class: "Laser") -> (Laser?)) & ((port: PortLike?, class: "DevHeatStorage") -> (DevHeatStorage?)) & ((port: PortLike?, class: "BurnerGenerator") -> (BurnerGenerator?)) & ((port: PortLike?, class: "DevGravityGenerator") -> (DevGravityGenerator?)) & ((port: PortLike?, class: "Servo") -> (Servo?)) & ((port: PortLike?, class: "DriveBox") -> (DriveBox?)) & ((port: PortLike?, class: "FluidProjector") -> (FluidProjector?)) & ((port: PortLike?, class: "TimeSensor") -> (TimeSensor?)) & ((port: PortLike?, class: "ElectricFence") -> (ElectricFence?)) & ((port: PortLike?, class: "Pump") -> (Pump?)) & ((port: PortLike?, class: "Assembler") -> (Assembler?)) & ((port: PortLike?, class: "Keyboard") -> (Keyboard?)) & ((port: PortLike?, class: "StasisField") -> (StasisField?)) & ((port: PortLike?, class: "LightBridge") -> (LightBridge?)) & ((port: PortLike?, class: "ProximityButton") -> (ProximityButton?)) & ((port: PortLike?, class: "WirelessButton") -> (WirelessButton?)) & ((port: PortLike?, class: "DarkConverter") -> (DarkConverter?)) & ((port: PortLike?, class: "Disk") -> (Disk?)) & ((port: PortLike?, class: "LightTube") -> (LightTube?)) & ((port: PortLike?, class: "LifeSensor") -> (LifeSensor?)) & ((port: PortLike?, class: "SteamTurbine") -> (SteamTurbine?)) & ((port: PortLike?, class: "PilotObject") -> (PilotObject?)) & ((port: PortLike?, class: "Component") -> (Component?)) & ((port: PortLike?, class: "Brick") -> (Brick?)) & ((port: PortLike?, class: "Warhead") -> (Warhead?)) & ((port: PortLike?, class: "Transformer") -> (Transformer?)) & ((port: PortLike?, class: "Fireworks") -> (Fireworks?)) & ((port: PortLike?, class: "FactionHub") -> (FactionHub?)) & ((port: PortLike?, class: "TriggerRelay") -> (TriggerRelay?)) & ((port: PortLike?, class: "PowerCell") -> (PowerCell?)) & ((port: PortLike?, class: "Transistor") -> (Transistor?)) & ((port: PortLike?, class: "Piston") -> (Piston?)) & ((port: PortLike?, class: "Treads") -> (Treads?)) & ((port: PortLike?, class: "CrudeWing") -> (CrudeWing?)) & ((port: PortLike?, class: "SteamEngine") -> (SteamEngine?)) & ((port: PortLike?, class: "Microcontroller") -> (Microcontroller?)) & ((port: PortLike?, class: "HeatPump") -> (HeatPump?)) & ((port: PortLike?, class: "Speaker") -> (Speaker?)) & ((port: PortLike?, class: "Hull") -> (Hull?)) & ((port: PortLike?, class: "VehicleSeat") -> (VehicleSeat?)) & ((port: PortLike?, class: "Winch") -> (Winch?)) & ((port: PortLike?, class: "Rotor") -> (Rotor?)) & ((port: PortLike?, class: "Controller") -> (Controller?)) & ((port: PortLike?, class: "Obelisk") -> (Obelisk?)) & ((port: PortLike?, class: "Motor") -> (Motor?)) & ((port: PortLike?, class: "Telescope") -> (Telescope?)) & ((port: PortLike?, class: "BlackBox") -> (BlackBox?)) & ((port: PortLike?, class: "Reactor") -> (Reactor?)) & ((port: PortLike?, class: "Prosthetic") -> (Prosthetic?)) & ((port: PortLike?, class: "Decoupler") -> (Decoupler?)) & ((port: PortLike?, class: "Solenoid") -> (Solenoid?)) & ((port: PortLike?, class: "DevSink") -> (DevSink?)) & ((port: PortLike?, class: "HyperDrive") -> (HyperDrive?)) & ((port: PortLike?, class: "TriggerSwitch") -> (TriggerSwitch?)) & ((port: PortLike?, class: "SolarPanel") -> (SolarPanel?)) & ((port: PortLike?, class: "Boombox") -> (Boombox?)) & ((port: PortLike?, class: "Igniter") -> (Igniter?)) & ((port: PortLike?, class: "DeleteSwitch") -> (DeleteSwitch?)) & ((port: PortLike?, class: "Electromagnet") -> (Electromagnet?)) & ((port: PortLike?, class: "Rocket") -> (Rocket?)) & ((port: PortLike?, class: "Scrapper") -> (Scrapper?)) & ((port: PortLike?, class: "TemperatureGate") -> (TemperatureGate?)) & ((port: PortLike?, class: "RemoteControl") -> (RemoteControl?)) & ((port: PortLike?, class: "Flamethrower") -> (Flamethrower?)) & ((port: PortLike?, class: "Light") -> (Light?)) & ((port: PortLike?, class: "Balloon") -> (Balloon?)) & ((port: PortLike?, class: "DarkReactor") -> (DarkReactor?)) & ((port: PortLike?, class: "Sail") -> (Sail?)) & ((port: PortLike?, class: "Rail") -> (Rail?)) & ((port: PortLike?, class: "RepairLaser") -> (RepairLaser?)) & ((port: PortLike?, class: "Polysilicon") -> (Polysilicon?)) & ((port: PortLike?, class: "Scanner") -> (Scanner?)) & ((port: PortLike?, class: "Furnace") -> (Furnace?)) & ((port: PortLike?, class: "DevSource") -> (DevSource?)) & ((port: PortLike?, class: "AutomaticLaser") -> (AutomaticLaser?)) & ((port: PortLike?, class: "Faucet") -> (Faucet?)) & ((port: PortLike?, class: "Thruster") -> (Thruster?)) & ((port: PortLike?, class: "CombustionTurbine") -> (CombustionTurbine?)) & ((port: PortLike?, class: "TouchScreen") -> (TouchScreen?)) & ((port: PortLike?, class: "HeatCell") -> (HeatCell?)) & ((port: PortLike?, class: "Camera") -> (Camera?)) & ((port: PortLike?, class: "Modem") -> (Modem?)) & ((port: PortLike?, class: "TemperatureSensor") -> (TemperatureSensor?)) & ((port: PortLike?, class: "Engine") -> (Engine?)) & ((port: PortLike?, class: "Radar") -> (Radar?)) & ((port: PortLike?, class: "RepairPlate") -> (RepairPlate?)) & ((port: PortLike?, class: "MiningLaser") -> (MiningLaser?)) & ((port: PortLike?, class: "IonRocket") -> (IonRocket?)) & ((port: PortLike?, class: "BallastTank") -> (BallastTank?)) & ((port: PortLike?, class: "Router") -> (Router?)) & ((port: PortLike?, class: "Explosive") -> (Explosive?)) & ((port: PortLike?, class: "ObjectDetector") -> (ObjectDetector?)) & ((port: PortLike?, class: "StarMap") -> (StarMap?)) & ((port: PortLike?, class: "TractorBeam") -> (TractorBeam?)) & ((port: PortLike?, class: "Turbofan") -> (Turbofan?)) & ((port: PortLike?, class: "Battery") -> (Battery?)) & ((port: PortLike?, class: "Coupler") -> (Coupler?)) & ((port: PortLike?, class: "DevTeleporter") -> (DevTeleporter?)) & ((port: PortLike?, class: "Seat") -> (Seat?)) & ((port: PortLike?, class: "Part100k") -> (Part100k?)) & ((port: PortLike?, class: "Valve") -> (Valve?)) & ((port: PortLike?, class: "Freezer") -> (Freezer?)) & ((port: PortLike?, class: "Melter") -> (Melter?)) & ((port: PortLike?, class: "Railgun") -> (Railgun?)) & ((port: PortLike?, class: "Dispenser") -> (Dispenser?)) & ((port: PortLike?, class: "Wing") -> (Wing?)) & ((port: PortLike?, class: "Anchor") -> (Anchor?)) & ((port: PortLike?, class: "HeatValve") -> (HeatValve?)) & ((port: PortLike?, class: "Constructor") -> (Constructor?)) & ((port: PortLike?, class: "tinnitus") -> (tinnitus?)) & ((port: PortLike?, class: "EnergyBomb") -> (EnergyBomb?)) & ((port: PortLike?, class: "EnergyShield") -> (EnergyShield?)) & ((port: PortLike?, class: "TouchSensor") -> (TouchSensor?)) & ((port: PortLike?, class: "StorageSensor") -> (StorageSensor?)) & ((port: PortLike?, class: "Microphone") -> (Microphone?)) & ((port: PortLike?, class: "Blade") -> (Blade?)) & ((port: PortLike?, class: "Sorter") -> (Sorter?)) & ((port: PortLike?, class: "Hydroponic") -> (Hydroponic?)) & ((port: PortLike?, class: "GravityGenerator") -> (GravityGenerator?)) & ((port: PortLike?, class: "Gyro") -> (Gyro?)) & ((port: PortLike?, class: "WindTurbine") -> (WindTurbine?)) & ((port: PortLike?, class: "Sign") -> (Sign?)) & ((port: PortLike?, class: "ConveyorBelt") -> (ConveyorBelt?)) & ((port: PortLike?, class: "Plastic") -> (Plastic?)) & ((port: PortLike?, class: "Hologram") -> (Hologram?)) & ((port: PortLike?, class: "FourthOfJuly") -> (FourthOfJuly?)) & ((port: PortLike?, class: "Relay") -> (Relay?)) & ((port: PortLike?, class: "Transporter") -> (Transporter?)) & ((port: PortLike?, class: "DevBattery") -> (DevBattery?)) & ((port: PortLike?, class: "Door") -> (Door?)) & ((port: PortLike?, class: "Handle") -> (Handle?)) & ((port: PortLike?, class: "SolarScoop") -> (SolarScoop?)) & ((port: PortLike?, class: "Refinery") -> (Refinery?)) & ((port: PortLike?, class: "Bin") -> (Bin?)) & ((port: PortLike?, class: "Propeller") -> (Propeller?)) & ((port: PortLike?, class: "Kiln") -> (Kiln?)) & ((port: PortLike?, class: "Boiler") -> (Boiler?)) & ((port: PortLike?, class: "Asphalt") -> (Asphalt?)) & ((port: PortLike?, class: "HyperspaceRadar") -> (HyperspaceRadar?)) & ((port: PortLike?, class: "Tank") -> (Tank?)) & ((port: PortLike?, class: "Switch") -> (Switch?)) & ((port: PortLike?, class: "Port") -> (Port?)) & ((port: PortLike?, class: "Beacon") -> (Beacon?)) & ((port: PortLike?, class: "Spotlight") -> (Spotlight?)) & ((port: PortLike?, class: string) -> (PilotObject)),
		GetParts = ( GetParts :: any ) :: ((class: "DelayWire") -> ({ DelayWire })) & ((class: "Hatch") -> ({ Hatch })) & ((class: "Screen") -> ({ Screen })) & ((class: "Extractor") -> ({ Extractor })) & ((class: "Apparel") -> ({ Apparel })) & ((class: "CloningBay") -> ({ CloningBay })) & ((class: "Food") -> ({ Food })) & ((class: "Filter") -> ({ Filter })) & ((class: "Antenna") -> ({ Antenna })) & ((class: "Instrument") -> ({ Instrument })) & ((class: "ARController") -> ({ ARController })) & ((class: "Teleporter") -> ({ Teleporter })) & ((class: "Laser") -> ({ Laser })) & ((class: "DevHeatStorage") -> ({ DevHeatStorage })) & ((class: "BurnerGenerator") -> ({ BurnerGenerator })) & ((class: "DevGravityGenerator") -> ({ DevGravityGenerator })) & ((class: "Servo") -> ({ Servo })) & ((class: "DriveBox") -> ({ DriveBox })) & ((class: "FluidProjector") -> ({ FluidProjector })) & ((class: "TimeSensor") -> ({ TimeSensor })) & ((class: "ElectricFence") -> ({ ElectricFence })) & ((class: "Pump") -> ({ Pump })) & ((class: "Assembler") -> ({ Assembler })) & ((class: "Keyboard") -> ({ Keyboard })) & ((class: "StasisField") -> ({ StasisField })) & ((class: "LightBridge") -> ({ LightBridge })) & ((class: "ProximityButton") -> ({ ProximityButton })) & ((class: "WirelessButton") -> ({ WirelessButton })) & ((class: "DarkConverter") -> ({ DarkConverter })) & ((class: "Disk") -> ({ Disk })) & ((class: "LightTube") -> ({ LightTube })) & ((class: "LifeSensor") -> ({ LifeSensor })) & ((class: "SteamTurbine") -> ({ SteamTurbine })) & ((class: "PilotObject") -> ({ PilotObject })) & ((class: "Component") -> ({ Component })) & ((class: "Brick") -> ({ Brick })) & ((class: "Warhead") -> ({ Warhead })) & ((class: "Transformer") -> ({ Transformer })) & ((class: "Fireworks") -> ({ Fireworks })) & ((class: "FactionHub") -> ({ FactionHub })) & ((class: "TriggerRelay") -> ({ TriggerRelay })) & ((class: "PowerCell") -> ({ PowerCell })) & ((class: "Transistor") -> ({ Transistor })) & ((class: "Piston") -> ({ Piston })) & ((class: "Treads") -> ({ Treads })) & ((class: "CrudeWing") -> ({ CrudeWing })) & ((class: "SteamEngine") -> ({ SteamEngine })) & ((class: "Microcontroller") -> ({ Microcontroller })) & ((class: "HeatPump") -> ({ HeatPump })) & ((class: "Speaker") -> ({ Speaker })) & ((class: "Hull") -> ({ Hull })) & ((class: "VehicleSeat") -> ({ VehicleSeat })) & ((class: "Winch") -> ({ Winch })) & ((class: "Rotor") -> ({ Rotor })) & ((class: "Controller") -> ({ Controller })) & ((class: "Obelisk") -> ({ Obelisk })) & ((class: "Motor") -> ({ Motor })) & ((class: "Telescope") -> ({ Telescope })) & ((class: "BlackBox") -> ({ BlackBox })) & ((class: "Reactor") -> ({ Reactor })) & ((class: "Prosthetic") -> ({ Prosthetic })) & ((class: "Decoupler") -> ({ Decoupler })) & ((class: "Solenoid") -> ({ Solenoid })) & ((class: "DevSink") -> ({ DevSink })) & ((class: "HyperDrive") -> ({ HyperDrive })) & ((class: "TriggerSwitch") -> ({ TriggerSwitch })) & ((class: "SolarPanel") -> ({ SolarPanel })) & ((class: "Boombox") -> ({ Boombox })) & ((class: "Igniter") -> ({ Igniter })) & ((class: "DeleteSwitch") -> ({ DeleteSwitch })) & ((class: "Electromagnet") -> ({ Electromagnet })) & ((class: "Rocket") -> ({ Rocket })) & ((class: "Scrapper") -> ({ Scrapper })) & ((class: "TemperatureGate") -> ({ TemperatureGate })) & ((class: "RemoteControl") -> ({ RemoteControl })) & ((class: "Flamethrower") -> ({ Flamethrower })) & ((class: "Light") -> ({ Light })) & ((class: "Balloon") -> ({ Balloon })) & ((class: "DarkReactor") -> ({ DarkReactor })) & ((class: "Sail") -> ({ Sail })) & ((class: "Rail") -> ({ Rail })) & ((class: "RepairLaser") -> ({ RepairLaser })) & ((class: "Polysilicon") -> ({ Polysilicon })) & ((class: "Scanner") -> ({ Scanner })) & ((class: "Furnace") -> ({ Furnace })) & ((class: "DevSource") -> ({ DevSource })) & ((class: "AutomaticLaser") -> ({ AutomaticLaser })) & ((class: "Faucet") -> ({ Faucet })) & ((class: "Thruster") -> ({ Thruster })) & ((class: "CombustionTurbine") -> ({ CombustionTurbine })) & ((class: "TouchScreen") -> ({ TouchScreen })) & ((class: "HeatCell") -> ({ HeatCell })) & ((class: "Camera") -> ({ Camera })) & ((class: "Modem") -> ({ Modem })) & ((class: "TemperatureSensor") -> ({ TemperatureSensor })) & ((class: "Engine") -> ({ Engine })) & ((class: "Radar") -> ({ Radar })) & ((class: "RepairPlate") -> ({ RepairPlate })) & ((class: "MiningLaser") -> ({ MiningLaser })) & ((class: "IonRocket") -> ({ IonRocket })) & ((class: "BallastTank") -> ({ BallastTank })) & ((class: "Router") -> ({ Router })) & ((class: "Explosive") -> ({ Explosive })) & ((class: "ObjectDetector") -> ({ ObjectDetector })) & ((class: "StarMap") -> ({ StarMap })) & ((class: "TractorBeam") -> ({ TractorBeam })) & ((class: "Turbofan") -> ({ Turbofan })) & ((class: "Battery") -> ({ Battery })) & ((class: "Coupler") -> ({ Coupler })) & ((class: "DevTeleporter") -> ({ DevTeleporter })) & ((class: "Seat") -> ({ Seat })) & ((class: "Part100k") -> ({ Part100k })) & ((class: "Valve") -> ({ Valve })) & ((class: "Freezer") -> ({ Freezer })) & ((class: "Melter") -> ({ Melter })) & ((class: "Railgun") -> ({ Railgun })) & ((class: "Dispenser") -> ({ Dispenser })) & ((class: "Wing") -> ({ Wing })) & ((class: "Anchor") -> ({ Anchor })) & ((class: "HeatValve") -> ({ HeatValve })) & ((class: "Constructor") -> ({ Constructor })) & ((class: "tinnitus") -> ({ tinnitus })) & ((class: "EnergyBomb") -> ({ EnergyBomb })) & ((class: "EnergyShield") -> ({ EnergyShield })) & ((class: "TouchSensor") -> ({ TouchSensor })) & ((class: "StorageSensor") -> ({ StorageSensor })) & ((class: "Microphone") -> ({ Microphone })) & ((class: "Blade") -> ({ Blade })) & ((class: "Sorter") -> ({ Sorter })) & ((class: "Hydroponic") -> ({ Hydroponic })) & ((class: "GravityGenerator") -> ({ GravityGenerator })) & ((class: "Gyro") -> ({ Gyro })) & ((class: "WindTurbine") -> ({ WindTurbine })) & ((class: "Sign") -> ({ Sign })) & ((class: "ConveyorBelt") -> ({ ConveyorBelt })) & ((class: "Plastic") -> ({ Plastic })) & ((class: "Hologram") -> ({ Hologram })) & ((class: "FourthOfJuly") -> ({ FourthOfJuly })) & ((class: "Relay") -> ({ Relay })) & ((class: "Transporter") -> ({ Transporter })) & ((class: "DevBattery") -> ({ DevBattery })) & ((class: "Door") -> ({ Door })) & ((class: "Handle") -> ({ Handle })) & ((class: "SolarScoop") -> ({ SolarScoop })) & ((class: "Refinery") -> ({ Refinery })) & ((class: "Bin") -> ({ Bin })) & ((class: "Propeller") -> ({ Propeller })) & ((class: "Kiln") -> ({ Kiln })) & ((class: "Boiler") -> ({ Boiler })) & ((class: "Asphalt") -> ({ Asphalt })) & ((class: "HyperspaceRadar") -> ({ HyperspaceRadar })) & ((class: "Tank") -> ({ Tank })) & ((class: "Switch") -> ({ Switch })) & ((class: "Port") -> ({ Port })) & ((class: "Beacon") -> ({ Beacon })) & ((class: "Spotlight") -> ({ Spotlight })) & ((class: string) -> ({ PilotObject })),
		GetPartsFromPort = ( GetPartsFromPort :: any ) :: ((port: PortLike?, class: "DelayWire") -> ({ DelayWire })) & ((port: PortLike?, class: "Hatch") -> ({ Hatch })) & ((port: PortLike?, class: "Screen") -> ({ Screen })) & ((port: PortLike?, class: "Extractor") -> ({ Extractor })) & ((port: PortLike?, class: "Apparel") -> ({ Apparel })) & ((port: PortLike?, class: "CloningBay") -> ({ CloningBay })) & ((port: PortLike?, class: "Food") -> ({ Food })) & ((port: PortLike?, class: "Filter") -> ({ Filter })) & ((port: PortLike?, class: "Antenna") -> ({ Antenna })) & ((port: PortLike?, class: "Instrument") -> ({ Instrument })) & ((port: PortLike?, class: "ARController") -> ({ ARController })) & ((port: PortLike?, class: "Teleporter") -> ({ Teleporter })) & ((port: PortLike?, class: "Laser") -> ({ Laser })) & ((port: PortLike?, class: "DevHeatStorage") -> ({ DevHeatStorage })) & ((port: PortLike?, class: "BurnerGenerator") -> ({ BurnerGenerator })) & ((port: PortLike?, class: "DevGravityGenerator") -> ({ DevGravityGenerator })) & ((port: PortLike?, class: "Servo") -> ({ Servo })) & ((port: PortLike?, class: "DriveBox") -> ({ DriveBox })) & ((port: PortLike?, class: "FluidProjector") -> ({ FluidProjector })) & ((port: PortLike?, class: "TimeSensor") -> ({ TimeSensor })) & ((port: PortLike?, class: "ElectricFence") -> ({ ElectricFence })) & ((port: PortLike?, class: "Pump") -> ({ Pump })) & ((port: PortLike?, class: "Assembler") -> ({ Assembler })) & ((port: PortLike?, class: "Keyboard") -> ({ Keyboard })) & ((port: PortLike?, class: "StasisField") -> ({ StasisField })) & ((port: PortLike?, class: "LightBridge") -> ({ LightBridge })) & ((port: PortLike?, class: "ProximityButton") -> ({ ProximityButton })) & ((port: PortLike?, class: "WirelessButton") -> ({ WirelessButton })) & ((port: PortLike?, class: "DarkConverter") -> ({ DarkConverter })) & ((port: PortLike?, class: "Disk") -> ({ Disk })) & ((port: PortLike?, class: "LightTube") -> ({ LightTube })) & ((port: PortLike?, class: "LifeSensor") -> ({ LifeSensor })) & ((port: PortLike?, class: "SteamTurbine") -> ({ SteamTurbine })) & ((port: PortLike?, class: "PilotObject") -> ({ PilotObject })) & ((port: PortLike?, class: "Component") -> ({ Component })) & ((port: PortLike?, class: "Brick") -> ({ Brick })) & ((port: PortLike?, class: "Warhead") -> ({ Warhead })) & ((port: PortLike?, class: "Transformer") -> ({ Transformer })) & ((port: PortLike?, class: "Fireworks") -> ({ Fireworks })) & ((port: PortLike?, class: "FactionHub") -> ({ FactionHub })) & ((port: PortLike?, class: "TriggerRelay") -> ({ TriggerRelay })) & ((port: PortLike?, class: "PowerCell") -> ({ PowerCell })) & ((port: PortLike?, class: "Transistor") -> ({ Transistor })) & ((port: PortLike?, class: "Piston") -> ({ Piston })) & ((port: PortLike?, class: "Treads") -> ({ Treads })) & ((port: PortLike?, class: "CrudeWing") -> ({ CrudeWing })) & ((port: PortLike?, class: "SteamEngine") -> ({ SteamEngine })) & ((port: PortLike?, class: "Microcontroller") -> ({ Microcontroller })) & ((port: PortLike?, class: "HeatPump") -> ({ HeatPump })) & ((port: PortLike?, class: "Speaker") -> ({ Speaker })) & ((port: PortLike?, class: "Hull") -> ({ Hull })) & ((port: PortLike?, class: "VehicleSeat") -> ({ VehicleSeat })) & ((port: PortLike?, class: "Winch") -> ({ Winch })) & ((port: PortLike?, class: "Rotor") -> ({ Rotor })) & ((port: PortLike?, class: "Controller") -> ({ Controller })) & ((port: PortLike?, class: "Obelisk") -> ({ Obelisk })) & ((port: PortLike?, class: "Motor") -> ({ Motor })) & ((port: PortLike?, class: "Telescope") -> ({ Telescope })) & ((port: PortLike?, class: "BlackBox") -> ({ BlackBox })) & ((port: PortLike?, class: "Reactor") -> ({ Reactor })) & ((port: PortLike?, class: "Prosthetic") -> ({ Prosthetic })) & ((port: PortLike?, class: "Decoupler") -> ({ Decoupler })) & ((port: PortLike?, class: "Solenoid") -> ({ Solenoid })) & ((port: PortLike?, class: "DevSink") -> ({ DevSink })) & ((port: PortLike?, class: "HyperDrive") -> ({ HyperDrive })) & ((port: PortLike?, class: "TriggerSwitch") -> ({ TriggerSwitch })) & ((port: PortLike?, class: "SolarPanel") -> ({ SolarPanel })) & ((port: PortLike?, class: "Boombox") -> ({ Boombox })) & ((port: PortLike?, class: "Igniter") -> ({ Igniter })) & ((port: PortLike?, class: "DeleteSwitch") -> ({ DeleteSwitch })) & ((port: PortLike?, class: "Electromagnet") -> ({ Electromagnet })) & ((port: PortLike?, class: "Rocket") -> ({ Rocket })) & ((port: PortLike?, class: "Scrapper") -> ({ Scrapper })) & ((port: PortLike?, class: "TemperatureGate") -> ({ TemperatureGate })) & ((port: PortLike?, class: "RemoteControl") -> ({ RemoteControl })) & ((port: PortLike?, class: "Flamethrower") -> ({ Flamethrower })) & ((port: PortLike?, class: "Light") -> ({ Light })) & ((port: PortLike?, class: "Balloon") -> ({ Balloon })) & ((port: PortLike?, class: "DarkReactor") -> ({ DarkReactor })) & ((port: PortLike?, class: "Sail") -> ({ Sail })) & ((port: PortLike?, class: "Rail") -> ({ Rail })) & ((port: PortLike?, class: "RepairLaser") -> ({ RepairLaser })) & ((port: PortLike?, class: "Polysilicon") -> ({ Polysilicon })) & ((port: PortLike?, class: "Scanner") -> ({ Scanner })) & ((port: PortLike?, class: "Furnace") -> ({ Furnace })) & ((port: PortLike?, class: "DevSource") -> ({ DevSource })) & ((port: PortLike?, class: "AutomaticLaser") -> ({ AutomaticLaser })) & ((port: PortLike?, class: "Faucet") -> ({ Faucet })) & ((port: PortLike?, class: "Thruster") -> ({ Thruster })) & ((port: PortLike?, class: "CombustionTurbine") -> ({ CombustionTurbine })) & ((port: PortLike?, class: "TouchScreen") -> ({ TouchScreen })) & ((port: PortLike?, class: "HeatCell") -> ({ HeatCell })) & ((port: PortLike?, class: "Camera") -> ({ Camera })) & ((port: PortLike?, class: "Modem") -> ({ Modem })) & ((port: PortLike?, class: "TemperatureSensor") -> ({ TemperatureSensor })) & ((port: PortLike?, class: "Engine") -> ({ Engine })) & ((port: PortLike?, class: "Radar") -> ({ Radar })) & ((port: PortLike?, class: "RepairPlate") -> ({ RepairPlate })) & ((port: PortLike?, class: "MiningLaser") -> ({ MiningLaser })) & ((port: PortLike?, class: "IonRocket") -> ({ IonRocket })) & ((port: PortLike?, class: "BallastTank") -> ({ BallastTank })) & ((port: PortLike?, class: "Router") -> ({ Router })) & ((port: PortLike?, class: "Explosive") -> ({ Explosive })) & ((port: PortLike?, class: "ObjectDetector") -> ({ ObjectDetector })) & ((port: PortLike?, class: "StarMap") -> ({ StarMap })) & ((port: PortLike?, class: "TractorBeam") -> ({ TractorBeam })) & ((port: PortLike?, class: "Turbofan") -> ({ Turbofan })) & ((port: PortLike?, class: "Battery") -> ({ Battery })) & ((port: PortLike?, class: "Coupler") -> ({ Coupler })) & ((port: PortLike?, class: "DevTeleporter") -> ({ DevTeleporter })) & ((port: PortLike?, class: "Seat") -> ({ Seat })) & ((port: PortLike?, class: "Part100k") -> ({ Part100k })) & ((port: PortLike?, class: "Valve") -> ({ Valve })) & ((port: PortLike?, class: "Freezer") -> ({ Freezer })) & ((port: PortLike?, class: "Melter") -> ({ Melter })) & ((port: PortLike?, class: "Railgun") -> ({ Railgun })) & ((port: PortLike?, class: "Dispenser") -> ({ Dispenser })) & ((port: PortLike?, class: "Wing") -> ({ Wing })) & ((port: PortLike?, class: "Anchor") -> ({ Anchor })) & ((port: PortLike?, class: "HeatValve") -> ({ HeatValve })) & ((port: PortLike?, class: "Constructor") -> ({ Constructor })) & ((port: PortLike?, class: "tinnitus") -> ({ tinnitus })) & ((port: PortLike?, class: "EnergyBomb") -> ({ EnergyBomb })) & ((port: PortLike?, class: "EnergyShield") -> ({ EnergyShield })) & ((port: PortLike?, class: "TouchSensor") -> ({ TouchSensor })) & ((port: PortLike?, class: "StorageSensor") -> ({ StorageSensor })) & ((port: PortLike?, class: "Microphone") -> ({ Microphone })) & ((port: PortLike?, class: "Blade") -> ({ Blade })) & ((port: PortLike?, class: "Sorter") -> ({ Sorter })) & ((port: PortLike?, class: "Hydroponic") -> ({ Hydroponic })) & ((port: PortLike?, class: "GravityGenerator") -> ({ GravityGenerator })) & ((port: PortLike?, class: "Gyro") -> ({ Gyro })) & ((port: PortLike?, class: "WindTurbine") -> ({ WindTurbine })) & ((port: PortLike?, class: "Sign") -> ({ Sign })) & ((port: PortLike?, class: "ConveyorBelt") -> ({ ConveyorBelt })) & ((port: PortLike?, class: "Plastic") -> ({ Plastic })) & ((port: PortLike?, class: "Hologram") -> ({ Hologram })) & ((port: PortLike?, class: "FourthOfJuly") -> ({ FourthOfJuly })) & ((port: PortLike?, class: "Relay") -> ({ Relay })) & ((port: PortLike?, class: "Transporter") -> ({ Transporter })) & ((port: PortLike?, class: "DevBattery") -> ({ DevBattery })) & ((port: PortLike?, class: "Door") -> ({ Door })) & ((port: PortLike?, class: "Handle") -> ({ Handle })) & ((port: PortLike?, class: "SolarScoop") -> ({ SolarScoop })) & ((port: PortLike?, class: "Refinery") -> ({ Refinery })) & ((port: PortLike?, class: "Bin") -> ({ Bin })) & ((port: PortLike?, class: "Propeller") -> ({ Propeller })) & ((port: PortLike?, class: "Kiln") -> ({ Kiln })) & ((port: PortLike?, class: "Boiler") -> ({ Boiler })) & ((port: PortLike?, class: "Asphalt") -> ({ Asphalt })) & ((port: PortLike?, class: "HyperspaceRadar") -> ({ HyperspaceRadar })) & ((port: PortLike?, class: "Tank") -> ({ Tank })) & ((port: PortLike?, class: "Switch") -> ({ Switch })) & ((port: PortLike?, class: "Port") -> ({ Port })) & ((port: PortLike?, class: "Beacon") -> ({ Beacon })) & ((port: PortLike?, class: "Spotlight") -> ({ Spotlight })) & ((port: PortLike?, class: string) -> ({ PilotObject })),
		GetPart = ( GetPart :: any ) :: ((class: "DelayWire") -> (DelayWire?)) & ((class: "Hatch") -> (Hatch?)) & ((class: "Screen") -> (Screen?)) & ((class: "Extractor") -> (Extractor?)) & ((class: "Apparel") -> (Apparel?)) & ((class: "CloningBay") -> (CloningBay?)) & ((class: "Food") -> (Food?)) & ((class: "Filter") -> (Filter?)) & ((class: "Antenna") -> (Antenna?)) & ((class: "Instrument") -> (Instrument?)) & ((class: "ARController") -> (ARController?)) & ((class: "Teleporter") -> (Teleporter?)) & ((class: "Laser") -> (Laser?)) & ((class: "DevHeatStorage") -> (DevHeatStorage?)) & ((class: "BurnerGenerator") -> (BurnerGenerator?)) & ((class: "DevGravityGenerator") -> (DevGravityGenerator?)) & ((class: "Servo") -> (Servo?)) & ((class: "DriveBox") -> (DriveBox?)) & ((class: "FluidProjector") -> (FluidProjector?)) & ((class: "TimeSensor") -> (TimeSensor?)) & ((class: "ElectricFence") -> (ElectricFence?)) & ((class: "Pump") -> (Pump?)) & ((class: "Assembler") -> (Assembler?)) & ((class: "Keyboard") -> (Keyboard?)) & ((class: "StasisField") -> (StasisField?)) & ((class: "LightBridge") -> (LightBridge?)) & ((class: "ProximityButton") -> (ProximityButton?)) & ((class: "WirelessButton") -> (WirelessButton?)) & ((class: "DarkConverter") -> (DarkConverter?)) & ((class: "Disk") -> (Disk?)) & ((class: "LightTube") -> (LightTube?)) & ((class: "LifeSensor") -> (LifeSensor?)) & ((class: "SteamTurbine") -> (SteamTurbine?)) & ((class: "PilotObject") -> (PilotObject?)) & ((class: "Component") -> (Component?)) & ((class: "Brick") -> (Brick?)) & ((class: "Warhead") -> (Warhead?)) & ((class: "Transformer") -> (Transformer?)) & ((class: "Fireworks") -> (Fireworks?)) & ((class: "FactionHub") -> (FactionHub?)) & ((class: "TriggerRelay") -> (TriggerRelay?)) & ((class: "PowerCell") -> (PowerCell?)) & ((class: "Transistor") -> (Transistor?)) & ((class: "Piston") -> (Piston?)) & ((class: "Treads") -> (Treads?)) & ((class: "CrudeWing") -> (CrudeWing?)) & ((class: "SteamEngine") -> (SteamEngine?)) & ((class: "Microcontroller") -> (Microcontroller?)) & ((class: "HeatPump") -> (HeatPump?)) & ((class: "Speaker") -> (Speaker?)) & ((class: "Hull") -> (Hull?)) & ((class: "VehicleSeat") -> (VehicleSeat?)) & ((class: "Winch") -> (Winch?)) & ((class: "Rotor") -> (Rotor?)) & ((class: "Controller") -> (Controller?)) & ((class: "Obelisk") -> (Obelisk?)) & ((class: "Motor") -> (Motor?)) & ((class: "Telescope") -> (Telescope?)) & ((class: "BlackBox") -> (BlackBox?)) & ((class: "Reactor") -> (Reactor?)) & ((class: "Prosthetic") -> (Prosthetic?)) & ((class: "Decoupler") -> (Decoupler?)) & ((class: "Solenoid") -> (Solenoid?)) & ((class: "DevSink") -> (DevSink?)) & ((class: "HyperDrive") -> (HyperDrive?)) & ((class: "TriggerSwitch") -> (TriggerSwitch?)) & ((class: "SolarPanel") -> (SolarPanel?)) & ((class: "Boombox") -> (Boombox?)) & ((class: "Igniter") -> (Igniter?)) & ((class: "DeleteSwitch") -> (DeleteSwitch?)) & ((class: "Electromagnet") -> (Electromagnet?)) & ((class: "Rocket") -> (Rocket?)) & ((class: "Scrapper") -> (Scrapper?)) & ((class: "TemperatureGate") -> (TemperatureGate?)) & ((class: "RemoteControl") -> (RemoteControl?)) & ((class: "Flamethrower") -> (Flamethrower?)) & ((class: "Light") -> (Light?)) & ((class: "Balloon") -> (Balloon?)) & ((class: "DarkReactor") -> (DarkReactor?)) & ((class: "Sail") -> (Sail?)) & ((class: "Rail") -> (Rail?)) & ((class: "RepairLaser") -> (RepairLaser?)) & ((class: "Polysilicon") -> (Polysilicon?)) & ((class: "Scanner") -> (Scanner?)) & ((class: "Furnace") -> (Furnace?)) & ((class: "DevSource") -> (DevSource?)) & ((class: "AutomaticLaser") -> (AutomaticLaser?)) & ((class: "Faucet") -> (Faucet?)) & ((class: "Thruster") -> (Thruster?)) & ((class: "CombustionTurbine") -> (CombustionTurbine?)) & ((class: "TouchScreen") -> (TouchScreen?)) & ((class: "HeatCell") -> (HeatCell?)) & ((class: "Camera") -> (Camera?)) & ((class: "Modem") -> (Modem?)) & ((class: "TemperatureSensor") -> (TemperatureSensor?)) & ((class: "Engine") -> (Engine?)) & ((class: "Radar") -> (Radar?)) & ((class: "RepairPlate") -> (RepairPlate?)) & ((class: "MiningLaser") -> (MiningLaser?)) & ((class: "IonRocket") -> (IonRocket?)) & ((class: "BallastTank") -> (BallastTank?)) & ((class: "Router") -> (Router?)) & ((class: "Explosive") -> (Explosive?)) & ((class: "ObjectDetector") -> (ObjectDetector?)) & ((class: "StarMap") -> (StarMap?)) & ((class: "TractorBeam") -> (TractorBeam?)) & ((class: "Turbofan") -> (Turbofan?)) & ((class: "Battery") -> (Battery?)) & ((class: "Coupler") -> (Coupler?)) & ((class: "DevTeleporter") -> (DevTeleporter?)) & ((class: "Seat") -> (Seat?)) & ((class: "Part100k") -> (Part100k?)) & ((class: "Valve") -> (Valve?)) & ((class: "Freezer") -> (Freezer?)) & ((class: "Melter") -> (Melter?)) & ((class: "Railgun") -> (Railgun?)) & ((class: "Dispenser") -> (Dispenser?)) & ((class: "Wing") -> (Wing?)) & ((class: "Anchor") -> (Anchor?)) & ((class: "HeatValve") -> (HeatValve?)) & ((class: "Constructor") -> (Constructor?)) & ((class: "tinnitus") -> (tinnitus?)) & ((class: "EnergyBomb") -> (EnergyBomb?)) & ((class: "EnergyShield") -> (EnergyShield?)) & ((class: "TouchSensor") -> (TouchSensor?)) & ((class: "StorageSensor") -> (StorageSensor?)) & ((class: "Microphone") -> (Microphone?)) & ((class: "Blade") -> (Blade?)) & ((class: "Sorter") -> (Sorter?)) & ((class: "Hydroponic") -> (Hydroponic?)) & ((class: "GravityGenerator") -> (GravityGenerator?)) & ((class: "Gyro") -> (Gyro?)) & ((class: "WindTurbine") -> (WindTurbine?)) & ((class: "Sign") -> (Sign?)) & ((class: "ConveyorBelt") -> (ConveyorBelt?)) & ((class: "Plastic") -> (Plastic?)) & ((class: "Hologram") -> (Hologram?)) & ((class: "FourthOfJuly") -> (FourthOfJuly?)) & ((class: "Relay") -> (Relay?)) & ((class: "Transporter") -> (Transporter?)) & ((class: "DevBattery") -> (DevBattery?)) & ((class: "Door") -> (Door?)) & ((class: "Handle") -> (Handle?)) & ((class: "SolarScoop") -> (SolarScoop?)) & ((class: "Refinery") -> (Refinery?)) & ((class: "Bin") -> (Bin?)) & ((class: "Propeller") -> (Propeller?)) & ((class: "Kiln") -> (Kiln?)) & ((class: "Boiler") -> (Boiler?)) & ((class: "Asphalt") -> (Asphalt?)) & ((class: "HyperspaceRadar") -> (HyperspaceRadar?)) & ((class: "Tank") -> (Tank?)) & ((class: "Switch") -> (Switch?)) & ((class: "Port") -> (Port?)) & ((class: "Beacon") -> (Beacon?)) & ((class: "Spotlight") -> (Spotlight?)) & ((class: string) -> (PilotObject)),
		logError = ( logError :: any ) :: (message: string, level: number?) -> (),
		Beep = ( Beep :: any ) :: (frequency: number?) -> (),
		GetCPUTime = ( GetCPUTime :: any ) :: () -> (number),
	},
	{
		__call = function(self)
			return self.Beep, self.FileSystem, self.GetCPUTime, self.GetPart, self.GetPartFromPort, self.GetParts, self.GetPartsFromPort, self.GetPort, self.GetPorts, self.JSONDecode, self.JSONEncode, self.Microcontroller, self.Network, self.RawFileSystem, self.SandboxID, self.SandboxRunID, self.TriggerPort, self.logError, self.pilot
		end
	}
)

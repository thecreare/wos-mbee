local module = {}

module.COMPAT_NAME_REPLACEMENTS = {
    SteeringSeat = "VehicleSeat";
    Aluminium = "Aluminum";
    SignalWire = "TriggerWire";
    Explosives = "Explosive";
    WheelTemplate = "Cylinder";
    CylinderTemplate = "Cylinder";
    WedgeTemplate = "Wedge";
    CornerTemplate = "CornerWedge";
    CornerTetraTemplate = "CornerTetra";
    TetrahedronTemplate = "Tetrahedron";
    BallTemplate = "Ball";
    DoorTemplate = "Door";
    BladeTemplate = "Blade";
    RoundTemplate = "RoundWedge";
    RoundTemplate2 = "RoundWedge2";
    CornerRoundTemplate = "CornerRoundWedge";
    CornerRoundTemplate2 = "CornerRoundWedge2";
    TrussTemplate = "Truss";
    Eridanium = "Iron";
    Abantium = "Iron";
    Lirvanite = "Iron";
    TouchTrigger = "TouchSensor";
    IonDrive = "Thruster";
    NeonBuildingPart = "Neon";
    SpotLight = "Spotlight";
    Airshield = "AirSupply";
    PsiSwitch = "WirelessButton";

    Container = "Tank";
}

module.COMPAT_CONFIG_REPLACEMENTS = {
    Swing = {
        ["No swing"] = "None",
        ["Swing down"] = "Swing",
        ["Follow cursor"] = "Point",    
    },

    TriggerMode = {
        ["Trigger on down"] = "MouseDown",
        ["Trigger on up"] = "MouseUp",
        ["Trigger on up and down"] = "Both",
    }
}

return module
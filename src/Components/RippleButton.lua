local PseudoInstance = require(script.Parent.Parent.MBEPackages.PseudoInstance)

local THEME = require(script.Parent.Parent.Theme)
local Fusion = require(script.Parent.Parent.Packages.fusion)
type UsedAs<T> = Fusion.UsedAs<T>

local function RippleButton(
    scope: Fusion.Scope<typeof(Fusion)>,
    props: {
        Label: UsedAs<string>?,
        OnPressed: ()->(),
        Parent: UsedAs<Instance>?,
        Style: UsedAs<"Flat"|"Outlined"|"Contained">?,
        BorderRadius: UsedAs<number>?,
        Layout: {
            LayoutOrder: UsedAs<number>?,
            Position: UsedAs<UDim2>?,
            AnchorPoint: UsedAs<Vector2>?,
            ZIndex: UsedAs<number>?,
            Size: UsedAs<UDim2>?,
            AutomaticSize: UsedAs<Enum.AutomaticSize>?,
        }?,
    }
): Fusion.Child
    props.Layout = props.Layout or {}; assert(props.Layout)

    local holder = scope:New "Frame" {
        Name = props.Label,
        BackgroundTransparency = 1,

        Parent = props.Parent,

        LayoutOrder = props.Layout.LayoutOrder,
        Position = props.Layout.Position,
        AnchorPoint = props.Layout.AnchorPoint,
        ZIndex = props.Layout.ZIndex,
        Size = props.Layout.Size or UDim2.new(1, -10, 0, 32),
        AutomaticSize = props.Layout.AutomaticSize,
    }

    -- I hate PseudoInstance
    local button = scope:Hydrate(PseudoInstance.new("RippleButton")) {
        Text = props.Label,
        -- FontFace = THEME.font_regular,
        Font = THEME.font,
        TextSize = 24,
        PrimaryColor3 = THEME.COLORS.MainContrast,
        Size = UDim2.fromScale(1, 1),

        -- idk
        BorderRadius = props.BorderRadius or 0,
        Style = props.Style or "Outlined",
    }
    button.OnPressed:Connect(props.OnPressed)
    button.Parent = holder

    return holder
end

return RippleButton
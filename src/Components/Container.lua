local THEME = require(script.Parent.Parent.Theme)
local Fusion = require(script.Parent.Parent.Packages.fusion)

local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

local function PaddedContainer(
    scope: Fusion.Scope<typeof(Fusion)>,
    props: {
        Name: UsedAs<string>?,
        BackgroundColor3: UsedAs<Color3>?,
        BackgroundTransparency: UsedAs<number>?,
        ClipsDescendants: UsedAs<boolean>?,
        Visible: UsedAs<boolean>?,
        Parent: UsedAs<Instance>?,

        AbsoluteSizeOut: Fusion.Value<Vector2, Vector2>?,

        Padding: {
            All: UsedAs<UDim>?,
            Bottom: UsedAs<UDim>?,
            Left: UsedAs<UDim>?,
            Right: UsedAs<UDim>?,
            Top: UsedAs<UDim>?,
        }?,
        Layout: {
            LayoutOrder: UsedAs<number>?,
            Position: UsedAs<UDim2>?,
            AnchorPoint: UsedAs<Vector2>?,
            ZIndex: UsedAs<number>?,
            Size: UsedAs<UDim2>?,
            AutomaticSize: UsedAs<Enum.AutomaticSize>?,
            Rotation: UsedAs<number>?,
        }?,
        [typeof(Children)]: Fusion.Child?,
    }
): Fusion.Child
    local scope = scope:innerScope({
        Padding = require(script.Parent.Padding)
    })
    props.Layout = props.Layout or {}
    assert(props.Layout, "Can't happen")
    return scope:New "Frame" {
        Name = props.Name or "Container",
        BackgroundColor3 = props.BackgroundColor3 or THEME.COLORS.MainBackground,
        BackgroundTransparency = props.BackgroundTransparency,
        Visible = props.Visible,
        ClipsDescendants = props.ClipsDescendants,
        Parent = props.Parent,

        -- Layout
        LayoutOrder = props.Layout.LayoutOrder,
        Position = props.Layout.Position,
        AnchorPoint = props.Layout.AnchorPoint,
        ZIndex = props.Layout.ZIndex,
        Size = props.Layout.Size or UDim2.fromScale(1, 1),
        AutomaticSize = props.Layout.AutomaticSize,
        Rotation = props.Layout.Rotation,

        [Fusion.Out "AbsoluteSize"] = props.AbsoluteSizeOut,

        [Children] = {
            -- Padding
            scope:Padding {
                Padding = props.Padding,
            },
            props[Children] :: Fusion.Child,
        }
    }
end

return PaddedContainer
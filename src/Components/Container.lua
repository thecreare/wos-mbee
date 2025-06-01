--!strict
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

        Padding: {
            All: UsedAs<UDim>?,
            Bottom: UsedAs<number>?,
            Left: UsedAs<number>?,
            Right: UsedAs<number>?,
            Top: UsedAs<number>?,
        },
        Layout: {
            LayoutOrder: UsedAs<number>?,
            Position: UsedAs<UDim2>?,
            AnchorPoint: UsedAs<Vector2>?,
            ZIndex: UsedAs<number>?,
            Size: UsedAs<UDim2>?,
            AutomaticSize: UsedAs<Enum.AutomaticSize>?,
        },
        [typeof(Children)]: Fusion.Child,
    }
): Fusion.Child
    local scope = scope:deriveScope({
        Padding = require(script.Parent.Padding)
    })
    props.Layout = props.Layout or {}
    return scope:New "Frame" {
        Name = props.Name,
        BackgroundColor3 = props.BackgroundColor3 or THEME.COLORS.MainBackground,
        BackgroundTransparency = props.BackgroundTransparency,

        -- Layout
        LayoutOrder = props.Layout.LayoutOrder,
        Position = props.Layout.Position,
        AnchorPoint = props.Layout.AnchorPoint,
        ZIndex = props.Layout.ZIndex,
        Size = props.Layout.Size or UDim2.fromScale(1, 1),
        AutomaticSize = props.Layout.AutomaticSize,

        [Children] = {
            -- Padding
            props.Padding and scope:Padding {
                Padding = props.Padding,
            },
            props[Children],
        }
    }
end

return PaddedContainer
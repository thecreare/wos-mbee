--!strict
local Fusion = require(script.Parent.Parent.Packages.fusion)
type UsedAs<T> = Fusion.UsedAs<T>

local function Padding(
    scope: Fusion.Scope<typeof(Fusion)>,
    props: {
        Padding: {
            All: UsedAs<UDim>?,
            Bottom: UsedAs<number>?,
            Left: UsedAs<number>?,
            Right: UsedAs<number>?,
            Top: UsedAs<number>?,
        },
    }
): Fusion.Child
    return scope:New "UIPadding" {
        PaddingBottom = props.Padding.Bottom or props.Padding.All,
        PaddingLeft = props.Padding.Left or props.Padding.All,
        PaddingRight = props.Padding.Right or props.Padding.All,
        PaddingTop = props.Padding.Top or props.Padding.All,
    }
end

return Padding
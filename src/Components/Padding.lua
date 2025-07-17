local Fusion = require(script.Parent.Parent.Packages.fusion)
type UsedAs<T> = Fusion.UsedAs<T>

local function Padding(
    scope: Fusion.Scope<typeof(Fusion)>,
    props: {
        Padding: {
            All: UsedAs<UDim>?,
            Bottom: UsedAs<UDim>?,
            Left: UsedAs<UDim>?,
            Right: UsedAs<UDim>?,
            Top: UsedAs<UDim>?,
        }?,
    }
): Fusion.Child
    props.Padding = props.Padding or {}
    assert(props.Padding, "Can't happen")
    local all = props.Padding.All or UDim.new(0, 0)
    return scope:New "UIPadding" {
        PaddingBottom = props.Padding.Bottom or all,
        PaddingLeft = props.Padding.Left or all,
        PaddingRight = props.Padding.Right or all,
        PaddingTop = props.Padding.Top or all,
    }
end

return Padding
local Fusion = require(script.Parent.Parent.Packages.fusion)
type UsedAs<T> = Fusion.UsedAs<T>

local function UIListLayout(
    scope: Fusion.Scope<typeof(Fusion)>,
    props: {
        Name: UsedAs<string>?,
        Parent: UsedAs<Instance>?,
        Padding: UsedAs<UDim>?,
        FillDirection: UsedAs<Enum.FillDirection>?,
        SortOrder: UsedAs<Enum.SortOrder>?,
        Wraps: UsedAs<boolean>?,
        
        HorizontalAlignment: UsedAs<Enum.HorizontalAlignment>?,
        VerticalAlignment: UsedAs<Enum.VerticalAlignment>?,
        HorizontalFlex: UsedAs<Enum.UIFlexMode>?,
        VerticalFlex: UsedAs<Enum.UIFlexMode>?,
        ItemLineAlignment: UsedAs<Enum.ItemLineAlignment>?,
    }
): Fusion.Child
    return scope:New "UIListLayout" {
        Name = props.Name,
        Parent = props.Parent,
        Padding = props.Padding or UDim.new(0, 4),
        FillDirection = props.FillDirection,
        SortOrder = props.SortOrder or Enum.SortOrder.LayoutOrder,
        Wraps = props.Wraps,

        HorizontalAlignment = props.HorizontalAlignment,
        VerticalAlignment = props.VerticalAlignment,
        HorizontalFlex = props.HorizontalFlex,
        VerticalFlex = props.VerticalFlex,
        ItemLineAlignment = props.ItemLineAlignment,
    }
end

return UIListLayout
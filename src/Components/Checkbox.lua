local PseudoInstance = require(script.Parent.Parent.MBEPackages.PseudoInstance)

local THEME = require(script.Parent.Parent.Theme)
local Fusion = require(script.Parent.Parent.Packages.fusion)
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

local function Checkbox(
    scope: Fusion.Scope<typeof(Fusion)>,
    props: {
        Label: UsedAs<string>?,
        Checked: UsedAs<boolean>,
        Parent: UsedAs<Instance>?,
        Layout: {
            LayoutOrder: UsedAs<number>?,
            Position: UsedAs<UDim2>?,
            AnchorPoint: UsedAs<Vector2>?,
            ZIndex: UsedAs<number>?,
            Size: UsedAs<UDim2>?,
            AutomaticSize: UsedAs<Enum.AutomaticSize>?,
        },
    }
): Fusion.Child
    props.Layout = props.Layout or {}

    local holder = scope:New "Frame" {
        Name = "Holder",
        BackgroundTransparency = 1,
        Parent = props.Parent,
        
        LayoutOrder = props.Layout.LayoutOrder,
        Position = props.Layout.Position,
        AnchorPoint = props.Layout.AnchorPoint,
        ZIndex = props.Layout.ZIndex,
        Size = props.Layout.Size or UDim2.new(1, -6, 0, 30),
        AutomaticSize = props.Layout.AutomaticSize,

        [Children] = {
            scope:New "UIListLayout" {
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
            },
            scope:New "TextLabel" {
                Name = "Label",
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = props.Label,
                FontFace = THEME.font_regular,
                TextColor3 = THEME.COLORS.MainText,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextSize = 24,
                ClipsDescendants = true,
                LayoutOrder = 1,
                [Children] = {
                    scope:New "UIFlexItem" { FlexMode = Enum.UIFlexMode.Shrink }
                },
            },
        },
    }

    -- I hate PseudoInstance
    local checkbox = scope:Hydrate(PseudoInstance.new("Checkbox")) {
        PrimaryColor3 = THEME.COLORS.MainContrast,
        LayoutOrder = 2,
        Checked = props.Checked,
    }
    -- Reflect checkbox state
    checkbox.OnChecked:Connect(function(On)
        props.Checked:set(On)
    end)
    checkbox.Parent = holder

    return holder
end

return Checkbox
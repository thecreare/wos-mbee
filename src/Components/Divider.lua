--!strict

local rs = game:GetService("ReplicatedStorage")

local THEME = require(script.Parent.Parent.Theme)
local Fusion = require(script.Parent.Parent.Packages.fusion)

type UsedAs<T> = Fusion.UsedAs<T>

local function Divider(
    scope: Fusion.Scope<typeof(Fusion)>,
    props: {
        LayoutOrder: UsedAs<number>?,
        Axis: UsedAs<"X"|"Y">?,
        Thickness: UsedAs<number>?,
        Parent: UsedAs<Instance>?,
    }
): Fusion.Child
    return scope:New "Frame" {
        LayoutOrder = props.LayoutOrder,
        BackgroundColor3 = THEME.COLORS.MainContrast,
        Parent = props.Parent,
        Size = scope:Computed(function(use)
            local axis = use(props.Axis) or "X"
            local thickness = use(props.Thickness) or 2
            return if axis == "X" then UDim2.new(1, 0, 0, thickness) else UDim2.new(0, thickness, 1, 0)
        end),
    }
end

return Divider
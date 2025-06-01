local THEME = require(script.Parent.Parent.Theme)
local Fusion = require(script.Parent.Parent.Packages.fusion)

local peek = Fusion.peek
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

local function ScrollingFrame(
    scope: Fusion.Scope<typeof(Fusion)>,
    props: {
        Name: UsedAs<string>?,
        ScrollingDirection: UsedAs<"X"|"Y"|"XY">?,
        BackgroundTransparency: UsedAs<number>?,
        Parent: UsedAs<Instance>?,
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
    props.Layout = props.Layout or {}
    local isScrollbarVisible = scope:Value(true)

    local scrolling_frame = scope:New "ScrollingFrame" {
        Name = props.Name,

        AutomaticCanvasSize = props.ScrollingDirection or "Y",
        ScrollingDirection = props.ScrollingDirection or "Y",
        CanvasSize = UDim2.fromScale(1, 0),
        TopImage = "rbxassetid://7058754954",
		BottomImage = "rbxassetid://7058754954",
		MidImage = "rbxassetid://7058754954",
        ScrollBarImageColor3 = THEME.COLORS.ScrollBar,
        BackgroundColor3 = THEME.COLORS.ScrollBarBackground,
        BackgroundTransparency = props.BackgroundTransparency,
        ScrollBarImageTransparency = 0,
        ScrollBarThickness = 6,

        -- Layout
        LayoutOrder = props.Layout.LayoutOrder,
        Position = props.Layout.Position,
        AnchorPoint = props.Layout.AnchorPoint,
        ZIndex = props.Layout.ZIndex,
        Size = props.Layout.Size or UDim2.fromScale(1, 1),
        AutomaticSize = props.Layout.AutomaticSize,

        Parent = props.Parent,
        [Children] = {
            scope:New "UIListLayout" {
                Padding = UDim.new(0, 3),
                SortOrder = Enum.SortOrder.LayoutOrder,
            },
            props.Padding and
                scope:New "UIPadding" {
                    PaddingBottom = props.Padding.Bottom or props.Padding.All,
                    PaddingLeft = props.Padding.Left or props.Padding.All,
                    PaddingRight = scope:Computed(function(use)
                        local pad = use(props.Padding.Right) or use(props.Padding.All) or UDim.new(0, 0)
                        return if use(isScrollbarVisible) then UDim.new(pad.Scale, pad.Offset+12) else pad
                    end),
                    PaddingTop = props.Padding.Top or props.Padding.All,
                }
            ,
            props[Children],
        },
    }

    -- Update scrollbar visiblity reflection when the canvas or window size changes
    local function UpdateExtraPadEnabled()
        isScrollbarVisible:set(scrolling_frame.AbsoluteCanvasSize.Y > scrolling_frame.AbsoluteWindowSize.Y)
    end
    scrolling_frame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(UpdateExtraPadEnabled)
    scrolling_frame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(UpdateExtraPadEnabled)


    return peek(scrolling_frame)
end

return ScrollingFrame
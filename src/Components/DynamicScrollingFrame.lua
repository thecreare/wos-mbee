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
        ListPadding: UsedAs<UDim>?,
        Parent: UsedAs<Instance>?,
        Active: UsedAs<boolean>?,

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
        }?,
        ScrollBarThickness: number?,
        RemoveListLayout: boolean?,
        [typeof(Children)]: Fusion.Child,
    }
): Fusion.Child
    local is_scrollbar_visible = scope:Value(true)
    local bar_thickness = props.ScrollBarThickness or 8
    props.Padding = props.Padding or {}; assert(props.Padding, "Can't happen")
    props.Layout = props.Layout or {}; assert(props.Layout)

    local scroll_bar_padding = scope:Computed(function(use)
        local scroll_bar_padding = if use(is_scrollbar_visible) then UDim.new(0, bar_thickness) else UDim.new(0, 0)
        return scroll_bar_padding
    end)

    local scrolling_frame = scope:New "ScrollingFrame" {
        Name = props.Name,

        AutomaticCanvasSize = props.ScrollingDirection or "Y",
        ScrollingDirection = props.ScrollingDirection or "Y",
        CanvasSize = UDim2.fromScale(0, 0),
        Active = props.Active,

        -- Rounded
        TopImage = "rbxassetid://3062506445",
        MidImage = "rbxassetid://3062506202",
        BottomImage = "rbxassetid://3062505976",

        -- Square
        -- TopImage = "rbxassetid://7058754954",
		-- BottomImage = "rbxassetid://7058754954",
		-- MidImage = "rbxassetid://7058754954",

        -- W/Arrow
        -- TopImage = "rbxassetid://13458742509",
		-- BottomImage = "rbxassetid://13458740792",
		-- MidImage = "rbxassetid://13458741869",

        ScrollBarImageColor3 = THEME.COLORS.ScrollBar,
        BackgroundColor3 = THEME.COLORS.ScrollBarBackground,
        BackgroundTransparency = props.BackgroundTransparency,
        ScrollBarImageTransparency = scope:Computed(function(use)
            return if use(is_scrollbar_visible) then 0 else 1
        end),
        ScrollBarThickness = bar_thickness,

        -- Layout
        LayoutOrder = props.Layout.LayoutOrder,
        Position = props.Layout.Position,
        AnchorPoint = props.Layout.AnchorPoint,
        ZIndex = props.Layout.ZIndex,
        Size = props.Layout.Size or UDim2.fromScale(1, 1),
        AutomaticSize = props.Layout.AutomaticSize,

        Parent = props.Parent,
        [Children] = {
            scope:New "UIPadding" {
                PaddingRight = scroll_bar_padding,
            },
            scope:New "Frame" {
                Size = UDim2.fromScale(1, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = THEME.COLORS.MainBackground,
                [Children] = {
                    if props.RemoveListLayout == true then nil else scope:New "UIListLayout" {
                        Padding = props.ListPadding or UDim.new(0, 2),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    } :: Fusion.Child,
                    scope:New "UIPadding" {
                        PaddingBottom = props.Padding.Bottom or props.Padding.All,
                        PaddingLeft = props.Padding.Left or props.Padding.All,
                        PaddingRight = props.Padding.Right or props.Padding.All,
                        PaddingTop = props.Padding.Top or props.Padding.All,
                    },
                    props[Children],
                }
            }
        },
    } :: ScrollingFrame

    -- Update scrollbar visiblity reflection when the canvas or window size changes
    local function UpdateExtraPadEnabled()
        is_scrollbar_visible:set(scrolling_frame.AbsoluteCanvasSize.Y > scrolling_frame.AbsoluteWindowSize.Y)
    end
    scrolling_frame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(UpdateExtraPadEnabled)
    scrolling_frame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(UpdateExtraPadEnabled)


    return scrolling_frame
end

return ScrollingFrame
local UITemplates = require(script.Parent.Parent.Modules.UITemplates).UITemplates

local THEME = require(script.Parent.Parent.Theme)
local Fusion = require(script.Parent.Parent.Packages.fusion)
local Children, peek = Fusion.Children, Fusion.peek
local Out = Fusion.Out
type UsedAs<T> = Fusion.UsedAs<T>

local function TextBox(
    scope: Fusion.Scope<typeof(Fusion)>,
    props: {
        Text: UsedAs<string>,
        onTextChange: (text: string)->()?,
        Options: UsedAs<{[any]: string}>?,
        PlaceholderText: UsedAs<string>?,

        Parent: UsedAs<Instance>?,
        Layout: {
            LayoutOrder: UsedAs<number>?,
            Position: UsedAs<UDim2>?,
            AnchorPoint: UsedAs<Vector2>?,
            ZIndex: UsedAs<number>?,
            Size: UsedAs<UDim2>?,
            AutomaticSize: UsedAs<Enum.AutomaticSize>?,
        }?,
        Box: {
            BackgroundColor3: UsedAs<Color3>?,
            TextColor3: UsedAs<Color3>?,
        }?,
        Label: {
            Text: UsedAs<string>?,
            TextScaled: UsedAs<boolean>?,
            TextColor3: UsedAs<Color3>?,
        }?
    }
): Fusion.Child
    props.Layout = props.Layout or {}; assert(props.Layout)
    props.Box = props.Box or {}; assert(props.Box)
    props.Label = props.Label or {}; assert(props.Label)
    local tips_open = scope:Value(false)
    local holder_size = scope:Value(UDim2.fromOffset(30, 30))

    local proxy_text_value = scope:Value(peek(props.Text))

    -- TODO: Implement real tips thing instead of extracting this and manually running the cursed mbe function on it
    local Box = scope:New "TextBox" {
        Name = props.Label.Text,
        Size = UDim2.fromScale(1, 1),
        Text = proxy_text_value,
        PlaceholderText = props.PlaceholderText or "Input...",
        TextColor3 = props.Box.TextColor3 or THEME.COLORS.MainText,
        PlaceholderColor3 = THEME.COLORS.DimmedText,
        BackgroundColor3 = props.Box.BackgroundColor3 or THEME.COLORS.InputFieldBackground,
        FontFace = THEME.font_light,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextScaled = true,
        ClearTextOnFocus = false,
        TextSize = 24,
        LayoutOrder = 2,

        -- [OnEvent "MouseEnter"] = function()
        --     tips_open:set(true)
        -- end,
        -- [OnEvent "MouseLeave"] = function()
        --     tips_open:set(false)
        -- end,

        [Children] = {
            scope:New "UIFlexItem" { FlexMode = Enum.UIFlexMode.Shrink },
            -- props.Options and scope:New "ScrollingFrame" {

            --     [Children] = {
            --         scope:New "UIListLayout" {},
            --         scope:ForValues(props.Options, function(use, scope, option)
            --             return scope:New "TextButton" {
            --                 BorderSizePixel = 1,
            --                 Size = scope:Computed(function(use)
            --                     return UDim2.new(1, 0, 0, use(holder_size).Y)
            --                 end),
            --                 Text = tostring(option),
            --                 Name = tostring(option),
            --                 FontFace = THEME.font_light,
            --                 TextXAlignment = Enum.TextXAlignment.Left,
            --                 TextScaled = true,
                            
            --                 BackgroundColor3 = THEME.COLORS.Button,
            --                 BorderColor3 = THEME.COLORS.Border,
            --                 TextColor3 = THEME.COLORS.ButtonText,

            --                 [OnEvent "Activated"] = function()
            --                     props.Text:set(option)
            --                 end,
            --             }
            --         end),
            --     }
            -- },
            -- if props.Options then scope:Computed(function(use)
            --     if use(tips_open) == false then return end
            -- end) else nil,
        },
    } :: TextBox


    local changing = false
    scope:Observer(props.Text):onChange(function()
        changing = true
        proxy_text_value:set(peek(props.Text))
        changing = false
    end)
    if props.onTextChange then       
        table.insert(scope, Box:GetPropertyChangedSignal("Text"):Connect(function()
            if changing then return end
            props.onTextChange(Box.Text)
        end))
    end

    if props.Options then
        UITemplates.CreateTipBoxes(Box :: any, props.Options)
    end
    local container = scope:New "Frame" {
        Name = "Holder",
        BackgroundTransparency = 1,
        Parent = props.Parent,

        LayoutOrder = props.Layout.LayoutOrder,
        Position = props.Layout.Position,
        AnchorPoint = props.Layout.AnchorPoint,
        ZIndex = props.Layout.ZIndex,
        Size = props.Layout.Size or UDim2.new(1, 0, 0, 30),
        AutomaticSize = props.Layout.AutomaticSize,

        [Out "AbsoluteSize"] = holder_size,

        [Children] = {
            scope:New "UIListLayout" {
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
            },
            scope:New "TextLabel" {
                Name = "Label",
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = props.Label.Text,
                FontFace = THEME.font_regular,
                TextColor3 = props.Label.TextColor3 or THEME.COLORS.MainText,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextScaled = props.Label.TextScaled,
                TextSize = 24,
                TextStrokeTransparency = 0,
                TextStrokeColor3 = THEME.COLORS.MainBackground,
                ClipsDescendants = true,
                LayoutOrder = 1,
                [Children] = {
                    scope:New "UIFlexItem" { FlexMode = Enum.UIFlexMode.Shrink }
                },
            },
            Box,
        },
    } :: Frame
    holder_size:set(container.AbsoluteSize)


    return container
end

return TextBox
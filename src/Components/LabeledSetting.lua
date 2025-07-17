local PluginSettings = require(script.Parent.Parent.Modules.PluginSettings)
local Fusion = require(script.Parent.Parent.Packages.fusion)

type UsedAs<T> = Fusion.UsedAs<T>

local function Divider(
    scope: Fusion.Scope<typeof(Fusion)>,
    props: {
        Setting: string,
        Parent: UsedAs<Instance>?,
        Layout: {
            LayoutOrder: UsedAs<number>?,
            Position: UsedAs<UDim2>?,
            AnchorPoint: UsedAs<Vector2>?,
            ZIndex: UsedAs<number>?,
            Size: UsedAs<UDim2>?,
            AutomaticSize: UsedAs<Enum.AutomaticSize>?,
        }?,
    }
): Fusion.Child
    local scope = scope:innerScope({
        CheckBox = require(script.Parent.Checkbox),
        TextBox = require(script.Parent.TextBox),
    })
    local setting = PluginSettings.Info[props.Setting]
    local value = PluginSettings.Values[props.Setting]
    if setting.Type == "boolean" then
        return scope:CheckBox {
            Label = setting.Name,
            Parent = props.Parent,
            Checked = value,
            Layout = props.Layout,
        }
    else
        return scope:TextBox {
            Parent = props.Parent,
            Text = value,
            PlaceholderText = scope:Computed(function()
                return if setting.Options
                    then table.concat(setting.Options, "/")
                    elseif setting.Default and setting.Default ~= "" then `{setting.Default} [{setting.Type}]`
                    else setting.Type
            end),
            onTextChange = function(text: string)
                value:set(text)
            end,
            Layout = props.Layout,
            Options = setting.Options,
            Label = {
                Text = setting.Name,
            }
        }
    end
end

return Divider
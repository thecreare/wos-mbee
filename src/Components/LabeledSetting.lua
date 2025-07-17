local PluginSettings = require(script.Parent.Parent.Modules.PluginSettings)
local Fusion = require(script.Parent.Parent.Packages.fusion)

type UsedAs<T> = Fusion.UsedAs<T>

local function Divider(
    scope: Fusion.Scope<typeof(Fusion)>,
    props: {
        Setting: PluginSettings.Setting,
        PluginSettingValues: {[string]: Fusion.Value<any>},
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
    local setting = props.Setting
    if setting.Type == "boolean" then
        return scope:CheckBox {
            Label = setting.Name,
            Parent = props.Parent,
            Checked = props.PluginSettingValues[setting.Key],
            Layout = props.Layout,
        }
    else
        return scope:TextBox {
            Parent = props.Parent,
            Text = props.PluginSettingValues[setting.Key],
            PlaceholderText = scope:Computed(function()
                return if setting.Options
                    then table.concat(setting.Options, "/")
                    else "Input..."
            end),
            Layout = props.Layout,
            Options = setting.Options,
            Label = {
                Text = setting.Name,
            }
        }
    end
end

return Divider
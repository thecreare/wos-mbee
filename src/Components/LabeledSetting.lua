local Selection = game:GetService("Selection")

local AllParts = require(script.Parent.Parent.Modules.AllParts)
local ExtractedUtil = require(script.Parent.Parent.Modules.ExtractedUtil)
local PluginSettings = require(script.Parent.Parent.Modules.PluginSettings)
local UITemplates = require(script.Parent.Parent.Modules.UITemplates).UITemplates
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
): Fusion.Child?
    local setting = PluginSettings.Info[props.Setting]
    local value = PluginSettings.Values[props.Setting]
    if setting.Visible == false then
        return
    end
    local scope = scope:innerScope({
        CheckBox = require(script.Parent.Checkbox),
        TextBox = require(script.Parent.TextBox),
    })
    if setting.Type == "boolean" then
        return scope:CheckBox {
            Label = setting.Name,
            Parent = props.Parent,
            Checked = value,
            Layout = props.Layout,
        }
    else
        local box = scope:TextBox {
            Parent = props.Parent,
            Text = value,
            PlaceholderText = scope:Computed(function()
                return if setting.Options
                    then table.concat(setting.Options, "/")
                    elseif setting.Default and setting.Default ~= "" then `{setting.Default} [{setting.Type}]`
                    elseif setting.Type == "Resource" then `Resource [string]`
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
        -- This should probably be moved into a thing somewhere else, like in the place
        -- where settings are defined
        if setting.Type == "Resource" then
            UITemplates.ConnectBoxToAutocomplete((box :: any):FindFirstChildOfClass("TextBox"), AllParts:GetBasePartList()).Event:Connect(function(Matched)
                if #Matched > 16 then return end
                if Matched[1] == nil then return end
                ExtractedUtil.ApplyTemplates(Selection:Get(), Matched[1])
            end)
        end
        return box
    end
end

return Divider
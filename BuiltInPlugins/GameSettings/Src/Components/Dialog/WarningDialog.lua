--[[
	A dialog that displays a warning image and message.
	Used with the showDialog function.

	Props:
		string Header = The header text to display at the top of this Dialog.
		string Description = The main message to display in this Dialog.
		table Buttons = {string cancelButtonName, string confirmButtonName}
]]
local FFlagGameSettingsWithContext = game:GetFastFlag("GameSettingsWithContext")
local FFlagFixWarningDialogIcon = game:GetFastFlag("FixWarningDialogIcon")

local Plugin = script.Parent.Parent.Parent.Parent
local Roact = require(Plugin.Roact)
local Cryo = require(Plugin.Cryo)

local Framework = require(Plugin.Framework)
local LayoutOrderIterator = Framework.Util.LayoutOrderIterator

local ContextServices = require(Plugin.Framework).ContextServices
local withContext = ContextServices.withContext

local DEPRECATED_Constants = require(Plugin.Src.Util.DEPRECATED_Constants)

local BaseDialog = require(Plugin.Src.Components.Dialog.BaseDialog)

local WarningDialog = Roact.PureComponent:extend("WarningDialog")

function WarningDialog:render()
	local props = self.props

	local theme = props.Theme:get("Plugin")

	local buttons = props.Buttons
	local header = props.Header
	local description = props.Description
	local layoutOrder = LayoutOrderIterator.new(-2)

	return Roact.createElement(BaseDialog, {
		Buttons = buttons,
		OnResult = props.OnResult,
	}, {

		Warning = not FFlagFixWarningDialogIcon and Roact.createElement("ImageLabel", {
			Image = DEPRECATED_Constants.WARNING_IMAGE,
			BackgroundTransparency = 1,
			LayoutOrder = layoutOrder:getNextOrder(),
			Size = UDim2.new(0, 16, 0, 16),
			Position = UDim2.new(0, 30, 0, 68),
		}),

		Header = FFlagFixWarningDialogIcon and Roact.createElement("TextLabel", Cryo.Dictionary.join(theme.fontStyle.Title, {
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, theme.warningDialog.headerOffset, 0, 0),
			AnchorPoint = Vector2.new(0.5, 0),
			LayoutOrder = layoutOrder:getNextOrder(),
			BackgroundTransparency = 1,
			Text = header,
			TextXAlignment = Enum.TextXAlignment.Left,
		})) or Roact.createElement("TextLabel", Cryo.Dictionary.join(theme.fontStyle.Title, {
			Size = UDim2.new(1, -60, 0, 23),
			AnchorPoint = Vector2.new(0.5, 0),
			LayoutOrder = layoutOrder:getNextOrder(),
			Position = UDim2.new(0.5, 0, 0, 30),
			BackgroundTransparency = 1,
			Text = header,
			TextXAlignment = Enum.TextXAlignment.Left,
		})),

		WarningDescription = FFlagFixWarningDialogIcon and Roact.createElement("Frame", {
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = layoutOrder:getNextOrder(),
		}, {
			UILayout = Roact.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, theme.dialog.spacing),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			Warning = Roact.createElement("ImageLabel", {
				Image = DEPRECATED_Constants.WARNING_IMAGE,
				LayoutOrder = layoutOrder:getNextOrder(),
				BackgroundTransparency = 1,
				Size = UDim2.new(0, theme.warningDialog.icon.size, 0, theme.warningDialog.icon.size),
			}),

			Description = Roact.createElement("TextLabel", Cryo.Dictionary.join(theme.fontStyle.Warning, {
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = layoutOrder:getNextOrder(),
				Size = UDim2.new(0, theme.warningDialog.description.length, 0, 0),
				BackgroundTransparency = 1,
				Text = description,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
			})),
		}),

		Description = not FFlagFixWarningDialogIcon and Roact.createElement("TextLabel", Cryo.Dictionary.join(theme.fontStyle.Warning, {
			Size = UDim2.new(0, 387, 0, 40),
			Position = UDim2.new(0, 56, 0, 65),
			BackgroundTransparency = 1,
			LayoutOrder = layoutOrder:getNextOrder(),
			Text = description,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
		})),
	})
end

if FFlagGameSettingsWithContext then
	WarningDialog = withContext({
		Theme = ContextServices.Theme,
	})(WarningDialog)
else
	ContextServices.mapToProps(WarningDialog, {
		Theme = ContextServices.Theme,
	})
end


return WarningDialog

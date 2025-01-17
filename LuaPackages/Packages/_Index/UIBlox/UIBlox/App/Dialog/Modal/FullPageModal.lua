--!nonstrict
local ModalRoot = script.Parent
local DialogRoot = ModalRoot.Parent
local AppRoot = DialogRoot.Parent
local UIBlox = AppRoot.Parent
local Packages = UIBlox.Parent

local Roact = require(Packages.Roact)
local t = require(Packages.t)

local FitFrame = require(Packages.FitFrame)
local FitFrameVertical = FitFrame.FitFrameVertical

local ButtonStack = require(AppRoot.Button.ButtonStack)

local ModalTitle = require(ModalRoot.ModalTitle)
local ModalWindow = require(ModalRoot.ModalWindow)

local FullPageModal = Roact.PureComponent:extend("FullPageModal")

local MARGIN = 24

FullPageModal.validateProps = t.strictInterface({
	-- Size of the container housing the `Modal`. This is necessary to dynamically scale the modal's width
	screenSize = t.Vector2,
	[Roact.Children] = t.table,

	-- Position of `Modal` in the whole page. Depending on the screensize that houses it, the position and anchor of the modal will change.
	-- If the width is less than the max size of the `Modal` (540px), then it will be anchored at the bottom of the screen, otherwise it will be positioned at the center.
	-- This is just for the ease of seeing the final state of the window, the window should be animated in and out.
	position = t.optional(t.UDim2),
	-- Title text of the `Modal`. Title can be a maximum of 2 lines long before it is cut off
	title = t.optional(t.string),
	-- Used to set the left/right margin's of the middle content in the modal
	marginSize = t.optional(t.number),
	-- Button stack validates the contents.
	-- See [ButtonStack](../Button/ButtonStack.md) for more information.
	buttonStackProps = t.optional(t.table),
	-- A function that is called when the X button in the Title has been clicked
	onCloseClicked = t.optional(t.callback),
	-- The modal does not inherently account for safe zone areas at the top, such as device-specific status bars.
	-- This value repositions the top of the modal by this pixel value from the top of the screen.
	distanceFromTop = t.optional(t.number),
})

FullPageModal.defaultProps = {
	marginSize = 24,
	distanceFromTop = 0,
}

function FullPageModal:init()
	self.state = {
		buttonFrameSize = Vector2.new(0, 0),
	}

	self.changeButtonFrameSize = function(rbx)
		if self.state.buttonFrameSize ~= rbx.AbsoluteSize then
			self:setState({
				buttonFrameSize = rbx.AbsoluteSize,
			})
		end
	end
end

function FullPageModal:render()
	return Roact.createElement(ModalWindow, {
		isFullHeight = true,
		screenSize = self.props.screenSize,
		position = self.props.position,
		distanceFromTop = self.props.distanceFromTop,
	}, {
		TitleContainer = Roact.createElement(ModalTitle, {
			title = self.props.title,
			onCloseClicked = self.props.onCloseClicked,
		}),
		Content = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, -ModalTitle:GetHeight()),
			Position = UDim2.new(0, 0, 0, ModalTitle:GetHeight()),
			BackgroundTransparency = 1,
		}, {
			Roact.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),
			Roact.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 0),
				PaddingRight = UDim.new(0, 0),
				PaddingBottom = UDim.new(0, MARGIN),
			}),
			MiddleContent = Roact.createElement("Frame", {
				Size = UDim2.new(1, -2 * self.props.marginSize, 1, -self.state.buttonFrameSize.Y),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, self.props[Roact.Children]),
			Buttons = self.props.buttonStackProps and Roact.createElement(FitFrameVertical, {
				BackgroundTransparency = 1,
				width = UDim.new(1, 0),
				LayoutOrder = 2,
				[Roact.Change.AbsoluteSize] = self.changeButtonFrameSize,
			}, {
				Padding = Roact.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, MARGIN),
					PaddingRight = UDim.new(0, MARGIN),
				}),
				Roact.createElement(ButtonStack, self.props.buttonStackProps),
			}),
		}),
	})
end

return FullPageModal

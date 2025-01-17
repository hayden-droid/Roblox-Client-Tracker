--!nonstrict
local ButtonRoot = script.Parent
local AppRoot = ButtonRoot.Parent
local UIBlox = AppRoot.Parent
local Packages = UIBlox.Parent

local Roact = require(Packages.Roact)
local Cryo = require(Packages.Cryo)
local RoactGamepad = require(Packages.RoactGamepad)
local t = require(Packages.t)

local AlertButton = require(ButtonRoot.AlertButton)
local PrimaryContextualButton = require(ButtonRoot.PrimaryContextualButton)
local PrimarySystemButton = require(ButtonRoot.PrimarySystemButton)
local SecondaryButton = require(ButtonRoot.SecondaryButton)
local GetTextSize = require(UIBlox.Core.Text.GetTextSize)
local withStyle = require(UIBlox.Core.Style.withStyle)

local enumerateValidator = require(UIBlox.Utility.enumerateValidator)
local validateButtonProps = require(ButtonRoot.validateButtonProps)

local FitFrame = require(Packages.FitFrame)
local FitFrameOnAxis = FitFrame.FitFrameOnAxis

local ButtonType = require(ButtonRoot.Enum.ButtonType)

local ButtonStack = Roact.PureComponent:extend("ButtonStack")

ButtonStack.validateProps = t.strictInterface({
	-- A table of button tables that contain props that PrimaryContextualButton,
	-- AlertButton, PrimarySystemButton, or SecondaryButton allow.
	buttons = t.array(t.strictInterface({
		-- Determines which button to use
		buttonType = t.optional(enumerateValidator(ButtonType)),
		props = validateButtonProps,
		-- Default gamepad focus to this button if true.
		isDefaultChild = t.optional(t.boolean),
	})),

	buttonHeight = t.optional(t.numberMin(0)),

	-- What fill direction to force into. If nil, then the fillDirection
	-- will be Vertical and automatically change to Horizontal if any button's text is
	-- too long.
	forcedFillDirection = t.optional(t.enum(Enum.FillDirection)),

	-- marginBetween: the margin between each button.
	marginBetween = t.optional(t.numberMin(0)),

	-- The minimum left and right padding used to calculate
	-- the when the button text overflows and automatically changes fillDirection.
	-- The overflow calculation will be if the length of the button text is over
	-- the button size - (2 * minHorizontalButtonPadding).
	minHorizontalButtonPadding = t.optional(t.numberMin(0)),

	-- optional parameters for RoactGamepad
	NextSelectionLeft = t.optional(t.table),
	NextSelectionRight = t.optional(t.table),
	NextSelectionUp = t.optional(t.table),
	NextSelectionDown = t.optional(t.table),
	frameRef = t.optional(t.table),
})

ButtonStack.defaultProps = {
	buttonHeight = 36,
	marginBetween = 12,
	minHorizontalButtonPadding = 8,
}

function ButtonStack:init()
	self.buttonRefs = RoactGamepad.createRefCache()

	self.state = {
		frameWidth = 0,
	}

	self.updateFrameSize = function(rbx)
		local frameWidth = rbx.AbsoluteSize.X
		if frameWidth ~= self.state.frameWidth then
			self:setState({
				frameWidth = frameWidth,
			})
		end
	end
end

function ButtonStack:render()
	return withStyle(function(stylePalette)
		local font = stylePalette.Font
		local textSize = font.Body.RelativeSize * font.BaseSize

		local buttons = self.props.buttons
		local paddingBetween = #buttons > 1 and self.props.marginBetween or 0
		local nonStackedButtonWidth = (self.state.frameWidth / #buttons) - (paddingBetween * (#buttons - 1) / #buttons)

		local isButtonStacked = false
		local fillDirection
		local defaultChildIndex
		if self.props.forcedFillDirection then
			isButtonStacked = self.props.forcedFillDirection == Enum.FillDirection.Vertical
			fillDirection = self.props.forcedFillDirection
		else
			for _, button in ipairs(buttons) do
				local buttonTextWidth = GetTextSize(
					button.props.text or "",
					textSize,
					font.Body.Font,
					Vector2.new(self.state.frameWidth, self.props.buttonHeight)
				)
				if buttonTextWidth.X > (nonStackedButtonWidth - (2 * self.props.minHorizontalButtonPadding)) then
					isButtonStacked = true
					break
				end
			end
			fillDirection = isButtonStacked and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
		end

		local buttonSize = isButtonStacked and UDim2.new(1, 0, 0, self.props.buttonHeight)
			or UDim2.new(0, nonStackedButtonWidth, 0, self.props.buttonHeight)

		local buttonTable = {}
		for colIndex, button in ipairs(buttons) do
			local newProps = {
				key = tostring(colIndex),
				layoutOrder = isButtonStacked and (#buttons - colIndex) or colIndex,
				size = buttonSize,
			}
			local buttonProps = Cryo.Dictionary.join(newProps, button.props)

			local buttonComponent
			if button.buttonType == ButtonType.PrimaryContextual then
				buttonComponent = PrimaryContextualButton
			elseif button.buttonType == ButtonType.PrimarySystem then
				buttonComponent = PrimarySystemButton
			elseif button.buttonType == ButtonType.Alert then
				buttonComponent = AlertButton
			else
				buttonComponent = SecondaryButton
			end

			if button.isDefaultChild then
				defaultChildIndex = colIndex
			end

			local gamepadProps = {
				[Roact.Ref] = self.buttonRefs[colIndex],
				NextSelectionUp = (isButtonStacked and colIndex > 1) and self.buttonRefs[colIndex - 1] or nil,
				NextSelectionDown = (isButtonStacked and colIndex < #buttons) and self.buttonRefs[colIndex + 1] or nil,
				NextSelectionLeft = (not isButtonStacked and colIndex > 1) and self.buttonRefs[colIndex - 1] or nil,
				NextSelectionRight = (not isButtonStacked and colIndex < #buttons) and self.buttonRefs[colIndex + 1]
					or nil,
			}
			local buttonPropsWithGamepad = Cryo.Dictionary.join(buttonProps, gamepadProps)
			table.insert(buttonTable, Roact.createElement(buttonComponent, buttonPropsWithGamepad))
		end

		return Roact.createElement(RoactGamepad.Focusable[FitFrameOnAxis], {
			BackgroundTransparency = 1,
			contentPadding = UDim.new(0, paddingBetween),
			FillDirection = fillDirection,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			LayoutOrder = 3,
			minimumSize = UDim2.new(1, 0, 0, self.props.buttonHeight),
			[Roact.Ref] = self.props.frameRef,
			[Roact.Change.AbsoluteSize] = self.updateFrameSize,

			NextSelectionLeft = self.props.NextSelectionLeft,
			NextSelectionRight = self.props.NextSelectionRight,
			NextSelectionUp = self.props.NextSelectionUp,
			NextSelectionDown = self.props.NextSelectionDown,
			defaultChild = defaultChildIndex and self.buttonRefs[defaultChildIndex] or nil,
		}, buttonTable)
	end)
end

local ButtonStackForwardRef = Roact.forwardRef(function(props, ref)
	return Roact.createElement(ButtonStack, Cryo.Dictionary.join(props, { frameRef = ref }))
end)

-- Include validateProps on forward ref so other components can use it for validation
ButtonStackForwardRef.validateProps = ButtonStack.validateProps

return ButtonStackForwardRef

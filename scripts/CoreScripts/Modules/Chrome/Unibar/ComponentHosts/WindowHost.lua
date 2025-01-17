local CorePackages = game:GetService("CorePackages")
local React = require(CorePackages.Packages.React)
local ReactRoblox = require(CorePackages.Packages.ReactRoblox)
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local ReactOtter = require(CorePackages.Packages.ReactOtter)

local UIBlox = require(CorePackages.UIBlox)
local Images = UIBlox.App.ImageSet.Images
local IconButton = UIBlox.App.Button.IconButton
local useStyle = UIBlox.Core.Style.useStyle

local ChromeService = require(script.Parent.Parent.Parent.Service)
local Constants = require(script.Parent.Parent.Parent.Unibar.Constants)
local ChromeTypes = require(script.Parent.Parent.Parent.Service.Types)

local useWindowSize = require(script.Parent.Parent.Parent.Hooks.useWindowSize)

local CLOSE_ICON = Images["icons/navigation/close_small"]

export type WindowHostProps = {
	integration: ChromeTypes.IntegrationComponentProps,
	position: UDim2?,
}

local ICON_SIZE = 42
local MOTOR_OPTIONS = {
	dampingRatio = 1,
	frequency = 3,
}

local WindowHost = function(props: WindowHostProps)
	local style = useStyle()
	local theme = style.Theme
	local backgroundPress = theme.BackgroundOnPress

	local windowSize = useWindowSize(props.integration.integration)
	local windowRef: { current: Frame? } = React.useRef(nil)
	local connection: { current: RBXScriptConnection? } = React.useRef(nil)
	local overlayTask: { current: thread? } = React.useRef(nil)

	local isActive, setActive = React.useBinding(false)

	-- Account for 0,0 and frame size when positioning
	local position = React.useMemo(function()
		-- If position has already been set, return existing position
		if windowRef and windowRef.current then
			return windowRef.current.Position
		end

		local defaultPosition: UDim2 = props.position or UDim2.new()

		return UDim2.new(1, defaultPosition.X.Offset - windowSize.X.Offset, 0, defaultPosition.Y.Offset)
	end)

	-- When a reposition tween is playing, momentarily disallow dragging the window
	local isRepositioning, updateIsRepositioning = React.useBinding(false)

	local frameWidth, setFrameWidth = ReactOtter.useAnimatedBinding(windowSize.X.Offset)
	local frameHeight, setFrameHeight = ReactOtter.useAnimatedBinding(windowSize.Y.Offset)

	React.useEffect(function()
		setFrameWidth(ReactOtter.spring(windowSize.X.Offset, MOTOR_OPTIONS))
	end, { windowSize.X.Offset })

	React.useEffect(function()
		setFrameHeight(ReactOtter.spring(windowSize.Y.Offset, MOTOR_OPTIONS))
	end, { windowSize.Y.Offset })

	-- This effect determines whether the window was opened as a result of a drag from IconHost
	-- when a connection is active drive the window frame position with the input object and
	-- adjust the size of the window to expand as if it was scaling up from the icon
	React.useEffect(function()
		local storedConnection = ChromeService:dragConnection(props.integration.id)

		if storedConnection ~= nil then
			connection = storedConnection

			assert(windowRef.current ~= nil)
			assert(windowRef.current.Parent ~= nil)

			if connection then
				local frame = windowRef.current
				local frameParent = windowRef.current.Parent :: ScreenGui
				local parentScreenSize = frameParent.AbsoluteSize

				setFrameWidth(ReactOtter.instant(ICON_SIZE) :: any)
				setFrameHeight(ReactOtter.instant(ICON_SIZE) :: any)

				task.defer(setFrameWidth, ReactOtter.spring(windowSize.X.Offset, MOTOR_OPTIONS))
				task.defer(setFrameHeight, ReactOtter.spring(windowSize.Y.Offset, MOTOR_OPTIONS))

				local frameStartPosition =
					Vector3.new(windowRef.current.AbsolutePosition.X, windowRef.current.AbsolutePosition.Y, 0)
				local dragStartPosition = frameStartPosition

				connection.current = UserInputService.InputChanged:Connect(function(inputChangedObj: InputObject, _)
					local inputPosition = inputChangedObj.Position

					local delta = inputPosition - dragStartPosition
					local newPosition = {
						X = math.clamp((delta + frameStartPosition).X, 0, parentScreenSize.X),
						Y = math.clamp((delta + frameStartPosition).Y, 0, parentScreenSize.Y),
					}

					frame.Position = UDim2.fromOffset(newPosition.X, newPosition.Y)
				end)
			end
		end
	end, {})

	local touchBegan = React.useCallback(function(_: Frame, inputObj: InputObject)
		assert(windowRef.current ~= nil)
		assert(windowRef.current.Parent ~= nil)

		local frame = windowRef.current
		local frameParent = windowRef.current.Parent :: ScreenGui
		local parentScreenSize = frameParent.AbsoluteSize

		local frameHalfWidth = frameWidth:getValue() / 2
		local frameHalfHeight = frameHeight:getValue() / 2

		-- Input Objects are reused across different connections
		-- therefore cache the value of the start position
		local dragStartPosition = inputObj.Position
		local frameStartPosition = Vector3.new(
			windowRef.current.AbsolutePosition.X + frameHalfWidth,
			windowRef.current.AbsolutePosition.Y + frameHalfHeight,
			0
		)

		if
			inputObj.UserInputType == Enum.UserInputType.MouseButton1
			or inputObj.UserInputType == Enum.UserInputType.Touch
		then
			-- Set window active, cancel any tasks to turn off overlay
			setActive(true)
			if overlayTask.current then
				task.cancel(overlayTask.current)
			end

			-- Handle dragging
			if not connection.current and not isRepositioning:getValue() then
				-- The dragging callback might never be called when a single tap is registered
				-- Assign the position to the frame ref itself to ensure we have the most current
				local newPosition = {
					X = math.clamp((frameStartPosition).X, 0, parentScreenSize.X - frameHalfWidth),
					Y = math.clamp((frameStartPosition).Y, 0, parentScreenSize.Y - frameHalfHeight),
				}
				frame.Position = UDim2.fromOffset(newPosition.X, newPosition.Y)
				connection.current = UserInputService.InputChanged:Connect(function(inputChangedObj: InputObject, _)
					local inputPosition = inputChangedObj.Position
					local delta = inputPosition - dragStartPosition
					local newPosition = {
						X = math.clamp(
							(delta + frameStartPosition).X,
							frameHalfWidth,
							parentScreenSize.X - frameHalfWidth
						),
						Y = math.clamp(
							(delta + frameStartPosition).Y,
							frameHalfHeight,
							parentScreenSize.Y - frameHalfHeight
						),
					}
					frame.Position = UDim2.fromOffset(newPosition.X, newPosition.Y)
				end)
			end
		end
	end, {})

	-- When the drag ends and the window frame is clipped, reposition it within the screen bounds
	local repositionWindowWithinScreenBounds = React.useCallback(function()
		assert(windowRef.current ~= nil)
		assert(windowRef.current.Parent ~= nil)

		local frame = windowRef.current
		local frameParent = windowRef.current.Parent :: ScreenGui

		local frameHalfWidth = frameWidth:getValue() / 2
		local frameHalfHeight = frameHeight:getValue() / 2
		local parentScreenSize = frameParent.AbsoluteSize

		local xPosition = frame.Position.X.Offset
		local yPosition = frame.Position.Y.Offset

		if
			xPosition < frameHalfWidth
			or xPosition > parentScreenSize.X - frameHalfWidth
			or yPosition < frameHalfHeight
			or yPosition > parentScreenSize.Y - frameHalfHeight
		then
			updateIsRepositioning(true)

			local x = math.clamp(xPosition, frameHalfWidth, parentScreenSize.X - frameHalfWidth)
			local y = math.clamp(yPosition, frameHalfHeight, parentScreenSize.Y - frameHalfHeight)

			local positionTarget = UDim2.new(0, x, 0, y)

			local tweenStyle = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
			local positionTween = TweenService:Create(frame, tweenStyle, { Position = positionTarget })
			positionTween.Completed:Connect(function(_)
				updateIsRepositioning(false)
			end)
			positionTween:Play()
		end
	end, {})

	local touchEnded = React.useCallback(function(_: Frame, inputObj: InputObject)
		if
			inputObj.UserInputType == Enum.UserInputType.MouseButton1
			or inputObj.UserInputType == Enum.UserInputType.Touch
		then
			-- Spawn task to disable overlay after a timespan
			overlayTask.current = task.spawn(function()
				task.wait(Constants.WINDOW_ACTIVE_SECONDS)
				setActive(false)
			end)

			-- Handle dragging
			if connection.current then
				connection.current:Disconnect()
				connection.current = nil
				ChromeService:gesture(props.integration.id, nil)
				repositionWindowWithinScreenBounds()
			end
		end
	end, {})

	return ReactRoblox.createPortal({
		Name = React.createElement("ScreenGui", {
			Name = Constants.WINDOW_HOST_GUI_NAME .. ":" .. props.integration.id,
			-- TODO manage display ordering
			DisplayOrder = 100,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		}, {
			WindowFrame = React.createElement("Frame", {
				Size = React.joinBindings({ frameWidth, frameHeight }):map(function(sizes)
					return UDim2.fromOffset(sizes[1], sizes[2])
				end),
				LayoutOrder = 1,
				ref = windowRef,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = position,
				[React.Event.InputBegan] = touchBegan,
				[React.Event.InputEnded] = touchEnded,
			}, {
				WindowWrapper = React.createElement("Frame", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
				}, {
					Overlay = React.createElement("Frame", {
						Size = UDim2.new(1, 0, 1, 0),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(0.5, 0, 0.5, 0),
						BackgroundColor3 = backgroundPress.Color,
						BackgroundTransparency = backgroundPress.Transparency,
						BorderSizePixel = 0,
						Visible = isActive,
						ZIndex = 2,
					}, {
						Corner = React.createElement("UICorner", {
							CornerRadius = Constants.CORNER_RADIUS,
						}),
					}),
					CloseButtonWrapper = React.createElement("Frame", {
						Size = Constants.CLOSE_BUTTON_SIZE,
						BackgroundTransparency = 1,
						Visible = isActive,
						ZIndex = 3,
					}, {
						CloseButtonLayout = React.createElement("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							SortOrder = Enum.SortOrder.LayoutOrder,
							VerticalAlignment = Enum.VerticalAlignment.Center,
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
						}),
						CloseButton = React.createElement(IconButton, {
							icon = CLOSE_ICON,
							iconSize = Constants.CLOSE_ICON_SIZE,
							onActivated = function()
								ChromeService:toggleWindow(props.integration.id)
							end,
						}),
					}),
					Integration = props.integration.component(props) or nil,
				}),
			}),
		}),
	}, CoreGui)
end

return WindowHost

--!strict
local CoreGui = game:GetService("CoreGui")
local CorePackages = game:GetService("CorePackages")
local GuiService = game:GetService("GuiService")

local React = require(CorePackages.Packages.React)
local Cryo = require(CorePackages.Packages.Cryo)
local CallProtocol = require(CorePackages.Workspace.Packages.CallProtocol)

local RobloxGui = CoreGui:WaitForChild("RobloxGui")

local ContactList = RobloxGui.Modules.ContactList
local dependencies = require(ContactList.dependencies)
local SocialLibraries = dependencies.SocialLibraries
local UIBlox = dependencies.UIBlox
local RoduxCall = dependencies.RoduxCall
local getStandardSizeAvatarHeadShotRbxthumb = dependencies.getStandardSizeAvatarHeadShotRbxthumb
local FFlagLuaAppUnifyCodeToGenerateRbxThumb = dependencies.FFlagLuaAppUnifyCodeToGenerateRbxThumb

local Colors = UIBlox.App.Style.Colors
local ImageSetLabel = UIBlox.Core.ImageSet.Label
local useStyle = UIBlox.Core.Style.useStyle

local useSelector = dependencies.Hooks.useSelector

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local localUserId: number = localPlayer and localPlayer.UserId or 0

export type Props = {
	callProtocol: CallProtocol.CallProtocolModule | nil,
	size: Vector2,
	callBarRef: { current: GuiObject? } | nil,
}

local PROFILE_SIZE = 36
local BUTTON_SIZE = 36
local PADDING_TOP_BOTTOM = 4
local PADDING_LEFT_RIGHT = 4
local PADDING_IN_BETWEEN = 8

local defaultProps = {
	callProtocol = CallProtocol.CallProtocol.default,
}

local function getTextFromCallStatus(status)
	-- TODO (joshli): Need to translate these.
	if status == RoduxCall.Enums.Status.Connecting.rawValue() then
		return "Waiting…"
	elseif status == RoduxCall.Enums.Status.Teleporting.rawValue() then
		return "Teleporting…"
	elseif status == RoduxCall.Enums.Status.Active.rawValue() then
		return "Roblox Call"
	elseif status == RoduxCall.Enums.Status.Failed.rawValue() then
		return "Call Ended"
	else
		return "Error"
	end
end

local function CallBar(passedProps: Props)
	local props = Cryo.Dictionary.join(defaultProps, passedProps)

	local style = useStyle()
	local theme = style.Theme
	local font = style.Font

	local selectCallId = React.useCallback(function(state: any)
		return if state.Call.currentCall then state.Call.currentCall.callId else ""
	end)
	local callId = useSelector(selectCallId)

	local selectCallStatus = React.useCallback(function(state: any)
		return if state.Call.currentCall then state.Call.currentCall.status else ""
	end)
	local callStatus = useSelector(selectCallStatus)

	local selectOtherEndParticipant = React.useCallback(function(state: any)
		local currentCall = state.Call.currentCall
		if currentCall then
			if localUserId == currentCall.callerId then
				return { userId = currentCall.calleeId, displayName = currentCall.calleeDisplayName }
			else
				return { userId = currentCall.callerId, displayName = currentCall.callerDisplayName }
			end
		end

		return nil :: any
	end)
	local otherEndParticipant = useSelector(selectOtherEndParticipant)

	local image
	if otherEndParticipant then
		if FFlagLuaAppUnifyCodeToGenerateRbxThumb then
			image = getStandardSizeAvatarHeadShotRbxthumb(otherEndParticipant.userId)
		else
			image = SocialLibraries.User.getUserAvatarImage(otherEndParticipant.userId)
		end
	end

	local callStatusText = getTextFromCallStatus(callStatus)
	local showEndButton = callStatus == RoduxCall.Enums.Status.Active.rawValue()
		or callStatus == RoduxCall.Enums.Status.Connecting.rawValue()

	local endButtonCallback = React.useCallback(function()
		if callStatus == RoduxCall.Enums.Status.Active.rawValue() then
			props.callProtocol:finishCall(callId)
		elseif callStatus == RoduxCall.Enums.Status.Connecting.rawValue() then
			props.callProtocol:cancelCall(callId)
		end
	end, { callStatus, props.callProtocol })

	return React.createElement("Frame", {
		Size = UDim2.fromOffset(props.size.X, props.size.Y),
		Position = UDim2.new(0.5, 0, 0, -(props.size.Y + GuiService:GetGuiInset().Y)),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = theme.BackgroundMuted.Color,
		BackgroundTransparency = theme.BackgroundMuted.Transparency,
		BorderSizePixel = 0,
		ref = props.callBarRef,
	}, {
		UICorner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0.5, 0),
		}),

		UIListLayout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, PADDING_IN_BETWEEN),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),

		UIPadding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, PADDING_LEFT_RIGHT),
			PaddingTop = UDim.new(0, PADDING_TOP_BOTTOM),
			PaddingRight = UDim.new(0, PADDING_LEFT_RIGHT),
			PaddingBottom = UDim.new(0, PADDING_TOP_BOTTOM),
		}),

		ProfileImage = React.createElement(ImageSetLabel, {
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.fromOffset(PROFILE_SIZE, PROFILE_SIZE),
			Image = image,
			LayoutOrder = 1,
		}, {
			UICorner = React.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		}),

		Content = React.createElement("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, -(PROFILE_SIZE + (PADDING_IN_BETWEEN * 2) + BUTTON_SIZE), 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = 2,
		}, {
			UIListLayout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			DisplayName = React.createElement("TextLabel", {
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Font = font.CaptionHeader.Font,
				LayoutOrder = 1,
				LineHeight = 1.25,
				Text = if otherEndParticipant then otherEndParticipant.displayName else "",
				TextColor3 = theme.TextEmphasis.Color,
				TextSize = font.BaseSize * font.CaptionHeader.RelativeSize,
				TextTransparency = theme.TextEmphasis.Transparency,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			Details = React.createElement("Frame", {
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = 2,
			}, {
				UIPadding = React.createElement("UIPadding", {
					PaddingTop = UDim.new(0, 2),
				}),

				DetailsText = React.createElement("TextLabel", {
					AutomaticSize = Enum.AutomaticSize.XY,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Font = font.Footer.Font,
					LineHeight = 1.16667,
					Text = callStatusText,
					TextColor3 = Colors.White,
					TextSize = font.BaseSize * font.Footer.RelativeSize,
					TextTransparency = 0.4,
					TextTruncate = Enum.TextTruncate.AtEnd,
				}),
			}),
		}),

		EndButton = if showEndButton
			then React.createElement("ImageButton", {
				Position = UDim2.fromOffset(0, 0),
				AnchorPoint = Vector2.new(1, 1),
				LayoutOrder = 3,
				Size = UDim2.fromOffset(BUTTON_SIZE, BUTTON_SIZE),
				BackgroundTransparency = style.Theme.UIMuted.Transparency,
				BackgroundColor3 = style.Theme.UIMuted.Color,
				BorderSizePixel = 0,
				Image = "rbxassetid://12788429603",
				[React.Event.Activated] = endButtonCallback,
			}, {
				UICorner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, BUTTON_SIZE),
				}),
			})
			else nil,
	})
end

return CallBar

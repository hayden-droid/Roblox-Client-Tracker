--[[
	A bubble for showing controls to enable/disable the
	user's Microphone and Camera.
]]
local FaceAnimatorService = game:GetService("FaceAnimatorService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local ExperienceChat = script:FindFirstAncestor("ExperienceChat")
local Packages = ExperienceChat.Parent

local Roact = require(Packages.Roact)
local RoactRodux = require(Packages.RoactRodux)
local UIBlox = require(Packages.UIBlox)
local Dictionary = require(Packages.llama).Dictionary

local Images = UIBlox.App.ImageSet.Images
local ExternalEventConnection = UIBlox.Utility.ExternalEventConnection

local BubbleChat = script:FindFirstAncestor("BubbleChat")
local getVoiceIndicatorIcon = require(BubbleChat.Helpers.getVoiceIndicatorIcon)

local ControlBubble = require(script.Parent.ControlBubble)

local GetFFlagControlBubbleUpdates = require(ExperienceChat.Flags.GetFFlagControlBubbleUpdates)
local getSetUpBubbleChatConfigurationChildProperties =
	require(ExperienceChat.Flags.getSetUpBubbleChatConfigurationChildProperties)

local VIDEO_IMAGE = Images["icons/controls/video"]
local VIDEO_OFF_IMAGE = Images["icons/controls/videoOff"]
local MIC_OFF_IMAGE = Images["icons/controls/microphoneMute"]
local INCREMENT_AMOUNT = 20
local NUM_INCREMENTS = 5

local PlayerButtons = Roact.PureComponent:extend("PlayerButtons")

-- PlayerButtons.validateProps = t.strictInterface({
-- 	chatSettings = t.table,
-- 	isInsideMaximizeDistance = t.boolean,
-- 	isLocalPlayer = t.boolean,
-- 	userId = t.string,
-- 	LayoutOrder = t.optional(t.number),
-- 	getIcon = t.callback,
-- 	hasCameraPermissions = t.boolean,
-- 	hasMicPermissions = t.boolean,
-- 	onClickedVoiceIndicator = t.callback,
-- 	onClickedCameraIndicator = t.callback,
-- 	getPermissions = t.callback,
-- })

PlayerButtons.defaultProps = {
	LayoutOrder = 1,
}

function PlayerButtons:init()
	self:setState({
		cameraEnabled = if FaceAnimatorService
			then (FaceAnimatorService:IsStarted() and FaceAnimatorService.VideoAnimationEnabled)
			else false,
	})

	-- toggle mic permissions
	self.toggleMic = function()
		self.props.onClickedVoiceIndicator(self.props.userId)
	end

	-- toggle video permissions
	self.toggleVideo = function()
		self.props.onClickedCameraIndicator()
	end

	self.updateVideo = function()
		self:setState({
			cameraEnabled = FaceAnimatorService.VideoAnimationEnabled,
		})
	end

	-- TODO Pass this down from one of the more central components when the real level is available
	self.level, self.updateLevel = Roact.createBinding(0)
	self.voiceState, self.updateVoiceState = Roact.createBinding(self.props.voiceState)

	-- Generate a fake volume level for now
	self.renderStepName = HttpService:GenerateGUID()
	RunService:BindToRenderStep(self.renderStepName, 1, function()
		self.updateLevel(math.random())
	end)

	self.levelIcon = Roact.joinBindings({ self.voiceState, self.level }):map(function(values: { number & string })
		local voiceState: string = values[1]
		local level: number = values[2]

		local speakerIconStyle = if game:GetEngineFeature("VoiceChatNewSpeakerIcons")
			then "SpeakerNew"
			else "SpeakerDark"
		local iconStyle = if self.props.isLocalPlayer then "New" else speakerIconStyle

		if GetFFlagControlBubbleUpdates() then
			return getVoiceIndicatorIcon(self.props.getIcon, voiceState, level, iconStyle)
		else
			local getIcon = self.props.getIcon

			if getIcon then
				if voiceState == "Muted" or voiceState == "LOCAL_MUTED" then
					return getIcon("Muted", iconStyle)
				elseif voiceState == "Connecting" then
					return getIcon("Connecting", iconStyle)
				elseif voiceState == "Inactive" then
					return getIcon("Unmuted0", iconStyle)
				elseif voiceState == "Talking" then
					local roundedLevel = INCREMENT_AMOUNT * math.floor(0.5 + NUM_INCREMENTS * level)
					return getIcon("Unmuted" .. tostring(roundedLevel), iconStyle)
				else
					return getIcon("Error", iconStyle)
				end
			else
				return ""
			end
		end
	end)
end

function PlayerButtons:getMicIcon()
	if self.props.isLocalPlayer then
		local muted = self.props.voiceState == "Muted" or self.props.voiceState == "LOCAL_MUTED"
		if muted or not self.props.hasMicPermissions then
			return MIC_OFF_IMAGE
		end
	end

	return self.levelIcon
end

function PlayerButtons:shouldShowCameraIndicator()
	if self.props.isLocalPlayer and self.props.hasCameraPermissions then
		return true
	end

	return false
end

function PlayerButtons:render()
	local shouldShowVoiceIndicator = self.props.hasMicPermissions
	local shouldShowCameraIndicator = self:shouldShowCameraIndicator()
	local chatSettings = self.props.chatSettings
	local muted = self.props.voiceState == "Muted" or self.props.voiceState == "LOCAL_MUTED"
	local useImageSetMic = muted or not self.props.hasMicPermissions

	local containerProperties = {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	}
	if getSetUpBubbleChatConfigurationChildProperties() then
		containerProperties = Dictionary.join(chatSettings.ImageLabel, containerProperties)
	end

	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(0, 0, 0, 25),
		LayoutOrder = self.props.LayoutOrder,
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Visible = shouldShowVoiceIndicator or shouldShowCameraIndicator,
	}, {
		Scale = Roact.createElement("UIScale", {
			Scale = not self.props.isInsideMaximizeDistance and 0.75 or 1.0,
		}),
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
		Container = Roact.createElement(
			getSetUpBubbleChatConfigurationChildProperties() and "ImageLabel" or "Frame",
			containerProperties,
			{
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
				UIListLayout = Roact.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0, 2),
				}),
				UIPadding = Roact.createElement("UIPadding", {
					PaddingTop = UDim.new(0, 2),
					PaddingRight = UDim.new(0, 2),
					PaddingBottom = UDim.new(0, 2),
					PaddingLeft = UDim.new(0, 2),
				}),
				MicrophoneBubble = shouldShowVoiceIndicator and Roact.createElement(ControlBubble, {
					LayoutOrder = 1,
					icon = self.levelIcon,
					iconSize = if self.props.isLocalPlayer then UDim2.fromOffset(14, 18) else UDim2.fromOffset(23, 21),
					imageSetIcon = MIC_OFF_IMAGE,
					onActivated = self.toggleMic,
					isImageSet = useImageSetMic,
					chatSettings = chatSettings,
				}),
				CameraBubble = shouldShowCameraIndicator and Roact.createElement(ControlBubble, {
					LayoutOrder = 2,
					imageSetIcon = if self.state.cameraEnabled and self.props.hasCameraPermissions
						then VIDEO_IMAGE
						else VIDEO_OFF_IMAGE,
					onActivated = self.toggleVideo,
					isImageSet = true,
					chatSettings = chatSettings,
				}),
			}
		),
		Carat = chatSettings.TailVisible and Roact.createElement("ImageLabel", {
			LayoutOrder = 3,
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 1, -1),
			Size = UDim2.fromOffset(12, 8),
			Image = "rbxasset://textures/ui/InGameChat/Caret.png",
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		}),
		VideoEnabledChanged = FaceAnimatorService and Roact.createElement(ExternalEventConnection, {
			event = FaceAnimatorService:GetPropertyChangedSignal("VideoAnimationEnabled"),
			callback = self.updateVideo,
		}) or nil,
	})
end

function PlayerButtons:didUpdate(previousProps, _previousState)
	if previousProps.voiceState ~= self.props.voiceState then
		self.updateVoiceState(self.props.voiceState)
	end
end

function PlayerButtons:didMount()
	self.updateVoiceState(self.props.voiceState)
end

function PlayerButtons:willUnmount()
	pcall(function()
		RunService:UnbindFromRenderStep(self.renderStepName)
	end)
end

local function mapStateToProps(state, props)
	return {
		voiceState = state.Voice.participants[props.userId],
	}
end

return RoactRodux.connect(mapStateToProps)(PlayerButtons)

--!nonstrict
--[[
		Filename: Players.lua
		Written by: Stickmasterluke
		Version 1.0
		Description: Player list inside escape menu, with friend adding functionality.
--]]
-------------- SERVICES --------------
local CoreGui = game:GetService("CoreGui")
local CorePackages = game:GetService("CorePackages")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local GuiService = game:GetService("GuiService")
local PlayersService = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local AnalyticsService = game:GetService("RbxAnalyticsService")
local RunService = game:GetService("RunService")
local VoiceChatServiceManager = require(RobloxGui.Modules.VoiceChat.VoiceChatServiceManager).default

----------- UTILITIES --------------
local CoreGuiModules = RobloxGui:WaitForChild("Modules")
CoreGuiModules:WaitForChild("TenFootInterface")
local ShareGameDirectory = CoreGui.RobloxGui.Modules.Settings.Pages.ShareGame
local ApolloClient = require(CoreGui.RobloxGui.Modules.ApolloClient)
local UserProfiles = require(CorePackages.Workspace.Packages.UserProfiles)
local formatUsername = UserProfiles.Formatters.formatUsername
local getCombinedNameFromId = UserProfiles.Selectors.getCombinedNameFromId
local Cryo = require(CorePackages.Cryo)

local utility = require(RobloxGui.Modules.Settings.Utility)

local reportAbuseMenu = require(RobloxGui.Modules.Settings.Pages.ReportAbuseMenu)
local SocialUtil = require(RobloxGui.Modules:WaitForChild("SocialUtil"))
local Diag = require(CorePackages.Workspace.Packages.Analytics).AnalyticsReporters.Diag
local EventStream = require(CorePackages.AppTempCommon.Temp.EventStream)
local ShareGameIcons = require(ShareGameDirectory.Spritesheets.ShareGameIcons)
local isTenFootInterface = require(RobloxGui.Modules.TenFootInterface):IsEnabled()
local RobloxTranslator = require(RobloxGui.Modules.RobloxTranslator)
local InviteToGameAnalytics = require(ShareGameDirectory.Analytics.InviteToGameAnalytics)
local onBlockButtonActivated = require(script:FindFirstAncestor("Settings").onBlockButtonActivated)
local VoiceAnalytics = require(script:FindFirstAncestor("Settings").Analytics.VoiceAnalytics)
local BlockingAnalytics = require(script:FindFirstAncestor("Settings").Analytics.BlockingAnalytics)
local BlockingUtility = require(RobloxGui.Modules.BlockingUtility)
local log = require(RobloxGui.Modules.Logger):new(script.Name)

------------ Constants -------------------
local Theme = require(script.Parent.Parent.Theme)

local Constants = require(RobloxGui.Modules:WaitForChild("InGameMenu"):WaitForChild("Resources"):WaitForChild("Constants"))

local FRAME_DEFAULT_TRANSPARENCY = .85
local FRAME_SELECTED_TRANSPARENCY = .65
local REPORT_PLAYER_IMAGE = isTenFootInterface and "rbxasset://textures/ui/Settings/Players/ReportFlagIcon@2x.png" or "rbxasset://textures/ui/Settings/Players/ReportFlagIcon.png"
local ADD_FRIEND_IMAGE = isTenFootInterface and "rbxasset://textures/ui/Settings/Players/AddFriendIcon@2x.png" or "rbxasset://textures/ui/Settings/Players/AddFriendIcon.png"
local FRIEND_IMAGE = isTenFootInterface and "rbxasset://textures/ui/Settings/Players/FriendIcon@2x.png" or "rbxasset://textures/ui/Settings/Players/FriendIcon.png"
local INSPECT_IMAGE = "rbxasset://textures/ui/InspectMenu/ico_inspect.png"
local BLOCK_IMAGE = isTenFootInterface and "rbxasset://textures/ui/Settings/Players/BlockIcon@2x.png" or "rbxasset://textures/ui/Settings/Players/BlockIcon.png"

if Theme.UIBloxThemeEnabled then
	REPORT_PLAYER_IMAGE = Theme.Images["icons/actions/feedback"]
	INSPECT_IMAGE = Theme.Images["icons/actions/zoomIn"]
	BLOCK_IMAGE = Theme.Images["icons/actions/block"]
	ADD_FRIEND_IMAGE = Theme.Images["icons/actions/friends/friendAdd"]
	FRIEND_IMAGE = Theme.Images["icons/menu/friends"]
end

local MuteStatusIcons = {
	MicOn = "rbxasset://textures/ui/Settings/Players/Unmute@2x.png",
	MicOff = "rbxasset://textures/ui/Settings/Players/Muted@2x.png",
	MicDisabled = "rbxasset://textures/ui/Settings/Players/Blocked@2x.png",
	Loading = "rbxasset://textures/ui/Settings/Players/Unmuted-White@2x.png",
	Error = VoiceChatServiceManager:GetIcon("Error", "MicLight"),
}

local PlayerMuteStatusIcons = MuteStatusIcons

local PLAYER_ROW_HEIGHT = 62
local PLAYER_ROW_HEIGHT_PORTRAIT = 105
local PLAYER_ROW_SPACING = 80
local PLAYER_ROW_SPACING_PORTRAIT = PLAYER_ROW_HEIGHT_PORTRAIT + PLAYER_ROW_SPACING - PLAYER_ROW_HEIGHT
local PLAYER_NAME_RIGHT_PADDING = 20
local BUTTON_ROW_HEIGHT = PLAYER_ROW_HEIGHT
local USERNAME_POSITION = 0.5
local USERNAME_POSITION_PORTRAIT = 0.275
local RIGHT_SIDE_BUTTON_PAD = -4

if Theme.UIBloxThemeEnabled then
	RIGHT_SIDE_BUTTON_PAD = -12
	BUTTON_ROW_HEIGHT = 52
end

local FULL_SIZE_SHARE_GAME_BUTTON_SIZE = UDim2.new(1, -10, 0, BUTTON_ROW_HEIGHT)
local HALF_SIZE_SHARE_GAME_BUTTON_SIZE = UDim2.new(0.5, -10, 0, BUTTON_ROW_HEIGHT)

------------ Variables -------------------
local platform = UserInputService:GetPlatform()
local PageInstance = nil
local localPlayer = PlayersService.LocalPlayer
while not localPlayer do
	PlayersService.ChildAdded:wait()
	localPlayer = PlayersService.LocalPlayer
end

------------ FAST FLAGS -------------------
local success, result = pcall(function() return settings():GetFFlag('UseNotificationsLocalization') end)
local FFlagUseNotificationsLocalization = success and result
local FFlagExtendedExpMenuPortraitLayout = require(RobloxGui.Modules.Flags.FFlagExtendedExpMenuPortraitLayout)
local getFFlagEnableVoiceChatPlayersList = require(RobloxGui.Modules.Flags.GetFFlagEnableVoiceChatPlayersList)
local getFFlagPlayerListApolloClientEnabled = require(RobloxGui.Modules.Flags.getFFlagPlayerListApolloClientEnabled)
local getIsUserProfileOnPlayersListEnabled = require(RobloxGui.Modules.Flags.getIsUserProfileOnPlayersListEnabled)
local GetFFlagVoiceChatUILogging = require(RobloxGui.Modules.Flags.GetFFlagVoiceChatUILogging)
local GetFFlagOldMenuNewIcons = require(RobloxGui.Modules.Flags.GetFFlagOldMenuNewIcons)
local GetFFlagPauseMuteFix = require(RobloxGui.Modules.Flags.GetFFlagPauseMuteFix)
local GetFFlagPlayerListAnimateMic = require(RobloxGui.Modules.Flags.GetFFlagPlayerListAnimateMic)
local GetFFlagOldMenuUseSpeakerIcons = require(RobloxGui.Modules.Flags.GetFFlagOldMenuUseSpeakerIcons)
local GetFFlagInviteTextTruncateFix = require(RobloxGui.Modules.Flags.GetFFlagInviteTextTruncateFix)
local FFlagAvatarChatCoreScriptSupport = require(RobloxGui.Modules.Flags.FFlagAvatarChatCoreScriptSupport)
local GetFFlagVoiceRecordingIndicatorsEnabled = require(RobloxGui.Modules.Flags.GetFFlagVoiceRecordingIndicatorsEnabled)
local GetFFlagRequestFriendshipAnalyticsSwitch = require(RobloxGui.Modules.Flags.GetFFlagRequestFriendshipAnalyticsSwitch)
local GetFFlagEnableInspectFriendsAnalytics = require(RobloxGui.Modules.Flags.GetFFlagEnableInspectFriendsAnalytics)
local GetFFlagVoiceChatToggleMuteAnalytics = require(RobloxGui.Modules.Settings.Flags.GetFFlagVoiceChatToggleMuteAnalytics)
local GetFFlagEnableBlockAnalyticsSource = require(RobloxGui.Modules.Flags.GetFFlagEnableBlockAnalyticsSource)
local GetFFlagFixMutePlayerAnalytics = require(RobloxGui.Modules.Flags.GetFFlagFixMutePlayerAnalytics)
local GetFFlagEnableLeaveHomeResumeAnalytics = require(RobloxGui.Modules.Flags.GetFFlagEnableLeaveHomeResumeAnalytics)

local EngineFeatureVoiceChatMultistreamSubscriptionsEnabled = game:GetEngineFeature("VoiceChatMultistreamSubscriptionsEnabled")
local LuaFlagVoiceChatDisableSubscribeRetryForMultistream = game:DefineFastFlag("LuaFlagVoiceChatDisableSubscribeRetryForMultistream", true)
local FFlagPlayerListRefactorUsernameFormatting = game:DefineFastFlag("PlayerListRefactorUsernameFormatting", false)

if GetFFlagOldMenuNewIcons() then
	MuteStatusIcons = VoiceChatServiceManager.MuteStatusIcons
	PlayerMuteStatusIcons = VoiceChatServiceManager.PlayerMuteStatusIcons
end

----------- CLASS DECLARATION --------------
local function Initialize()
	local settingsPageFactory = require(RobloxGui.Modules.Settings.SettingsPageFactory)
	local this = settingsPageFactory:CreateNewPage()

	if Theme.UIBloxThemeEnabled then
		this.PageListLayout.Padding = UDim.new(0, 16)
	else
		this.PageListLayout.Padding = UDim.new(0, PLAYER_ROW_SPACING - PLAYER_ROW_HEIGHT)
	end

	------ TAB CUSTOMIZATION -------
	this.TabHeader.Name = "PlayersTab"
	if Theme.UIBloxThemeEnabled then
		this.TabHeader.TabLabel.Icon.Image = isTenFootInterface and "rbxasset://textures/ui/Settings/MenuBarIcons/PlayersTabIcon@2x.png" or "rbxasset://textures/ui/Settings/MenuBarIcons/PlayersTabIcon.png"

		local icon = Theme.Images["icons/menu/friends"]
		this.TabHeader.TabLabel.Icon.ImageRectOffset = icon.ImageRectOffset
		this.TabHeader.TabLabel.Icon.ImageRectSize = icon.ImageRectSize
		this.TabHeader.TabLabel.Icon.Image = icon.Image

		this.TabHeader.TabLabel.Title.Text = "People"
	else
		this.TabHeader.Icon.Image = isTenFootInterface and "rbxasset://textures/ui/Settings/MenuBarIcons/PlayersTabIcon@2x.png" or "rbxasset://textures/ui/Settings/MenuBarIcons/PlayersTabIcon.png"

		if FFlagUseNotificationsLocalization then
			this.TabHeader.Title.Text = "People"
		else
			this.TabHeader.Icon.Title.Text = "People"
		end
	end


	----- FRIENDSHIP FUNCTIONS ------
	local function getFriendStatus(selectedPlayer)
		local success, result = pcall(function()
			-- NOTE: Core script only
			return localPlayer:GetFriendStatus(selectedPlayer)
		end)
		if success then
			return result
		else
			return Enum.FriendStatus.NotFriend
		end
	end

	------ PAGE CUSTOMIZATION -------
	this.Page.Name = "Players"

	local function showRightSideButtons(player)
		return player and player ~= localPlayer and player.UserId > 0 and localPlayer.UserId > 0
	end

	local function useOptimizedPortraitLayout()
		return FFlagExtendedExpMenuPortraitLayout and utility:IsSmallTouchScreen() and utility:IsPortrait()
	end

	local function getIsBlocked(player)
		return BlockingUtility:IsPlayerBlockedByUserId(player.UserId)
	end

	local function createFriendStatusTextLabel(status, player)
		if status == nil then
			return nil
		end

		local fakeSelection = Instance.new("Frame")
		fakeSelection.BackgroundTransparency = 1

		local friendLabel = nil
		local friendLabelText = nil
		if status == Enum.FriendStatus.Friend or status == Enum.FriendStatus.FriendRequestSent then
			friendLabel = Instance.new("TextButton")
			friendLabel.BackgroundTransparency = 1
			friendLabel.FontSize = Theme.fontSize(Enum.FontSize.Size24)
			friendLabel.Font = Theme.font(Enum.Font.SourceSans)
			friendLabel.TextColor3 = Color3.new(1,1,1)
			friendLabel.SelectionImageObject = fakeSelection
			if status == Enum.FriendStatus.Friend then
				friendLabel.Text = "Friend"
			else
				friendLabel.Text = "Request Sent"
			end
		elseif status == Enum.FriendStatus.Unknown or status == Enum.FriendStatus.NotFriend or status == Enum.FriendStatus.FriendRequestReceived then
			local addFriendFunc = function()
				if friendLabel and friendLabelText and friendLabelText.Text ~= "" then
					friendLabel.ImageTransparency = 1
					friendLabelText.Text = ""
					if localPlayer and player then
						AnalyticsService:ReportCounter("PlayersMenu-RequestFriendship")
						if GetFFlagRequestFriendshipAnalyticsSwitch() then
							AnalyticsService:SetRBXEventStream(Constants.AnalyticsTargetName, Constants.AnalyticsRequestFriendContext, Constants.AnalyticsRequestFriendName, {
								category = "Game"
							})
						else
							AnalyticsService:TrackEvent("Game", "RequestFriendship", "PlayersMenu")
						end

						localPlayer:RequestFriendship(player)
					end
				end
			end

			if platform ~= Enum.Platform.XBoxOne then
				friendLabel, friendLabelText = utility:MakeStyledButton("FriendStatus", "Add Friend", UDim2.new(0, 182, 0, Theme.ButtonHeight), addFriendFunc)
				friendLabelText.ZIndex = 3
				friendLabelText.Position = friendLabelText.Position + UDim2.new(0,0,0,1)
			end
		end

		if friendLabel then
			friendLabel.Name = "FriendStatus"
			friendLabel.ZIndex = 3
			if Theme.UIBloxThemeEnabled then
				friendLabel.Size = UDim2.new(0, 150, 0, Theme.ButtonHeight)
				friendLabel.Position = UDim2.new(1,-198,0,7)
				if friendLabelText then
					friendLabelText.Position = UDim2.new(0,0,0,0)
				end
			else
				friendLabel.Size = UDim2.new(0, 150, 0, 46)
				friendLabel.Position = UDim2.new(1,-198,0,7)
			end
		end
		return friendLabel
	end

	local function createFriendStatusImageLabel(status, player)

		if status == Enum.FriendStatus.Friend or status == Enum.FriendStatus.FriendRequestSent then
			if Theme.UIBloxThemeEnabled then

				local image = FRIEND_IMAGE
				local imgTrans =  0
				if status ~= Enum.FriendStatus.Friend then
					image = ADD_FRIEND_IMAGE
					imgTrans = 0.5
				end

				local addFriendButton, _addFriendImage = utility:MakeStyledImageButton("FriendStatus", image,
					UDim2.new(0, Theme.ButtonHeight, 0, Theme.ButtonHeight), UDim2.new(0, 28, 0, 28))
				addFriendButton.Name = "FriendStatus"
				addFriendButton.Selectable = false

				addFriendButton.FriendStatusImageLabel.ImageTransparency = imgTrans

				return addFriendButton
			else

				local friendLabel = Instance.new("ImageButton")
				friendLabel.Name = "FriendStatus"
				friendLabel.Size = UDim2.new(0, Theme.ButtonHeight, 0, Theme.ButtonHeight)
				friendLabel.Image = "rbxasset://textures/ui/Settings/MenuBarAssets/MenuButton.png"
				friendLabel.ScaleType = Enum.ScaleType.Slice
				friendLabel.SliceCenter = Rect.new(8,6,46,44)
				friendLabel.AutoButtonColor = false
				friendLabel.BackgroundTransparency = 1
				friendLabel.ZIndex = 2
				local friendImage = Instance.new("ImageLabel")
				friendImage.BackgroundTransparency = 1
				friendImage.Position = UDim2.new(0.5, 0, 0.5, 0)
				friendImage.Size = UDim2.new(0, 28, 0, 28)
				friendImage.AnchorPoint = Vector2.new(0.5, 0.5)
				friendImage.ZIndex = 3
				friendImage.Image = FRIEND_IMAGE
				if status == Enum.FriendStatus.Friend then
					friendImage.ImageTransparency = 0
				else
					friendImage.Image = ADD_FRIEND_IMAGE
					friendImage.ImageTransparency = 0.5
				end
				friendImage.Parent = friendLabel
				return friendLabel
			end
		elseif
			status == Enum.FriendStatus.Unknown
			or status == Enum.FriendStatus.NotFriend
			or status == Enum.FriendStatus.FriendRequestReceived
		then
			local addFriendButton, addFriendImage = nil
			local addFriendFunc = function()
				if addFriendButton and addFriendImage and addFriendButton.ImageTransparency ~= 1 then
					addFriendButton.ImageTransparency = 1
					addFriendImage.ImageTransparency = 1
					if localPlayer and player then
						AnalyticsService:ReportCounter("PlayersMenu-RequestFriendship")
						if GetFFlagRequestFriendshipAnalyticsSwitch() then
							AnalyticsService:SetRBXEventStream(Constants.AnalyticsTargetName, Constants.AnalyticsRequestFriendContext, Constants.AnalyticsRequestFriendName, {
								category = "Game"
							})
						else
							AnalyticsService:TrackEvent("Game", "RequestFriendship", "PlayersMenu")
						end

						localPlayer:RequestFriendship(player)
					end
				end
			end
			addFriendButton, addFriendImage = utility:MakeStyledImageButton("FriendStatus", ADD_FRIEND_IMAGE,
				UDim2.new(0, Theme.ButtonHeight, 0, Theme.ButtonHeight), UDim2.new(0, 28, 0, 28), addFriendFunc)
			addFriendButton.Name = "FriendStatus"
			addFriendButton.Selectable = true
			return addFriendButton
		end
		return nil
	end

	local shareGameButton
	local muteAllButton
	local muteImageButtons = {}
	local voiceAnalytics
	if GetFFlagVoiceChatToggleMuteAnalytics() then
		voiceAnalytics = VoiceAnalytics.new(AnalyticsService)
	end

	local function friendStatusCreate(playerLabel, player)
		local friendLabelParent = nil
		if playerLabel then
			friendLabelParent = playerLabel:FindFirstChild("RightSideButtons")
		end

		if friendLabelParent then
			-- remove any previous friend status labels
			for _, item in pairs(friendLabelParent:GetChildren()) do
				if item and item.Name == "FriendStatus" then
					if GuiService.SelectedCoreObject == item then
						GuiService.SelectedCoreObject = shareGameButton
					end
					item:Destroy()
				end
			end
		end
	end

	local function resizeFriendButton(parent, player, isPortrait, wasIsPortrait)
		local friendLabel = parent:FindFirstChild("FriendStatus")
		if friendLabel and isPortrait == wasIsPortrait then
			return
		end

		if friendLabel then
			friendLabel:Destroy()
			friendLabel = nil
		end

		local status
		if showRightSideButtons(player) then
			status = getFriendStatus(player)
		end

		if getIsBlocked(player) == false then
			if isPortrait then
				friendLabel = createFriendStatusImageLabel(status, player)
			else
				friendLabel = createFriendStatusTextLabel(status, player)
			end
		end

		if friendLabel then
			friendLabel.Name = "FriendStatus"
			friendLabel.LayoutOrder = 5
			friendLabel.Selectable = true
			friendLabel.Parent = parent
		end
	end

	localPlayer.FriendStatusChanged:connect(function(player, friendStatus)
		if player then
			local playerLabel = this.Page:FindFirstChild("PlayerLabel"..player.Name)
			if playerLabel then
				friendStatusCreate(playerLabel, player)
			end
		end
	end)

	local resizeBlockButton
	local blockingAnalytics = BlockingAnalytics.new(
		localPlayer.UserId,
		{ EventStream = AnalyticsService }
	)

	local function createBlockButton(parent, player, isPortrait, wasIsPortrait)
		local isBlocked = getIsBlocked(player)

		local function updateBlockButton()
			resizeBlockButton(parent, player, isPortrait, not isPortrait)
			resizeFriendButton(parent, player, isPortrait, not isPortrait)
		end

		local function blockUser()
			if GetFFlagEnableBlockAnalyticsSource() then
				onBlockButtonActivated(player, blockingAnalytics, Constants.AnalyticsInGameMenuName):andThen(updateBlockButton)
			else
				onBlockButtonActivated(player, blockingAnalytics):andThen(updateBlockButton)
			end
		end

		local function unBlockUser()
			local success = BlockingUtility:UnblockPlayerAsync(player)
			if success then
				blockingAnalytics:action("SettingsHub", "unblockUser", {
					blockeeUserId = player.UserId
				})

				updateBlockButton()
			end
		end

		if isBlocked then
			return utility:MakeStyledButton(
				"BlockButton",
				RobloxTranslator:FormatByKey("Feature.SettingsHub.Action.Unblock"),
				UDim2.new(0, 110, 0, Theme.ButtonHeight),
				unBlockUser
			)
		else
			return utility:MakeStyledImageButton(
				"BlockButton",
				BLOCK_IMAGE,
				UDim2.new(0, Theme.ButtonHeight, 0, Theme.ButtonHeight),
				UDim2.new(0, 28, 0, 28),
				blockUser
			)
		end
	end

	function resizeBlockButton(parent, player, isPortrait, wasIsPortrait)
		local blockButton = parent:FindFirstChild("BlockButton")
		if blockButton and isPortrait == wasIsPortrait then
			return
		end

		if blockButton then
			blockButton:Destroy()
			blockButton = nil
		end

		if showRightSideButtons(player) then
			blockButton = createBlockButton(parent, player, isPortrait, wasIsPortrait)
		end

		if blockButton then
			blockButton.Name = "BlockButton"
			blockButton.LayoutOrder = 4
			blockButton.Selectable = true
			blockButton.Parent = parent
		end
	end

	local isLocalPlayerMutedState = false
	local muteAllState = false

	local function muteButtonUpdate(playerLabel, playerStatus)
		local buttonParent = nil
		if playerLabel then
			buttonParent = playerLabel:FindFirstChild("RightSideButtons")
		end

		if not buttonParent then
			return
		end
		local oldButton = buttonParent:FindFirstChild("MuteStatusButton")

		if playerStatus == nil then
			if oldButton then
				oldButton:Destroy()
			end
			return
		end

		local imageSize = GetFFlagOldMenuNewIcons() and UDim2.fromOffset(36, 36) or UDim2.fromOffset(20, 26)
		local imageOffset = GetFFlagOldMenuNewIcons() and UDim2.fromOffset(0, 0) or UDim2.new(0, 0, 0, 1)
		local imageTransparency = 0

		local image = playerStatus.isMuted
			and MuteStatusIcons.MicOff
			or MuteStatusIcons.MicOn

		if playerStatus.subscriptionFailed then
			image = MuteStatusIcons.Error
			imageSize = UDim2.fromOffset(36, 36)
			imageOffset = UDim2.fromOffset(2, -2)
			if LuaFlagVoiceChatDisableSubscribeRetryForMultistream then
				if EngineFeatureVoiceChatMultistreamSubscriptionsEnabled then
					imageTransparency = 0.5
				end
			end
		elseif playerStatus.isMutedLocally then
			image = MuteStatusIcons.MicDisabled
			if GetFFlagOldMenuNewIcons() then
				imageTransparency = 0.5
			end
		elseif not playerStatus.subscriptionCompleted then
			image = MuteStatusIcons.Loading
		elseif GetFFlagOldMenuNewIcons() and GetFFlagPlayerListAnimateMic() and playerStatus.isSignalActive then
			local level = math.random()
			local roundedLevel = 20 * math.floor(0.5 + 5*level)
			image = VoiceChatServiceManager:GetIcon("Unmuted" .. tostring(roundedLevel), if GetFFlagOldMenuUseSpeakerIcons() then "SpeakerLight" else "MicLight")
		end

		if oldButton then
			local muteStatusLabel
			if GetFFlagPlayerListAnimateMic() then
				muteStatusLabel = muteImageButtons[playerStatus.userId] or buttonParent:FindFirstChild("MuteStatusImageLabel", true)
			else
				muteStatusLabel = buttonParent:FindFirstChild("MuteStatusImageLabel", true)
			end
			muteStatusLabel.Image = image
			muteStatusLabel.Size = imageSize
			if GetFFlagOldMenuNewIcons() then
				muteStatusLabel.ImageTransparency = imageTransparency
			end
		else
			local muteLabel, muteLabelText = utility:MakeStyledImageButton(
				"MuteStatus",
				image,
				UDim2.fromOffset(Theme.ButtonHeight, Theme.ButtonHeight),
				imageSize,
				function ()
					-- TODO(SOCRTC-3638|kangiwang): replace per-user subscription failure
					-- rejoin buttons with one single button to retry all subscriptions.
					local status = VoiceChatServiceManager.participants[tostring(playerStatus.userId)]
					if status.subscriptionCompleted then
						if voiceAnalytics then
							if GetFFlagFixMutePlayerAnalytics() then
								voiceAnalytics:onToggleMutePlayer(playerStatus.userId, not status.isMutedLocally)
							else
								voiceAnalytics:onToggleMutePlayer(not playerStatus.isMutedLocally, playerStatus.userId)
							end
						end
						VoiceChatServiceManager:ToggleMutePlayer(
							playerStatus.userId
						)
					elseif status.subscriptionFailed then
						if LuaFlagVoiceChatDisableSubscribeRetryForMultistream then
							if not EngineFeatureVoiceChatMultistreamSubscriptionsEnabled then
								VoiceChatServiceManager:SubscribeRetry(playerStatus.userId)
							end
						else
							VoiceChatServiceManager:SubscribeRetry(playerStatus.userId)
						end
					end
				end
			)
			if GetFFlagPlayerListAnimateMic() then
				muteImageButtons[playerStatus.userId] = muteLabelText
			end
			muteLabelText.ZIndex = 3
			muteLabelText.Position = muteLabelText.Position + imageOffset
			if GetFFlagOldMenuNewIcons() then
				muteLabelText.ImageTransparency = imageTransparency
			end
			muteLabel.Parent = buttonParent
		end
	end

	local buttonsContainer = utility:Create("Frame") {
		Name = "ButtonsContainer",
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundTransparency = 1,
		Parent = this.Page,

		Visible = false
	}

	local buttonPadding = 5;
	if Theme.UIBloxThemeEnabled then
		utility:Create("UIPadding") {
			PaddingBottom = UDim.new(0, 1),
			PaddingTop = UDim.new(0, 1),
			PaddingLeft = UDim.new(0, 1),
			PaddingRight = UDim.new(0, 1),
			Parent = buttonsContainer,
		}
		buttonPadding = 12
		buttonsContainer.Size = UDim2.new(1, 0, 0, Theme.ButtonHeight)
	end

	local leaveGameFunc = function()
		this.HubRef:SwitchToPage(this.HubRef.LeaveGamePage, false, 1)
	end

	local leaveGameText = "Leave"

	local leaveButton, leaveLabel = utility:MakeStyledButton("LeaveButton", leaveGameText, UDim2.new(1 / 3, -buttonPadding, 1, 0), leaveGameFunc)
	leaveButton.AnchorPoint = Vector2.new(0, 0)
	leaveButton.Position = UDim2.new(0, 0, 0, 0)
	if Theme.UIBloxThemeEnabled then
		leaveLabel.Size = UDim2.new(1, -4, 1, 0)
		leaveLabel.Position = UDim2.new(0, 2, 0, 0)
	else
		leaveLabel.Size = UDim2.new(1, 0, 1, -6)
	end

	leaveButton.Parent = buttonsContainer

	local resetFunc = function()
		this.HubRef:SwitchToPage(this.HubRef.ResetCharacterPage, false, 1)
	end
	local resetButton, resetLabel = utility:MakeStyledButton("ResetButton", "Reset Character", UDim2.new(1 / 3, -buttonPadding, 1, 0), resetFunc)
	resetButton.AnchorPoint = Vector2.new(0.5, 0)
	resetButton.Position = UDim2.new(0.5, 0, 0, 0)

	if Theme.UIBloxThemeEnabled then
		resetLabel.Size = UDim2.new(1, -4, 1, 0)
		resetLabel.Position = UDim2.new(0, 2, 0, 0)
	else
		resetLabel.Size = UDim2.new(1, 0, 1, -6)
	end
	resetButton.Parent = buttonsContainer

	local resumeGameFunc = function()
		this.HubRef:SetVisibility(false)
		if GetFFlagEnableLeaveHomeResumeAnalytics() then
			AnalyticsService:SetRBXEventStream(
				Constants.AnalyticsTargetName,
				Constants.AnalyticsResumeGameName,
				Constants.AnalyticsMenuActionName,
				{ source = Constants.AnalyticsResumeButtonSource }
			)
		end
	end

	local resumeGameText = "Resume"

	local resumeButton, resumeLabel = utility:MakeStyledButton("ResumeButton", resumeGameText, UDim2.new(1 / 3, -buttonPadding, 1, 0), resumeGameFunc)
	resumeButton.AnchorPoint = Vector2.new(1, 0)
	resumeButton.Position = UDim2.new(1, 0, 0, 0)

	if Theme.UIBloxThemeEnabled then
		resumeLabel.Size = UDim2.new(1, -4, 1, 0)
		resumeLabel.Position = UDim2.new(0, 2, 0, 0)
	else
		resumeLabel.Size = UDim2.new(1, 0, 1, -6)
	end

	resumeButton.Parent = buttonsContainer

	local function pollImage()
		local newMuted = VoiceChatServiceManager.localMuted
		local image
		if newMuted == nil then
			image = if GetFFlagOldMenuUseSpeakerIcons() then PlayerMuteStatusIcons.Loading else MuteStatusIcons.Loading
		elseif newMuted then
			image = if GetFFlagOldMenuUseSpeakerIcons() then PlayerMuteStatusIcons.MicOff else MuteStatusIcons.MicOff
		elseif VoiceChatServiceManager.isTalking and GetFFlagPlayerListAnimateMic() then
			local level = math.random()
			local roundedLevel = 20 * math.floor(0.5 + 5*level)
			image = VoiceChatServiceManager:GetIcon("Unmuted" .. tostring(roundedLevel), "MicLight")
		else
			image = if GetFFlagOldMenuUseSpeakerIcons() then PlayerMuteStatusIcons.MicOn else MuteStatusIcons.MicOn
		end
		return image
	end

	local function updateButtonPosition(buttonName, position, size, anchorPoint)
		-- We need to concat "ButtonButton" because addBottomBarButton creates name+"Button" and sends that to util.createButton
		-- which creates a button instance using name+"Button"...
		local buttonInstance = buttonsContainer:FindFirstChild(buttonName .. "Button", true)
		if not buttonInstance then
			return
		end
		buttonInstance.Position = position
		buttonInstance.Size = size
		buttonInstance.AnchorPoint = anchorPoint
	end

	local function updateButtonRow()
		local buttonPaddingY = 6
		local buttonPaddingX = 0

		local newButtonSize = 2 / 7
		if Theme.UIBloxThemeEnabled then
			buttonPaddingY = 0
			buttonPaddingX = 12
		end
		local oldButtonContainerSize = 6 / 7
		updateButtonPosition("ResumeButton", UDim2.new(1 * oldButtonContainerSize, 0, 0, 0), UDim2.new(newButtonSize, -buttonPaddingX, 1, -buttonPaddingY), Vector2.new(1, 0))
		updateButtonPosition("ResetButton", UDim2.new(0.5 * oldButtonContainerSize, 0, 0, 0), UDim2.new(newButtonSize, -buttonPaddingX, 1, -buttonPaddingY), Vector2.new(0.5, 0))
		updateButtonPosition("LeaveButton", UDim2.new(0 * oldButtonContainerSize, 0, 0, 0), UDim2.new(newButtonSize, -buttonPaddingX, 1, -buttonPaddingY), Vector2.new(0, 0))
	end

	local function updateIcon()
		local buttonInstance = buttonsContainer:FindFirstChild("PlayerMuteButtonImageLabel", true)
		if not buttonInstance then
			return
		end
		buttonInstance.Image = pollImage()
	end

	local function appendMuteButton()
		local muteButton, imageLabel = utility:MakeStyledImageButton(
			"PlayerMuteButton",
			pollImage(),
			GetFFlagPauseMuteFix() and UDim2.new(1, 0, 1, 0) or UDim2.new(1 / 5, -5, 4 / 5, 0),
			GetFFlagPauseMuteFix() and UDim2.new(1, -6, 1, -4) or UDim2.new(0.5, -6, 0.65, -4),
			function ()
				VoiceChatServiceManager:ToggleMic()
				if voiceAnalytics then
					voiceAnalytics:onToggleMuteSelf(isLocalPlayerMutedState)
				end
			end
			,nil, nil, "DefaultButton"
		)

		if Theme.UIBloxThemeEnabled then
			muteButton.Position = UDim2.new(1, 0, 0, 0)
			muteButton.Size = UDim2.new(1 / 7, -12, 1, 0)
			imageLabel.Size = UDim2.new(1, -6, 1, -4)
			utility:Create'UIAspectRatioConstraint'
			{
				AspectRatio = 1,
				Parent = imageLabel
			}
		else
			muteButton.Position = UDim2.new(1, 0, 0, 0)
			muteButton.Size = UDim2.new(1 / 7, 0, 1, -6)
		end

		muteButton.AnchorPoint = Vector2.new(1, 0)

		if GetFFlagPauseMuteFix() then
			imageLabel.SizeConstraint = Enum.SizeConstraint.RelativeYY
		end
		muteButton.Parent = buttonsContainer
		VoiceChatServiceManager.muteChanged.Event:Connect(function(muted)
			if GetFFlagVoiceChatToggleMuteAnalytics() then
				isLocalPlayerMutedState = muted
			end
			updateIcon()
		end)
	end

	local function addMuteButtonExperience()
		updateButtonRow()
		appendMuteButton()
	end

	utility:OnResized(buttonsContainer, function(newSize, isPortrait)

		if (isPortrait or utility:IsSmallTouchScreen()) and (not Theme.AlwaysShowBottomBar()) then
			local buttonsFontSize = isPortrait and Theme.textSize(18) or Theme.textSize(24)
			buttonsContainer.Visible = not Theme.UIBloxThemeEnabled or not Theme.EnableVerticalBottomBar
			if Theme.UIBloxThemeEnabled then
				buttonsContainer.Size = UDim2.new(1, 0, 0, Theme.ButtonHeight)
			else
				buttonsContainer.Size = UDim2.new(1, 0, 0, isPortrait and 50 or 62)
			end
			resetLabel.TextSize = buttonsFontSize
			leaveLabel.TextSize = buttonsFontSize
			resumeLabel.TextSize = buttonsFontSize
		else
			buttonsContainer.Visible = false
			buttonsContainer.Size = UDim2.new(1, 0, 0, 0)
		end
	end)

	if FFlagUseNotificationsLocalization then
		local function ApplyLocalizeTextSettingsToLabel(label)
			label.AnchorPoint = Vector2.new(0.5,0.5)
			label.Position = UDim2.new(0.5, 0, 0.5, -3)
			label.Size = UDim2.new(0.75, 0, 0.5, 0)
		end
		ApplyLocalizeTextSettingsToLabel(leaveLabel)
		ApplyLocalizeTextSettingsToLabel(resetLabel)
		ApplyLocalizeTextSettingsToLabel(resetLabel)
	end

	local function reportAbuseButtonCreate(playerLabel, player)
		local rightSideButtons = playerLabel:FindFirstChild("RightSideButtons")
		if rightSideButtons then
			local oldReportButton = rightSideButtons:FindFirstChild("ReportPlayer")
			if oldReportButton then
				oldReportButton:Destroy()
			end

			if showRightSideButtons(player) then
				local reportPlayerFunction = function()
					reportAbuseMenu:ReportPlayer(player, "MenuPlayerList")
				end

				local reportButton = utility:MakeStyledImageButton("ReportPlayer", REPORT_PLAYER_IMAGE,
						UDim2.new(0, Theme.ButtonHeight, 0, Theme.ButtonHeight), UDim2.new(0, 28, 0, 28), reportPlayerFunction)
				reportButton.Name = "ReportPlayer"
				reportButton.Position = UDim2.new(1, -260, 0, 7)
				reportButton.LayoutOrder = 3
				reportButton.Selectable = true
				reportButton.Parent = rightSideButtons
			end
		end
	end

	local createShareGameButton = nil
	local createMuteAllButton = nil
	local createPlayerRow = nil

	local voiceChatServiceConnected = false

	local function muteAllButtonRemove()
		if muteAllButton then
			muteAllButton.Visible = false
			muteAllButton:Destroy()
		end
		if shareGameButton then
			shareGameButton.Size = FULL_SIZE_SHARE_GAME_BUTTON_SIZE
		end
	end

	local function createRow(frameClassName, hasSecondRow)
		local frame = Instance.new(frameClassName)
		frame.Size = UDim2.new(1, 0, 0, PLAYER_ROW_HEIGHT)
		frame.Position = UDim2.new(0, 0, 0, 0)
		frame.ZIndex = 2

		if Theme.UIBloxThemeEnabled then
			frame.BackgroundColor3 = Theme.color("PlayerRowFrame")
			frame.BackgroundTransparency = Theme.transparency("PlayerRowFrame")
			utility:Create'UICorner'
			{
				CornerRadius = Theme.DefaultCornerRadius,
				Parent = frame,
			}
		else
			frame.Image = "rbxasset://textures/ui/dialog_white.png"
			frame.ScaleType = "Slice"
			frame.SliceCenter = Rect.new(10, 10, 10, 10)
			frame.BackgroundTransparency = 1
			frame.ImageTransparency = FRAME_DEFAULT_TRANSPARENCY
		end

		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.BackgroundTransparency = 1
		icon.Size = UDim2.new(0, 36, 0, 36)
		icon.Position = UDim2.new(0, 12, 0, 12)
		icon.ZIndex = 3
		icon.Parent = frame

		local textLabel = Instance.new("TextLabel")
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.Font = Theme.font(Enum.Font.SourceSans, "DisplayName")
		textLabel.FontSize = hasSecondRow and Theme.fontSize(Enum.FontSize.Size36, "DisplayName") or Theme.fontSize(Enum.FontSize.Size24, "DisplayName")
		textLabel.TextColor3 = Color3.new(1, 1, 1)
		textLabel.BackgroundTransparency = 1
		textLabel.Position = hasSecondRow and UDim2.new(0, 60, 0.5, -10) or UDim2.new(0, 60, .5, 0)
		textLabel.Size = UDim2.new(0, 0, 0, 0)
		textLabel.ZIndex = 3
		textLabel.Parent = frame

		if hasSecondRow then
			local secondRow = Instance.new("TextLabel")
			secondRow.Name = "SecondRow"
			secondRow.TextXAlignment = Enum.TextXAlignment.Left
			secondRow.Font = Theme.font(Enum.Font.SourceSans)
			secondRow.FontSize = Theme.fontSize(Enum.FontSize.Size24, "Username")
			secondRow.TextColor3 = Color3.fromRGB(162, 162, 162)
			secondRow.BackgroundTransparency = 1
			secondRow.Position = UDim2.new(0, 60, .5, 12)
			secondRow.Size = UDim2.new(0, 0, 0, 0)
			secondRow.ZIndex = 3
			secondRow.Parent = frame
		end

		return frame
	end

	local TAP_ACCURACY_THREASHOLD = 20
	createShareGameButton = function()
		local frame = createRow("ImageButton")
		if Theme.UIBloxThemeEnabled then
			frame.Size = UDim2.new(1, 0, 0, BUTTON_ROW_HEIGHT)
		end
		local textLabel = frame.TextLabel
		local icon = frame.Icon
		if voiceChatServiceConnected then
			frame.Size = HALF_SIZE_SHARE_GAME_BUTTON_SIZE
			if GetFFlagInviteTextTruncateFix() then
				textLabel.Size = UDim2.new(0.5, 0, 0, 0)
				textLabel.TextTruncate = Enum.TextTruncate.AtEnd
			end
			frame.AnchorPoint = Vector2.new(0, 0)
		end

		textLabel.Font = Theme.font(Enum.Font.SourceSansSemibold, "Semibold")
		textLabel.AutoLocalize = false
		textLabel.Text = RobloxTranslator:FormatByKey("Feature.SettingsHub.Action.InviteFriendsToPlay")

		if Theme.UIBloxThemeEnabled then
			icon.AnchorPoint = Vector2.new(0, 0.5)
			icon.Position = UDim2.new(0, 18, 0.5, 0)
			local iconImg = Theme.Images["icons/actions/friends/friendInvite"]
			if iconImg then
				icon.Image = iconImg.Image
				icon.ImageRectOffset = iconImg.ImageRectOffset
				icon.ImageRectSize = iconImg.ImageRectSize
			end
		else
			icon.Size = UDim2.new(0, 24, 0, 24)
			icon.Position = UDim2.new(0, 18, 0, 18)
			ShareGameIcons:ApplyImage(icon, "invite")
		end

		local function setIsHighlighted(isHighlighted)
			if isHighlighted then
				frame.ImageTransparency = FRAME_SELECTED_TRANSPARENCY
			else
				frame.ImageTransparency = FRAME_DEFAULT_TRANSPARENCY
			end
		end

		frame.InputBegan:Connect(function() setIsHighlighted(true) end)
		frame.InputEnded:Connect(function() setIsHighlighted(false) end)
		frame.Activated:Connect(function() setIsHighlighted(false) end)
		frame.TouchPan:Connect(function(_, totalTranslation)
			if math.abs(totalTranslation.Y) > TAP_ACCURACY_THREASHOLD then
				setIsHighlighted(false)
			end
		end)

		frame.SelectionGained:connect(function() setIsHighlighted(true) end)
		frame.SelectionLost:connect(function() setIsHighlighted(false) end)
		frame.SelectionImageObject = frame:Clone()

		return frame
	end

	createMuteAllButton = function()
		local frame = createRow("ImageButton")
		frame.Size = UDim2.new(shareGameButton and 0.5 or 1, -10, 0, BUTTON_ROW_HEIGHT)
		frame.Position = UDim2.new(1, 0, 0, 0)
		frame.AnchorPoint = Vector2.new(1, 0)
		local textLabel = frame.TextLabel
		local icon = frame.Icon

		textLabel.Font = Theme.font(Enum.Font.SourceSansSemibold, "Semibold")
		textLabel.AutoLocalize = false
		textLabel.Text = RobloxTranslator:FormatByKey("Feature.SettingsHub.Action.MuteAll")

		icon.Size = UDim2.new(0, 24, 0, 24)
		icon.Position = UDim2.new(0, 18, 0, 18)
		if GetFFlagOldMenuNewIcons() then
			icon.Size = UDim2.new(0, 32, 0, 32)
			icon.Position = UDim2.new(0, 18, 0, 16)
			icon.Image = VoiceChatServiceManager:GetIcon("UnmuteAll", "Misc")
		end

		if Theme.UIBloxThemeEnabled then
			icon.AnchorPoint = Vector2.new(0, 0.5)
			icon.Position = UDim2.new(0, 18, 0.5, 0)
		end

		local function setIsHighlighted(isHighlighted)
			if isHighlighted then
				frame.ImageTransparency = FRAME_SELECTED_TRANSPARENCY
			else
				frame.ImageTransparency = FRAME_DEFAULT_TRANSPARENCY
			end
		end

		frame.InputBegan:Connect(function() setIsHighlighted(true) end)
		frame.InputEnded:Connect(function() setIsHighlighted(false) end)
		frame.Activated:Connect(function() setIsHighlighted(false) end)
		frame.TouchPan:Connect(function(_, totalTranslation)
			if math.abs(totalTranslation.Y) > TAP_ACCURACY_THREASHOLD then
				setIsHighlighted(false)
			end
		end)

		frame.SelectionGained:connect(function() setIsHighlighted(true) end)
		frame.SelectionLost:connect(function() setIsHighlighted(false) end)
		frame.SelectionImageObject = frame:Clone()

		return frame
	end

	local function createInspectButtonImage(activateInspectAndBuyMenu)
		local inspectButton = utility:MakeStyledImageButton("InspectButton", INSPECT_IMAGE,
				UDim2.new(0, Theme.ButtonHeight, 0, Theme.ButtonHeight), UDim2.new(0, 28, 0, 28), activateInspectAndBuyMenu)
		return inspectButton
	end

	local function resizeInspectButton(parent, player, isPortrait, wasPortrait)
		local inspectButton = parent:FindFirstChild("Inspect")
		if inspectButton and isPortrait == wasPortrait then
			return
		end

		if inspectButton then
			inspectButton:Destroy()
		end

		local activateInspectAndBuyMenu = function()
			if GetFFlagEnableInspectFriendsAnalytics() then
				AnalyticsService:SetRBXEventStream(Constants.AnalyticsTargetName, Constants.AnalyticsExamineAvatarName, Constants.AnalyticsMenuActionName, {})
			end
			GuiService:InspectPlayerFromUserIdWithCtx(player.UserId, "escapeMenu")
			this.HubRef:SetVisibility(false)
		end

		inspectButton = createInspectButtonImage(activateInspectAndBuyMenu)
		inspectButton.Name = "Inspect"
		inspectButton.LayoutOrder = 2
		inspectButton.Selectable = true
		inspectButton.Parent = parent
	end

	createPlayerRow = function()
		local showDisplayName = true
		local frame = createRow("ImageLabel", showDisplayName)
		frame.TextLabel.Name = "DisplayNameLabel"
		frame.SecondRow.Name = "NameLabel"

		local rightSideButtons = Instance.new("Frame")
		rightSideButtons.Name = "RightSideButtons"
		rightSideButtons.BackgroundTransparency = 1
		rightSideButtons.ZIndex = 2
		rightSideButtons.Position = UDim2.new(0, 0, 0, 0)
		rightSideButtons.Size = UDim2.new(1, RIGHT_SIDE_BUTTON_PAD, 1, 0)
		rightSideButtons.Parent = frame

		-- Selection Highlighting logic:
		local updateHighlight = function(lostSelectionObject)
			if frame then
				if GuiService.SelectedCoreObject and GuiService.SelectedCoreObject ~= lostSelectionObject and GuiService.SelectedCoreObject.Parent == rightSideButtons then
					frame.ImageTransparency = FRAME_SELECTED_TRANSPARENCY
				else
					frame.ImageTransparency = FRAME_DEFAULT_TRANSPARENCY
				end
			end
		end

		local fakeSelectionObject = nil
		rightSideButtons.ChildAdded:connect(function(child)
			if child:IsA("GuiObject") then
				if fakeSelectionObject and child ~= fakeSelectionObject then
					fakeSelectionObject:Destroy()
					fakeSelectionObject = nil
				end
				child.SelectionGained:connect(function() updateHighlight(nil) end)
				child.SelectionLost:connect(function() updateHighlight(child) end)
			end
		end)

		fakeSelectionObject = Instance.new("Frame")
		fakeSelectionObject.Selectable = true
		fakeSelectionObject.Size = UDim2.new(1, 0, 1, 0)
		fakeSelectionObject.BackgroundTransparency = 1
		fakeSelectionObject.SelectionImageObject = fakeSelectionObject:Clone()
		fakeSelectionObject.Parent = rightSideButtons

		local rightSideListLayout = Instance.new("UIListLayout")
		rightSideListLayout.Name = "RightSideListLayout"
		rightSideListLayout.FillDirection = Enum.FillDirection.Horizontal
		rightSideListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		rightSideListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		rightSideListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		rightSideListLayout.Padding = UDim.new(0, 12)
		rightSideListLayout.Parent = rightSideButtons

		pcall(function()
			frame.NameLabel.Localize = false
			if showDisplayName then
				frame.DisplayNameLabel.Localize = false
			end
		end)

		return frame
	end

	-- Manage cutting off a players name if it is too long when switching into portrait mode.
	local function managePlayerNameCutoff(frame, player)
		local function getNearestRightSideButtonXPosition()
			local furthestLeftPos = nil

			for _, button in pairs(frame.RightSideButtons:GetChildren()) do
				if button:IsA("ImageButton") and (not furthestLeftPos or button.AbsolutePosition.X < furthestLeftPos) then
					furthestLeftPos = button.AbsolutePosition.X
				end
			end

			return furthestLeftPos
		end

		local lastRightSideButtonXPosition = nil
		local function rightSideButtonsChanged()
			local rightSideButtonXPosition = getNearestRightSideButtonXPosition()

			--We should only update if the absolute X position of the nearest "right-side-button" changes
			if rightSideButtonXPosition == lastRightSideButtonXPosition then
				return
			end

			lastRightSideButtonXPosition = rightSideButtonXPosition

			local nameLabelSize

			if rightSideButtonXPosition then
				nameLabelSize = UDim2.new(0, rightSideButtonXPosition - frame.NameLabel.AbsolutePosition.X - PLAYER_NAME_RIGHT_PADDING, 0, 0)
			else
				nameLabelSize = UDim2.new(1, - PLAYER_NAME_RIGHT_PADDING, 0, 0)
			end

			frame.NameLabel.Size = nameLabelSize
			frame.DisplayNameLabel.Size = nameLabelSize
			frame.NameLabel.Text = if FFlagPlayerListRefactorUsernameFormatting then formatUsername(player.Name) else "@" .. player.Name
			if getFFlagPlayerListApolloClientEnabled() and getIsUserProfileOnPlayersListEnabled() then
				ApolloClient:query({
					query = UserProfiles.Queries.userProfilesAllNamesByUserIds,
					variables = {
						userIds = { tostring(player.UserId) },
					},
				}):andThen(function(result)
					frame.DisplayNameLabel.Text = getCombinedNameFromId(result.data, player.UserId)
				end):catch(function()
					frame.DisplayNameLabel.Text = player.DisplayName
				end)
			else
				frame.DisplayNameLabel.Text = player.DisplayName
			end
		end

		frame.RightSideButtons.ChildAdded:connect(function(child)
			rightSideButtonsChanged()
			child:GetPropertyChangedSignal("AbsolutePosition"):Connect(rightSideButtonsChanged)
		end)

		rightSideButtonsChanged()
	end

	local function canShareCurrentGame()
		return localPlayer.UserId > 0
	end

	local sortedPlayers
	local existingPlayerLabels = {}
	local livePlayers = {}
	local renderStepName = 'player-list-mute-update'
	local renderSteppedConnected = false

	local function updateAllMuteButtons()
		if not muteAllButton then
			return
		end

		local players = PlayersService:GetPlayers()
		local allMuted = true
		for _, player in ipairs(players) do
			local frame = existingPlayerLabels[player.Name]

			if player and frame then
				local status = VoiceChatServiceManager.participants[tostring(player.UserId)]
				-- Check if a player is not muted to update the Mute All button.
				if FFlagAvatarChatCoreScriptSupport and status and (not status.isMutedLocally and not status.isMuted) then
					allMuted = false
				end
				muteButtonUpdate(frame, status)
			end
		end

		-- See if the Mute All button needs to update.
		if FFlagAvatarChatCoreScriptSupport then
			if allMuted then
				muteAllState = true
			else
				muteAllState = false
			end
			local text = muteAllState and RobloxTranslator:FormatByKey("Feature.SettingsHub.Action.UnmuteAll") or RobloxTranslator:FormatByKey("Feature.SettingsHub.Action.MuteAll")

			-- This button may not exist when cleaning up the settings menu after exiting a game.
			if FFlagAvatarChatCoreScriptSupport and not (muteAllButton and muteAllButton:FindFirstChild("TextLabel")) then
				return
			end
			muteAllButton.TextLabel.Text = text
			if GetFFlagOldMenuNewIcons() then
				muteAllButton.Icon.Image = VoiceChatServiceManager:GetIcon(muteAllState and "MuteAll" or "UnmuteAll", "Misc")
			end
		end
	end

	local rebuildPlayerList = function(switchedFromGamepadInput)
		sortedPlayers = PlayersService:GetPlayers()
		table.sort(sortedPlayers, function(item1,item2)
			return item1.Name:lower() < item2.Name:lower()
		end)

		local extraOffset = 20
		if utility:IsSmallTouchScreen() or utility:IsPortrait() then
			extraOffset = 85
		end

		local buttonFrame
		local showMuteAllButton = voiceChatServiceConnected and not muteAllButton
		if showMuteAllButton then
			buttonFrame = utility:Create'Frame'
			{
				Name = "Holder",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, BUTTON_ROW_HEIGHT),
				Parent = this.Page,
				LayoutOrder = 1,
			}
		end

		-- Create "invite friends" button if it doesn't exist yet
		-- We shouldn't create this button if we're not in a live game
		local isNotStudio = (not RunService:IsStudio())
		if canShareCurrentGame() and not shareGameButton and isNotStudio then
			local inviteToGameAnalytics = InviteToGameAnalytics.new()
				:withEventStream(EventStream.new())
				:withDiag(Diag.new(AnalyticsService))
				:withButtonName(InviteToGameAnalytics.ButtonName.SettingsHub)

			shareGameButton = createShareGameButton()
			shareGameButton.Activated:connect(function()
				inviteToGameAnalytics:inputShareGameEntryPoint()

				this.HubRef:InviteToGame()
			end)

			shareGameButton.LayoutOrder = 1
			if showMuteAllButton then
				shareGameButton.Parent = buttonFrame
			else
				-- Ensure the button is always at the top of the list
				shareGameButton.Parent = this.Page
			end
		end

		if showMuteAllButton then
			muteAllButton = createMuteAllButton()
			muteAllButton.Activated:connect(function()
				muteAllState = not muteAllState
				local text = muteAllState and RobloxTranslator:FormatByKey("Feature.SettingsHub.Action.UnmuteAll") or RobloxTranslator:FormatByKey("Feature.SettingsHub.Action.MuteAll")
				muteAllButton.TextLabel.Text = text
				if GetFFlagOldMenuNewIcons() then
					muteAllButton.Icon.Image = VoiceChatServiceManager:GetIcon(muteAllState and "MuteAll" or "UnmuteAll", "Misc")
				end
				if GetFFlagVoiceChatUILogging() then
					log:debug("{} all players", muteAllState and "Muting" or "Unmuting")
				end

				if voiceAnalytics then
					voiceAnalytics:onToggleMuteAll(muteAllState)
				end

				VoiceChatServiceManager:MuteAll(muteAllState)
				updateAllMuteButtons()
			end)

			muteAllButton.LayoutOrder = 1
			muteAllButton.Parent = buttonFrame
		end

		local inspectMenuEnabled = GuiService:GetInspectMenuEnabled()

		-- iterate through players to reuse or create labels for players
		for index=1, #sortedPlayers do
			local player = sortedPlayers[index]
			local frame
			frame = existingPlayerLabels[player.Name]

			if player then
				livePlayers[player.Name] = true
				-- create label (frame) for this player index if one does not exist
				if not frame or not frame.Parent then
					frame = createPlayerRow((index - 1)*PLAYER_ROW_SPACING + extraOffset)
					frame.Parent = this.Page
					existingPlayerLabels[player.Name] = frame
				end
				frame.Name = "PlayerLabel" ..player.Name

				if voiceChatServiceConnected then
					local status = VoiceChatServiceManager.participants[tostring(player.UserId)]
					muteButtonUpdate(frame, status)
				end

				local imageUrl = SocialUtil.GetPlayerImage(
					math.max(1, player.UserId), Enum.ThumbnailSize.Size100x100, Enum.ThumbnailType.AvatarThumbnail)
				frame.Icon.Image = imageUrl

				if not getFFlagPlayerListApolloClientEnabled() or not getIsUserProfileOnPlayersListEnabled() then
					frame.DisplayNameLabel.Text = player.DisplayName
				end

				frame.NameLabel.Text = if FFlagPlayerListRefactorUsernameFormatting then formatUsername(player.Name) else "@" .. player.Name

				frame.ImageTransparency = FRAME_DEFAULT_TRANSPARENCY
				-- extra index room for shareGameButton
				frame.LayoutOrder = index + 1

				frame.NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
				frame.DisplayNameLabel.TextTruncate = Enum.TextTruncate.AtEnd

				managePlayerNameCutoff(frame, player)

				friendStatusCreate(frame, player)

				local wasIsPortrait = nil
				utility:OnResized(frame, function(newSize, isPortrait)

					local parent = frame:FindFirstChild("RightSideButtons")

					if FFlagExtendedExpMenuPortraitLayout then
						local LABEL_POSX = 60

						local firstRow = frame:FindFirstChild("DisplayNameLabel")
						local secondRow = frame:FindFirstChild("NameLabel")
						local rightSideListLayout = parent and parent:FindFirstChild("RightSideListLayout")

						if useOptimizedPortraitLayout() then
							--[[
								If portrait layout on mobile, move the buttons onto ..
								a second line to remove overlap with username

								Changes:
									- Taller frame. Moves usernames higher in parent frame
									- Changes alignment of buttons to left/bottom
									- Aligns button left edge to username left edge
							--]]
							frame.Size = UDim2.new(1, 0, 0, PLAYER_ROW_HEIGHT_PORTRAIT)

							if firstRow then
								if secondRow then
									firstRow.Position = UDim2.new(0, LABEL_POSX, USERNAME_POSITION_PORTRAIT, -10)
									secondRow.Position = UDim2.new(0, LABEL_POSX, USERNAME_POSITION_PORTRAIT, 12)
								else
									firstRow.Position = UDim2.new(0, LABEL_POSX, USERNAME_POSITION_PORTRAIT, 0)
								end
							end

							if parent then
								parent.Position = UDim2.new(0, LABEL_POSX-3, 0, -2)
								parent.Size = UDim2.new(1, RIGHT_SIDE_BUTTON_PAD, 0.99, 0)
							end

							if rightSideListLayout then
								rightSideListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
								rightSideListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
							end
						else -- reset defaults
							frame.Size = UDim2.new(1, 0, 0, PLAYER_ROW_HEIGHT)

							if firstRow then
								if secondRow then
									firstRow.Position = UDim2.new(0, LABEL_POSX, USERNAME_POSITION, -10)
									secondRow.Position = UDim2.new(0, LABEL_POSX, USERNAME_POSITION, 12)
								else
									firstRow.Position = UDim2.new(0, LABEL_POSX, USERNAME_POSITION, 0)
								end
							end

							if parent then
								parent.Position = UDim2.new(0, 0, 0, 0)
								parent.Size = UDim2.new(1, RIGHT_SIDE_BUTTON_PAD, 1, 0)
							end

							if rightSideListLayout then
								rightSideListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
								rightSideListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
							end
						end
					end -- FFlagExtendedExpMenuPortraitLayout

					if parent then
						resizeFriendButton(parent, player, isPortrait, wasIsPortrait)
						resizeBlockButton(parent, player, isPortrait, wasIsPortrait)
						if inspectMenuEnabled then
							resizeInspectButton(parent, player, isPortrait, wasIsPortrait)
						end
						wasIsPortrait = isPortrait
					end
				end)

				reportAbuseButtonCreate(frame, player)
			end
		end

		if getFFlagPlayerListApolloClientEnabled() and getIsUserProfileOnPlayersListEnabled() then
			local playerIds = Cryo.List.map(sortedPlayers, function(player)
				return tostring(sortedPlayers.UserId)
			end)

			ApolloClient:query({
				query = UserProfiles.Queries.userProfilesAllNamesByUserIds,
				variables = {
					userIds = playerIds,
				},
			}):andThen(function(response)
				Cryo.List.map(response.data.userProfiles, function(userProfile)
					local labelFrame = existingPlayerLabels[userProfile.names.username]
					if labelFrame then
						labelFrame.DisplayNameLabel.Text = result.combinedName
					end
				end)
			end):catch(function()
				Cryo.List.map(sortedPlayers, function(player)
					local labelFrame = existingPlayerLabels[player.Name]
					labelFrame.DisplayNameLabel.Text = player.DisplayName
				end)
			end)
		end

		local frame = 0
		if voiceChatServiceConnected and not renderSteppedConnected and GetFFlagPlayerListAnimateMic() then
			log:debug("Setting Up Playerlist Mic Update Renderstep Hook")
			RunService:BindToRenderStep(renderStepName, Enum.RenderPriority.Last.Value, function()
				frame = frame + 1
				-- This looks a little less flickery if we only do it once every 3 frames
				if frame % 3 == 0 then
					updateAllMuteButtons()
					updateIcon()
				end
			end)
			renderSteppedConnected = true
		end

		for playerName, frame in pairs(existingPlayerLabels) do
			if not livePlayers[playerName] then
				frame:Destroy()
				existingPlayerLabels[playerName] = nil
			end
		end

		if UserInputService.GamepadEnabled then
			GuiService.SelectedCoreObject = shareGameButton
		end

		utility:OnResized("MenuPlayerListExtraPageSize", function(newSize, isPortrait)
			local extraOffset = 20
			if utility:IsSmallTouchScreen() or utility:IsPortrait() then
				extraOffset = 85
			end

			local inviteToGameRow = 1
			local playerListRowsCount = #sortedPlayers + inviteToGameRow
			if useOptimizedPortraitLayout() then
				this.Page.Size = UDim2.new(1,0,0, extraOffset + PLAYER_ROW_SPACING_PORTRAIT * playerListRowsCount - 5)
			else
				this.Page.Size = UDim2.new(1,0,0, extraOffset + PLAYER_ROW_SPACING * playerListRowsCount - 5)
			end
		end)
	end

	local cleanup = function()
		if renderStepName and renderSteppedConnected and GetFFlagPlayerListAnimateMic() then
			log:debug("Unbinding Playerlist Mic Update Renderstep Hook")
			renderSteppedConnected = false
			RunService:UnbindFromRenderStep(renderStepName)
		end
	end


	if getFFlagEnableVoiceChatPlayersList()
		and game:GetEngineFeature("VoiceChatSupported")
		and not voiceChatServiceConnected
	then
		VoiceChatServiceManager:asyncInit():andThen(function()
			voiceChatServiceConnected = true
			VoiceChatServiceManager:SetupParticipantListeners()
			-- This will only affect mobile as buttonContainer is only visibile in mobile
			addMuteButtonExperience()
			-- Rerender when the participants state changes
			VoiceChatServiceManager.participantsUpdate.Event:Connect(function()
				updateAllMuteButtons()
			end)
			VoiceChatServiceManager.participantLeft.Event:Connect(function(participants, userLeft)
				updateAllMuteButtons()
				if GetFFlagPlayerListAnimateMic() then
					muteImageButtons[userLeft] = nil
				end
			end)
			if GetFFlagVoiceRecordingIndicatorsEnabled() then
				local VCS = VoiceChatServiceManager:getService()
				VCS.StateChanged:Connect(function(_oldState, newState)
					if newState == (Enum :: any).VoiceChatState.Ended then
						muteAllButtonRemove()
						voiceChatServiceConnected = false
					elseif newState == (Enum :: any).VoiceChatState.Joined and voiceChatServiceConnected == false then
						-- TODO: Re-Add removed buttons as soon as we have a valid usecase for re-joining voice mid-game
					end
				end)
			end
		end):catch(function(err)
			if GetFFlagVoiceChatUILogging() then
				log:warning("Failed to init VoiceChatServiceManager")
			end
		end)
	end

	this.Displayed.Event:connect(rebuildPlayerList)
	this.Hidden.Event:connect(cleanup)

	PlayersService.PlayerRemoving:Connect(function (player)
		livePlayers[player.Name] = nil

		local playerLabel = existingPlayerLabels[player.Name]

		if not playerLabel then
			return
		end

		local buttons = playerLabel:FindFirstChild("RightSideButtons")
		if not buttons then
			return
		end

		local friendStatus = buttons:FindFirstChild("FriendStatus")
		if friendStatus then
			if GuiService.SelectedCoreObject == friendStatus then
				if UserInputService.GamepadEnabled then
					GuiService.SelectedCoreObject = shareGameButton
				else
					GuiService.SelectedCoreObject = nil
				end
			end
			friendStatus:Destroy()
		end

		local reportPlayer = buttons:FindFirstChild("ReportPlayer")
		if reportPlayer then
			if GuiService.SelectedCoreObject == reportPlayer then
				if UserInputService.GamepadEnabled then
					GuiService.SelectedCoreObject = shareGameButton
				else
					GuiService.SelectedCoreObject = nil
				end
			end
			reportPlayer:Destroy()
		end

		if getFFlagEnableVoiceChatPlayersList() then
			local muteStatus = buttons:FindFirstChild("MuteStatusButton")
			if muteStatus then
				if GuiService.SelectedCoreObject == muteStatus then
					if UserInputService.GamepadEnabled then
						GuiService.SelectedCoreObject = shareGameButton
					else
						GuiService.SelectedCoreObject = nil
					end
				end
				muteStatus:Destroy()
			end
		end

		local blockButton = buttons:FindFirstChild("BlockButton")
		if blockButton then
			if GuiService.SelectedCoreObject == blockButton then
				if UserInputService.GamepadEnabled then
					GuiService.SelectedCoreObject = shareGameButton
				else
					GuiService.SelectedCoreObject = nil
				end
			end
			blockButton:Destroy()
		end

		local inspectButton = buttons:FindFirstChild("Inspect")
		if inspectButton then
			if GuiService.SelectedCoreObject == inspectButton then
				GuiService.SelectedCoreObject = nil
			end
			inspectButton:Destroy()
		end
	end)

	local function removeInspectButtons()
		for _, frame in pairs(existingPlayerLabels) do
			local buttons = frame:FindFirstChild("RightSideButtons")

			if buttons then
				local inspectButton = buttons:FindFirstChild("Inspect")
				if inspectButton then
					if GuiService.SelectedCoreObject == inspectButton then
						GuiService.SelectedCoreObject = nil
					end
					inspectButton:Destroy()
				end
			end
		end
	end

	-- If the developer disables the Inspect Menu, remove the button from the escape menu.
	GuiService.InspectMenuEnabledChangedSignal:Connect(function(enabled)
		if not enabled then
			removeInspectButtons()
		end
	end)

	return this
end

----------- Public Facing API Additions --------------
PageInstance = Initialize()

return PageInstance

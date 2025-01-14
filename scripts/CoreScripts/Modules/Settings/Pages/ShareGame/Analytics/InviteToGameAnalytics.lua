local CorePackages = game:GetService("CorePackages")
local Cryo = require(CorePackages.Cryo)
local getFFlagGameInviteShortUrlEnabled = require(CorePackages.Workspace.Packages.SharedFlags).getFFlagGameInviteShortUrlEnabled

local CoreGui = game:GetService("CoreGui")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")

local getFFlagShareLinkFixAnalytics = require(RobloxGui.Modules.Settings.Flags.getFFlagShareLinkFixAnalytics)

game:DefineFastFlag("LuaAppInviteEventsIncludePlaceId", false)

local InviteToGameAnalytics = {}
InviteToGameAnalytics.__index = InviteToGameAnalytics

InviteToGameAnalytics.ButtonName = {
	SettingsHub = "settingsHub",
	ModalPrompt = "modalPrompt",
	InviteFriend = "inviteFriend",
	CancelInvite = "cancelInvite",
}

InviteToGameAnalytics.EventName = {
	InviteSent = "inputShareGameInviteSent",
	EntryPoint = "inputShareGameEntryPoint",
	LinkGenerated = "linkGenerated",
	ShareButtonClick = "buttonClick",
	InvitePromptShown = "invitePromptShown",
	InvitePromptFailed = "invitePromptFailed",
	InvitePromptAction = "invitePromptAction",
	InviteSearchFocused = "inviteSearchFocused",
}

InviteToGameAnalytics.EventFieldName = {
	CustomText = "customText",
	DefaultText = "defaultText",
}

InviteToGameAnalytics.DiagCounters = {
	EntryPoint = {
		[InviteToGameAnalytics.ButtonName.SettingsHub] = settings():GetFVariable("LuaShareGameSettingsHubEntryCounter"),
		[InviteToGameAnalytics.ButtonName.ModalPrompt] = settings():GetFVariable("LuaShareGameModalPromptEntryCounter"),
	},

	InviteSent = {
		[InviteToGameAnalytics.ButtonName.SettingsHub] = settings():GetFVariable("LuaShareGameSettingsHubInviteCounter"),
		[InviteToGameAnalytics.ButtonName.ModalPrompt] = settings():GetFVariable("LuaShareGameModalPromptInviteCounter"),
	},
}

function InviteToGameAnalytics.new()
	local self: any = {
		_eventStreamImpl = nil,
		_diagImpl = nil,
		_buttonName = nil,
	}
	setmetatable(self, InviteToGameAnalytics)

	return self
end

function InviteToGameAnalytics:withEventStream(eventStreamImpl)
	self._eventStreamImpl = eventStreamImpl
	return self
end

function InviteToGameAnalytics:withDiag(diagImpl)
	self._diagImpl = diagImpl
	return self
end

function InviteToGameAnalytics:withButtonName(buttonName)
	self._buttonName = buttonName
	return self
end

function InviteToGameAnalytics:onActivatedInviteSent(senderId, conversationId, participants)
	local buttonName = self:_getButtonName()
	local eventContext = "inGame"
	local eventName = InviteToGameAnalytics.EventName.InviteSent
	local participantsString = table.concat(participants, ",")
	local additionalArgs = {
		btn = buttonName,
		placeId = tostring(game.PlaceId),
		gameId = tostring(game.GameId),
		senderId = senderId,
		conversationId = tostring(conversationId),
		participants = participantsString,
	}
	self:_getEventStream():setRBXEventStream(eventContext, eventName, additionalArgs)

	local counterName = InviteToGameAnalytics.DiagCounters.InviteSent[self:_getButtonName()]
	if counterName then
		self:_getDiag():reportCounter(counterName, 1)
	end
end

function InviteToGameAnalytics:inputShareGameEntryPoint()
	local buttonName = self:_getButtonName()
	local eventContext = "inGame"
	local eventName = InviteToGameAnalytics.EventName.EntryPoint
	local additionalArgs = {
		btn = buttonName,
		placeId = tostring(game.PlaceId),
		gameId = tostring(game.GameId),
	}
	self:_getEventStream():setRBXEventStream(eventContext, eventName, additionalArgs)

	local counterName = InviteToGameAnalytics.DiagCounters.EntryPoint[self:_getButtonName()]
	if counterName then
		self:_getDiag():reportCounter(counterName, 1)
	end
end

function InviteToGameAnalytics:onLinkGenerated(linkType: string, linkId: number)
	assert(not getFFlagShareLinkFixAnalytics(), "onLinkGenerated should not be called when FFlagShareLinkFixAnalytics is on")
	local eventName = InviteToGameAnalytics.EventName.LinkGenerated
	local eventContext = "shareLinks"
	local additionalArgs = {
		linkType = linkType,
		linkId = linkId,
		page = "inGameMenu",
		subpage = "inviteFriendsPage",
		isShortUrlEnabled = if getFFlagGameInviteShortUrlEnabled() then true else nil
	}
	self:_getEventStream():setRBXEventStream(eventContext, eventName, additionalArgs)
end

function InviteToGameAnalytics:linkGenerated(args: { linkType: string, linkId: number })
	if not getFFlagShareLinkFixAnalytics() then
		return
	end

	local eventName = InviteToGameAnalytics.EventName.LinkGenerated
	local eventContext = "shareLinks"
	local additionalArgs = {
		linkType = args.linkType,
		linkId = args.linkId,
		page = "inGameMenu",
		subpage = "inviteFriendsPage",
	}
	self:_getEventStream():setRBXEventStream(eventContext, eventName, additionalArgs)
end

function InviteToGameAnalytics:onShareButtonClick()
	local eventName = InviteToGameAnalytics.EventName.ShareButtonClick
	local eventContext = "shareLinks"
	local additionalArgs = {
		btn = "shareServerInviteLink",
		page = "inGameMenu",
		subpage = "inviteFriendsPage",
		isShortUrlEnabled = if getFFlagGameInviteShortUrlEnabled() then true else nil
	}
	self:_getEventStream():setRBXEventStream(eventContext, eventName, additionalArgs)
end

function InviteToGameAnalytics:onSearchFocused()
	local eventName = InviteToGameAnalytics.EventName.InviteSearchFocused
	local eventContext = "inGame"
	local additionalArgs = {
		btn = self:_getButtonName(),
		page = "inGameMenu",
		subpage = "inviteFriendsPage",
	}
	self:_getEventStream():setRBXEventStream(eventContext, eventName, additionalArgs)
end

function InviteToGameAnalytics:sendEvent(trigger, event, additionalArgs: {any}?)
	local args = event.Args
	if game:GetFastFlag("LuaAppInviteEventsIncludePlaceId") then
		args = Cryo.Dictionary.join(args, { placeId = game.PlaceId })
	end
	if additionalArgs then
		args = Cryo.Dictionary.join(args, additionalArgs)
	end
	self:_getEventStream():setRBXEventStream(trigger, event.Type, args)
end

function InviteToGameAnalytics:createEventData(eventType, btn, field)
	local eventData = {
		Type = eventType,
		Args = {
			btn = btn,
			field = field,
		},
	}
	return eventData
end

function InviteToGameAnalytics:_getEventStream()
	assert(self._eventStreamImpl, "EventStream implementation not found. Did you forget to construct withEventStream?")
	return self._eventStreamImpl
end

function InviteToGameAnalytics:_getDiag()
	assert(self._diagImpl, "Diag implementation not found. Did you forget to construct withDiag?")
	return self._diagImpl
end

function InviteToGameAnalytics:_getButtonName()
	assert(self._buttonName, "ButtonName not found. Did you forget to construct withButtonName?")
	return self._buttonName
end

return InviteToGameAnalytics

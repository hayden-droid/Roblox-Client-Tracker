local CorePackages = game:GetService("CorePackages")
local IsExperienceMenuABTestEnabled = require(script.Parent.Parent.IsExperienceMenuABTestEnabled)
local GetFFlagShareInviteLinkContextMenuABTestEnabled = require(script.Parent.Parent.Flags.GetFFlagShareInviteLinkContextMenuABTestEnabled)
local GetFFlagEnableNewInviteMenuIXP = require(script.Parent.Parent.Flags.GetFFlagEnableNewInviteMenuIXP)
local GetFStringLargerRobuxUpsellIxpLayer = require(CorePackages.Workspace.Packages.SharedFlags).GetFStringLargerRobuxUpsellIxpLayer
local GetFStringLuaAppExperienceMenuLayer = require(script.Parent.Parent.Flags.GetFStringLuaAppExperienceMenuLayer)
local GetFFlagInGameMenuV1FadeBackgroundAnimation = require(script.Parent.Parent.Settings.Flags.GetFFlagInGameMenuV1FadeBackgroundAnimation)
local GetFFlagEnableTeleportBackButton = require(script.Parent.Parent.Flags.GetFFlagEnableTeleportBackButton)
local GetFStringTeleportBackButtonIXPCustomLayerName = require(script.Parent.Parent.Flags.GetFStringTeleportBackButtonIXPCustomLayerName)
local GetFFlagReportAnythingAnnotationIXP = require(script.Parent.Parent.Settings.Flags.GetFFlagReportAnythingAnnotationIXP)
local GetFStringReportAnythingAnnotationIXPLayerName = require(script.Parent.Parent.Settings.Flags.GetFStringReportAnythingAnnotationIXPLayerName)
local GetFStringChatTranslationLayerName = require(script.Parent.Parent.Flags.GetFStringChatTranslationLayerName)
local GetFFlagUserIsChatTranslationEnabled = require(script.Parent.Parent.Flags.GetFFlagUserIsChatTranslationEnabled)

return function()
	local layers = {
		"AbuseReports",
	}

	if IsExperienceMenuABTestEnabled()
		or GetFFlagShareInviteLinkContextMenuABTestEnabled()
		or GetFFlagEnableNewInviteMenuIXP()
	then
		table.insert(layers, GetFStringLuaAppExperienceMenuLayer())
	end

	if GetFStringLargerRobuxUpsellIxpLayer() then
		table.insert(layers, GetFStringLargerRobuxUpsellIxpLayer())
	end

	if GetFFlagEnableTeleportBackButton() then
		table.insert(layers, GetFStringTeleportBackButtonIXPCustomLayerName())
	end

	if GetFFlagInGameMenuV1FadeBackgroundAnimation() then
		table.insert(layers, "Engine.Interactivity.UICreation.NotchScreenSupport")
	end

	if GetFFlagReportAnythingAnnotationIXP() then
		table.insert(layers, GetFStringReportAnythingAnnotationIXPLayerName())
	end

	if GetFFlagUserIsChatTranslationEnabled() and #GetFStringChatTranslationLayerName() > 0 then
		table.insert(layers, GetFStringChatTranslationLayerName())
	end

	return layers
end

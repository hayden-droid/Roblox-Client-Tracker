local Plugin = script.Parent.Parent.Parent
local isCli = require(script.Parent.isCli)

local FFlagToolboxCreatorMarketplaceWebLinks = game:GetFastFlag("ToolboxCreatorMarketplaceWebLinks")
local FFlagAssetConfigSharingDesignTweaks = game:GetFastFlag("AssetConfigSharingDesignTweaks")
local FFlagToolboxAudioDiscovery = require(Plugin.Core.Util.Flags.AudioDiscovery).FFlagToolboxAudioDiscovery()

local AssetQuotaTypes = require(Plugin.Core.Types.AssetQuotaTypes)

local ToolboxPolicy
if isCli() then
	-- PluginPolicyService is not available in roblox-cli. So we set a mock policy (which is the current Global Toolbox policy)
	ToolboxPolicy = {
		ShowRobloxCreatedAssets = false,
		DisableMarketplaceAndRecents = false,
		DisableRatings = false,
		HideNonRelevanceSorts = false,
		HomeViewEnabledAssetTypes = if FFlagToolboxAudioDiscovery then nil else "Model;Audio",
		MarketplaceDisabledCategories = "FreePlugins;PaidPlugins;Plugins;FreeVideo",
		MarketplaceShouldUsePluginCreatorWhitelist = true,
		DisableAutocomplete = false,
		Enabled = true,
	}
else
	ToolboxPolicy = game:GetService("PluginPolicyService"):getPluginPolicy("Toolbox")
end

local ToolboxUtilities = {}

function ToolboxUtilities.showRobloxCreatedAssets()
	return ToolboxPolicy["ShowRobloxCreatedAssets"]
end

function ToolboxUtilities.disableMarketplaceAndRecents()
	return ToolboxPolicy["DisableMarketplaceAndRecents"]
end

function ToolboxUtilities.getMaxAudioLength()
	return ToolboxPolicy["MaxAudioLength"]
end

function ToolboxUtilities.getToolboxEnabled()
	return ToolboxPolicy["Enabled"]
end

function ToolboxUtilities.getMarketplaceDisabledCategories()
	return ToolboxPolicy["MarketplaceDisabledCategories"]
end

function ToolboxUtilities.getShouldUsePluginCreatorWhitelist()
	local policy = ToolboxPolicy["MarketplaceShouldUsePluginCreatorWhitelist"]

	-- Default to true (original behaviour) if the policy is not defined
	if policy == nil then
		return true
	end

	return policy
end

function ToolboxUtilities.disableRatings()
	return ToolboxPolicy["DisableRatings"]
end

function ToolboxUtilities.getShouldHideNonRelevanceSorts()
	return ToolboxPolicy["HideNonRelevanceSorts"]
end

function ToolboxUtilities.getShouldHideVerifiedCreatorBadges()
	return ToolboxPolicy["HideVerifiedCreatorBadges"]
end

function ToolboxUtilities.getShouldDisableAutocomplete()
	return ToolboxPolicy["DisableAutocomplete"]
end

if not FFlagToolboxAudioDiscovery then
	function ToolboxUtilities.getHomeViewEnabledAssetTypes()
		return ToolboxPolicy["HomeViewEnabledAssetTypes"]
	end
end

if FFlagAssetConfigSharingDesignTweaks then
	export type AssetConfigMessaging = {
		showManageUniversePermissionsLink: boolean?,
		audioPublicationDisabledLink: string?,
	}
	function ToolboxUtilities.getAssetConfigMessaging(): AssetConfigMessaging
		return ToolboxPolicy["AssetConfigMessaging"] or {}
	end
end

if FFlagToolboxCreatorMarketplaceWebLinks then
	function ToolboxUtilities.getCreatorMarketplaceWebBaseUrl(): string?
		return ToolboxPolicy["CreatorMarketplaceWebUrl"]
	end
end

local assetTypeLookup = {}
for _, v in pairs(Enum.AssetType:GetEnumItems()) do
	assetTypeLookup[v.Name] = v
end

function ToolboxUtilities.getAssetConfigDistributionQuotas(): AssetQuotaTypes.AssetQuotaPolicy
	local policyName = "AssetConfigDistributionQuotas"
	local policyValue = ToolboxPolicy[policyName]

	if policyValue == nil then
		return {}
	end

	if type(policyValue) ~= "table" then
		warn(policyName .. " is expected to be a table if defined")
		return {}
	end

	local results = {}
	for key, value in pairs(policyValue) do
		local assetType = assetTypeLookup[key]
		if assetType ~= nil then
			results[key] = value
		else
			warn("Invalid assetType name in getAssetConfigDistributionQuotasEnabledAssetTypes:", key)
		end
	end
	return results
end

return ToolboxUtilities

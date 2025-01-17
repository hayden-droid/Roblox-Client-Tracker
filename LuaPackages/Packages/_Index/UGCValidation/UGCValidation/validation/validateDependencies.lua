--!strict

--[[
	validateDependencies.lua checks that all the properties in the hierarchy tree of an asset that should contain a value, do contain an asset id, and
	that asset id points to an asset that exists (and when used from Studio, it uses validateModeration.lua which ensures the assets are created by the
	currently logged in Studio user)
]]

local root = script.Parent.Parent

local getFFlagDebugUGCDisableRCCOwnershipCheck = require(root.flags.getFFlagDebugUGCDisableRCCOwnershipCheck)

local Constants = require(root.Constants)

local ParseContentIds = require(root.util.ParseContentIds)
local FailureReasonsAccumulator = require(root.util.FailureReasonsAccumulator)
local getAssetCreationDetailsRCC = require(root.util.getAssetCreationDetailsRCC)
local Types = require(root.util.Types)

local validateModeration = require(root.validation.validateModeration)
local validateCanLoad = require(root.validation.validateCanLoad)

local function validateExistance(contentIdMap: any)
	for assetId, data in pairs(contentIdMap) do
		if not validateCanLoad(data.instance[data.fieldName]) then
			-- loading a mesh/texture can fail for many reasons, therefore we throw an error here, which means that the validation of this asset
			-- will be run again, rather than returning false. This is because we can't conclusively say it failed. It's inconclusive. This throwing
			-- of an error should only happen when validation is called from RCC
			error("Failed to load asset")
		end
	end
end

local ASSET_STATUS_RCC = {
	MODERATION_STATE_REVIEWING = "MODERATION_STATE_REVIEWING",
	MODERATION_STATE_REJECTED = "MODERATION_STATE_REJECTED",
	MODERATION_STATE_APPROVED = "MODERATION_STATE_APPROVED",
}

local function validateModerationRCC(
	restrictedUserIds: Types.RestrictedUserIds,
	contentIdMap: any
): (boolean, { string }?)
	-- if there are no users to validate against, we assume, it's not needed
	if not restrictedUserIds or #restrictedUserIds == 0 then
		return true
	end

	local idsHashTable = {}
	for _, entry in ipairs(restrictedUserIds) do
		idsHashTable[tonumber(entry.id)] = true
	end

	local reasonsAccumulator = FailureReasonsAccumulator.new()

	for id, data in pairs(contentIdMap) do
		local success, response = getAssetCreationDetailsRCC(id)
		if not success then
			-- requesting from the back-end can fail for many reasons, therefore we throw an error here, which means that the validation of this asset
			-- will be run again, rather than returning false. This is because we can't conclusively say it failed. It's inconclusive. This throwing
			-- of an error should only happen when validation is called from RCC
			error("Failed to load asset")
		end

		local failureMessage =
			string.format("%s.%s ( %s ) is not owned by the developer", data.instance:GetFullName(), data.fieldName, id)

		local creatorTable = response.creationContext.creator
		local creatorId = if creatorTable.userId then creatorTable.userId else creatorTable.groupId
		if not reasonsAccumulator:updateReasons(idsHashTable[tonumber(creatorId)], {
			failureMessage,
		}) then
			return reasonsAccumulator:getFinalResults()
		end

		if ASSET_STATUS_RCC.MODERATION_STATE_REVIEWING == response.moderationResult.moderationState then
			-- throw an error here, which means that the validation of this asset will be run again, rather than returning false. This is because we can't
			-- conclusively say it failed. It's inconclusive / in-progress, so we need to try again later
			error("Asset is under review")
		end

		if
			not reasonsAccumulator:updateReasons(
				ASSET_STATUS_RCC.MODERATION_STATE_APPROVED == response.moderationResult.moderationState,
				{
					failureMessage,
				}
			)
		then
			return reasonsAccumulator:getFinalResults()
		end
	end
	return reasonsAccumulator:getFinalResults()
end

local function validateDependencies(
	instance: Instance,
	isServer: boolean,
	allowUnreviewedAssets: boolean,
	restrictedUserIds: Types.RestrictedUserIds
): (boolean, { string }?)
	local contentIdMap = {}
	local contentIds = {}

	local parseSuccess, parseReasons = ParseContentIds.parseWithErrorCheck(
		contentIds,
		contentIdMap,
		instance,
		nil,
		Constants.CONTENT_ID_REQUIRED_FIELDS
	)
	if not parseSuccess then
		return false, parseReasons
	end

	if isServer then
		validateExistance(contentIdMap)
	end

	local reasonsAccumulator = FailureReasonsAccumulator.new()

	if not getFFlagDebugUGCDisableRCCOwnershipCheck() then
		if isServer then
			if not reasonsAccumulator:updateReasons(validateModerationRCC(restrictedUserIds, contentIdMap)) then
				return reasonsAccumulator:getFinalResults()
			end
		end
	end

	local checkModeration = not isServer
	if allowUnreviewedAssets then
		checkModeration = false
	end
	if checkModeration then
		if not reasonsAccumulator:updateReasons(validateModeration(instance, restrictedUserIds)) then
			return reasonsAccumulator:getFinalResults()
		end
	end
	return reasonsAccumulator:getFinalResults()
end

return validateDependencies

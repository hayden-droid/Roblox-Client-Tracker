--!nonstrict
local root = script.Parent.Parent

local Constants = require(root.Constants)

local validateInstanceTree = require(root.validation.validateInstanceTree)
local validateMeshTriangles = require(root.validation.validateMeshTriangles)
local validateModeration = require(root.validation.validateModeration)
local validateMaterials = require(root.validation.validateMaterials)
local validateTags = require(root.validation.validateTags)
local validateMeshBounds = require(root.validation.validateMeshBounds)
local validateTextureSize = require(root.validation.validateTextureSize)
local validateProperties = require(root.validation.validateProperties)
local validateAttributes = require(root.validation.validateAttributes)
local validateMeshVertColors = require(root.validation.validateMeshVertColors)
local validateSingleInstance = require(root.validation.validateSingleInstance)
local validateCanLoad = require(root.validation.validateCanLoad)
local validateThumbnailConfiguration = require(root.validation.validateThumbnailConfiguration)

local createAccessorySchema = require(root.util.createAccessorySchema)
local getAttachment = require(root.util.getAttachment)

local getFFlagUGCValidateBodyParts = require(root.flags.getFFlagUGCValidateBodyParts)
local getFFlagUGCValidateThumbnailConfiguration = require(root.flags.getFFlagUGCValidateThumbnailConfiguration)

local function validateLegacyAccessory(
	instances: { Instance },
	assetTypeEnum: Enum.AssetType,
	isServer: boolean,
	allowUnreviewedAssets: boolean
): (boolean, { string }?)
	local assetInfo = Constants.ASSET_TYPE_INFO[assetTypeEnum]

	local success: boolean, reasons: any

	success, reasons = validateSingleInstance(instances)
	if not success then
		return false, reasons
	end

	local instance = instances[1]

	local schema = createAccessorySchema(assetInfo.attachmentNames)

	success, reasons = validateInstanceTree(schema, instance)
	if not success then
		return false, reasons
	end

	local handle = instance:FindFirstChild("Handle") :: Part
	local mesh = handle:FindFirstChildOfClass("SpecialMesh") :: SpecialMesh
	local meshId = mesh.MeshId
	local meshScale = mesh.Scale
	local textureId = mesh.TextureId
	local attachment = getAttachment(handle, assetInfo.attachmentNames)

	local boundsInfo = assert(assetInfo.bounds[attachment.Name], "Could not find bounds for " .. attachment.Name)

	if isServer then
		local textureSuccess
		local meshSuccess
		local _canLoadFailedReason: any = {}
		textureSuccess, _canLoadFailedReason = validateCanLoad(textureId)
		meshSuccess, _canLoadFailedReason = validateCanLoad(meshId)
		if not textureSuccess or not meshSuccess then
			-- Failure to load assets should be treated as "inconclusive".
			-- Validation didn't succeed or fail, we simply couldn't run validation because the assets couldn't be loaded.
			error("Failed to load asset")
		end
	end

	if game:GetFastFlag("UGCReturnAllValidations") then
		local failedReason: any = {}
		local validationResult = true
		reasons = {}
		success, failedReason = validateMaterials(instance)
		if not success then
			table.insert(reasons, table.concat(failedReason, "\n"))
			validationResult = false
		end

		success, failedReason = validateProperties(instance)
		if not success then
			table.insert(reasons, table.concat(failedReason, "\n"))
			validationResult = false
		end

		success, failedReason = validateTags(instance)
		if not success then
			table.insert(reasons, table.concat(failedReason, "\n"))
			validationResult = false
		end

		success, failedReason = validateAttributes(instance)
		if not success then
			table.insert(reasons, table.concat(failedReason, "\n"))
			validationResult = false
		end

		success, failedReason = validateTextureSize(textureId)
		if not success then
			table.insert(reasons, table.concat(failedReason, "\n"))
			validationResult = false
		end

		if getFFlagUGCValidateThumbnailConfiguration() then
			success, failedReason = validateThumbnailConfiguration(instance, handle)
			if not success then
				table.insert(reasons, table.concat(failedReason, "\n"))
				validationResult = false
			end
		end

		local checkModeration = not isServer
		if allowUnreviewedAssets then
			checkModeration = false
		end
		if checkModeration then
			success, failedReason = validateModeration(instance, {})
			if not success then
				table.insert(reasons, table.concat(failedReason, "\n"))
				validationResult = false
			end
		end

		if meshId == "" then
			table.insert(reasons, "Mesh must contain valid MeshId")
			validationResult = false
		else
			success, failedReason = validateMeshBounds(
				handle,
				attachment,
				meshId,
				meshScale,
				assetTypeEnum,
				boundsInfo,
				(getFFlagUGCValidateBodyParts() and assetTypeEnum.Name or "")
			)
			if not success then
				table.insert(reasons, table.concat(failedReason, "\n"))
				validationResult = false
			end

			success, failedReason = validateMeshTriangles(meshId)
			if not success then
				table.insert(reasons, table.concat(failedReason, "\n"))
				validationResult = false
			end

			if game:GetFastFlag("UGCValidateMeshVertColors") then
				success, failedReason = validateMeshVertColors(meshId, false)
				if not success then
					table.insert(reasons, table.concat(failedReason, "\n"))
					validationResult = false
				end
			end
		end
		return validationResult, reasons
	else
		success, reasons = validateMaterials(instance)
		if not success then
			return false, reasons
		end

		success, reasons = validateProperties(instance)
		if not success then
			return false, reasons
		end

		success, reasons = validateTags(instance)
		if not success then
			return false, reasons
		end

		success, reasons = validateAttributes(instance)
		if not success then
			return false, reasons
		end

		success, reasons = validateMeshBounds(
			handle,
			attachment,
			meshId,
			meshScale,
			assetTypeEnum,
			boundsInfo,
			(getFFlagUGCValidateBodyParts() and assetTypeEnum.Name or "")
		)
		if not success then
			return false, reasons
		end

		success, reasons = validateTextureSize(textureId)
		if not success then
			return false, reasons
		end

		if getFFlagUGCValidateThumbnailConfiguration() then
			success, reasons = validateThumbnailConfiguration(instance, handle)
			if not success then
				return false, reasons
			end
		end

		success, reasons = validateMeshTriangles(meshId)
		if not success then
			return false, reasons
		end

		if game:GetFastFlag("UGCValidateMeshVertColors") then
			success, reasons = validateMeshVertColors(meshId, false)
			if not success then
				return false, reasons
			end
		end

		if not isServer then
			success, reasons = validateModeration(instance, {})
			if not success then
				return false, reasons
			end
		end

		return true
	end
end

return validateLegacyAccessory

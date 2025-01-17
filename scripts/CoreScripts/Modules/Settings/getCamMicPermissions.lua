--[[
	Multi functional script. Will first obtain Roblox User Settings if they
	have allowed camera and microphone access to Roblox through their account settings.

	Next, retrieves camera and microphone device permissions. MessageBus has a bug where
	it cannot handle multiple requests at once. This helper function
	will call once and store the values for future callers. It implements a
	request queue in the case this function is called multiple times
	before obtaining the permissions.

	Tracker: AVBURST-10621

	Response format for callbacks:
	{
		hasCameraPermissions = bool,
		hasMicPermissions = bool,
	}

	Otherwise the response from PermissionsProtocol is returned directly.
]]
local CorePackages = game:GetService("CorePackages")
local CoreGui = game:GetService("CoreGui")

local Cryo = require(CorePackages.Cryo)
local PermissionsProtocol = require(CorePackages.Workspace.Packages.PermissionsProtocol).PermissionsProtocol.default
local getVoiceCameraAccountSettings = require(CoreGui.RobloxGui.Modules.Settings.getVoiceCameraAccountSettings)
local getPlaceVoiceCameraEnabled = require(CoreGui.RobloxGui.Modules.Settings.getPlaceVoiceCameraEnabled)
local Promise = require(CorePackages.Promise)

local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local TrackerMenu = require(RobloxGui.Modules.Tracker.TrackerMenu)
local TrackerPromptType = require(RobloxGui.Modules.Tracker.TrackerPromptType)

local FFlagAvatarChatCoreScriptSupport = require(CoreGui.RobloxGui.Modules.Flags.FFlagAvatarChatCoreScriptSupport)
local FFlagSelfieViewEnabled = require(CoreGui.RobloxGui.Modules.SelfieView.Flags.FFlagSelfieViewEnabled)
-- Defaulting to true since this file is behind another flag.
local FFlagAvatarChatLuaCameraToast = game:DefineFastFlag("AvatarChatLuaCameraToast", true)

local GetFFlagAvatarChatServiceEnabled = require(RobloxGui.Modules.Flags.GetFFlagAvatarChatServiceEnabled)
local AvatarChatService : any = if GetFFlagAvatarChatServiceEnabled() then game:GetService("AvatarChatService") else nil

type Table = { [any]: any }
type Array<T> = { T }

local hasCameraPermissions
local hasMicPermissions
local requestPermissionsQueue: any = {}
local inProgress = false

export type PermissionsToCheck = { any? }

export type AllowedSettings = {
	isVoiceEnabled: boolean,
	isCameraEnabled: boolean,
}

-- Do not request permissions if the user has not enabled them
-- in their roblox account settings.
local function removePermissionsBasedOnUserSetting(allowedSettings: AllowedSettings, permissionsToCheck: Array<string>): Array<string>
	if not allowedSettings.isCameraEnabled and Cryo.List.find(permissionsToCheck, PermissionsProtocol.Permissions.CAMERA_ACCESS) then
		permissionsToCheck = Cryo.List.removeValue(permissionsToCheck, PermissionsProtocol.Permissions.CAMERA_ACCESS)
	end

	if not allowedSettings.isVoiceEnabled and Cryo.List.find(permissionsToCheck, PermissionsProtocol.Permissions.MICROPHONE_ACCESS) then
		permissionsToCheck = Cryo.List.removeValue(permissionsToCheck, PermissionsProtocol.Permissions.MICROPHONE_ACCESS)
	end

	return permissionsToCheck
end

local function requestPermissions(allowedSettings : AllowedSettings, callback, invokeNextRequest, permsToCheck)
	local cacheCamera = true
	local cacheMic = true
	if FFlagAvatarChatCoreScriptSupport or FFlagSelfieViewEnabled then
		cacheCamera = Cryo.List.find(permsToCheck, PermissionsProtocol.Permissions.CAMERA_ACCESS) ~= nil
		cacheMic = Cryo.List.find(permsToCheck, PermissionsProtocol.Permissions.MICROPHONE_ACCESS) ~= nil
	end

	local permissionsToCheck = removePermissionsBasedOnUserSetting(allowedSettings, permsToCheck)
	local checkingCamera = Cryo.List.find(permissionsToCheck, PermissionsProtocol.Permissions.CAMERA_ACCESS) ~= nil
	local checkingMic = Cryo.List.find(permissionsToCheck, PermissionsProtocol.Permissions.MICROPHONE_ACCESS) ~= nil

	-- early out if no permissions are to be checked.
	if not permissionsToCheck or #permissionsToCheck <= 0 then
		local response = {
			hasCameraPermissions = false,
			hasMicPermissions = false,
		}

		callback(response)
		return
	end
	-- First check if permissions were already given.
	return PermissionsProtocol:hasPermissions(permissionsToCheck):andThen(function(hasPermissionsResult)
		-- If permissions have already granted
		if hasPermissionsResult.status == PermissionsProtocol.Status.AUTHORIZED then
			local response = {
				hasCameraPermissions = checkingCamera,
				hasMicPermissions = checkingMic,
			}

			callback(response)
			inProgress = false
			invokeNextRequest()
			return hasPermissionsResult
		else
			-- Requesting any permissions that have not been given yet.
			return PermissionsProtocol:requestPermissions(permissionsToCheck):andThen(function(requestPermissionsResult)
				-- If the return value is a table, that means permissions have different values.
				if typeof(requestPermissionsResult) == "table" then
					local hasCameraPermissionsResponse = checkingCamera and (requestPermissionsResult.status == PermissionsProtocol.Status.AUTHORIZED
						or not Cryo.List.find(requestPermissionsResult.missingPermissions, PermissionsProtocol.Permissions.CAMERA_ACCESS))
					local hasMicPermissionsResponse = checkingMic and (requestPermissionsResult.status == PermissionsProtocol.Status.AUTHORIZED
						or not Cryo.List.find(requestPermissionsResult.missingPermissions, PermissionsProtocol.Permissions.MICROPHONE_ACCESS))

					hasCameraPermissions = if cacheCamera then hasCameraPermissionsResponse else nil
					hasMicPermissions = if cacheMic then hasMicPermissionsResponse else nil
				else
					-- If all permissions were authorized
					if requestPermissionsResult == PermissionsProtocol.Status.AUTHORIZED then
						hasCameraPermissions = checkingCamera
						hasMicPermissions = checkingMic
					else
						-- Fall back to denied
						hasCameraPermissions = false
						hasMicPermissions = false
					end
				end

				local response = {
					hasCameraPermissions = hasCameraPermissions or false,
					hasMicPermissions = hasMicPermissions or false,
				}

				-- Remove with AVBURST-12354 once the C++ side fixes this.
				if FFlagAvatarChatLuaCameraToast and checkingCamera and not hasCameraPermissions then
					TrackerMenu:showPrompt(TrackerPromptType.VideoNoPermission)
				end

				callback(response)
				inProgress = false
				invokeNextRequest()

				return requestPermissionsResult
			end)
		end
	end)
end

type CachedResult = {
	hasCameraPermissions : boolean,
	hasMicPermissions : boolean,
}

local function tryGetCachedResults(permsToCheck) : CachedResult?
	if hasCameraPermissions == nil or hasMicPermissions == nil then
		return nil
	end

	local hasOtherPermissions = false
	for _, permission in permsToCheck do
		if permission ~= PermissionsProtocol.Permissions.MICROPHONE_ACCESS and permission ~= PermissionsProtocol.Permissions.CAMERA_ACCESS then
			hasOtherPermissions = true
		end
	end

	if hasOtherPermissions then
		return nil
	end

	return {
		hasCameraPermissions = hasCameraPermissions or false,
		hasMicPermissions = hasMicPermissions or false,
	}
end

-- TODO Make callback required with removal of FFlagUpdateCamMicPermissioning
local function getCamMicPermissions(callback, permissionsToRequest: Array<string>?)
	local permsToCheck: Array<string> = {}
	if permissionsToRequest then
		permsToCheck = permissionsToRequest
	else
		permsToCheck = {
			PermissionsProtocol.Permissions.MICROPHONE_ACCESS,
			PermissionsProtocol.Permissions.CAMERA_ACCESS,
		}
	end

	-- A function to call the next request in the queue.
	local function invokeNextRequest()
		if requestPermissionsQueue[1] then
			local nextRequest = requestPermissionsQueue[1]
			table.remove(requestPermissionsQueue, 1)
			getCamMicPermissions(nextRequest.callback, nextRequest.permsToCheck)
		end
	end

	if FFlagAvatarChatCoreScriptSupport or FFlagSelfieViewEnabled then
		local cachedResults = tryGetCachedResults(permsToCheck)
		if cachedResults then
			callback(cachedResults)
			invokeNextRequest()
			return
		end
	end

	-- A request is already in progress. Queue up another call to this function.
	if inProgress then
		table.insert(requestPermissionsQueue, {
			callback = callback,
			permissionsToRequest = permissionsToRequest,
		})

		return
	end

	inProgress = true

	if FFlagAvatarChatCoreScriptSupport or FFlagSelfieViewEnabled then
		if GetFFlagAvatarChatServiceEnabled() then
			return Promise.new(function(resolve, _)
				if AvatarChatService.ClientFeaturesInitialized then
					local combinedAllowedSettings : AllowedSettings = {
						isVoiceEnabled = AvatarChatService:IsEnabled(AvatarChatService.ClientFeatures, Enum.AvatarChatServiceFeature.UserAudio),
						isCameraEnabled = AvatarChatService:IsEnabled(AvatarChatService.ClientFeatures, Enum.AvatarChatServiceFeature.UserVideo)
					}
					resolve(combinedAllowedSettings)
				else
					local clientFeaturesChangedListener
					clientFeaturesChangedListener = AvatarChatService:GetPropertyChangedSignal("ClientFeatures"):Connect(function()
						clientFeaturesChangedListener:Disconnect()
						local combinedAllowedSettings : AllowedSettings = {
							isVoiceEnabled = AvatarChatService:IsEnabled(AvatarChatService.ClientFeatures, Enum.AvatarChatServiceFeature.UserAudio),
							isCameraEnabled = AvatarChatService:IsEnabled(AvatarChatService.ClientFeatures, Enum.AvatarChatServiceFeature.UserVideo)
						}
						resolve(combinedAllowedSettings)
					end)
				end
			end):andThen(function(allowedSettings)
				requestPermissions(allowedSettings, callback, invokeNextRequest, permsToCheck)
			end)
		else
			local placeSettingsPromise = Promise.new(function(resolve, _)
				-- Check that the game has enabled camera and microphone in game settings
				local placeSettings = getPlaceVoiceCameraEnabled()
				local allowedSettings : AllowedSettings = {
					isVoiceEnabled = placeSettings.isVoiceEnabledPlaceSettings,
					isCameraEnabled = placeSettings.isCameraEnabledPlaceSettings,
				}
				resolve(allowedSettings)
			end)

			local userSettingsPromise = Promise.new(function(resolve, _)
				-- Check that the user has enabled voice/camera on their roblox account,
				-- and that the universe and place has it enabled as well.
				local userSettings = getVoiceCameraAccountSettings()
				local allowedSettings : AllowedSettings = {
					isVoiceEnabled = userSettings.isVoiceEnabledUserSettings,
					isCameraEnabled = userSettings.isCameraEnabledUserSettings,
				}
				resolve(allowedSettings)
			end)

			return Promise.all({
				placeSettingsPromise,
				userSettingsPromise,
			}):andThen(function(results)
				local placeSettingsResult = results[1] :: AllowedSettings
				local userSettingsResult = results[2] :: AllowedSettings
				local combinedAllowedSettings : AllowedSettings = {
					isVoiceEnabled = placeSettingsResult.isVoiceEnabled and userSettingsResult.isVoiceEnabled,
					isCameraEnabled = placeSettingsResult.isCameraEnabled and userSettingsResult.isCameraEnabled,
				}
				return combinedAllowedSettings
			end):andThen(function(allowedSettings)
				requestPermissions(allowedSettings, callback, invokeNextRequest, permsToCheck)
			end)
		end
	else
		return Promise.new(function(resolve, _)
			-- First check that the user has enabled voice/camera on their roblox account,
			-- and that the universe and place has it enabled as well.
			local userSettings = getVoiceCameraAccountSettings()
			local allowedSettings : AllowedSettings = {
				isVoiceEnabled = userSettings.isVoiceEnabledUserSettings,
				isCameraEnabled = userSettings.isCameraEnabledUserSettings,
			}
			resolve(allowedSettings)
		end):andThen(function(allowedSettings)
			requestPermissions(allowedSettings, callback, invokeNextRequest, permsToCheck)
		end)
	end
end

return getCamMicPermissions

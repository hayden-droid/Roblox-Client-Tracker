--[[
	Prompt to import an asset using the AssetImportService.
]]
local AssetImportService = game:GetService("AssetImportService")

local Plugin = script.Parent.Parent.Parent

local SetAssetImportSession = require(Plugin.Src.Actions.SetAssetImportSession)
local SetAssetSettings = require(Plugin.Src.Actions.SetAssetSettings)
local SetFilename = require(Plugin.Src.Actions.SetFilename)
local SetInstanceMap = require(Plugin.Src.Actions.SetInstanceMap)
local SetSelectedSettingsItem = require(Plugin.Src.Actions.SetSelectedSettingsItem)
local SetTreeChecked = require(Plugin.Src.Actions.SetTreeChecked)
local SetImportStatuses = require(Plugin.Src.Actions.SetImportStatuses)
local UpdatePreviewInstance = require(Plugin.Src.Thunks.UpdatePreviewInstance)

local UpdateChecked = require(Plugin.Src.Thunks.UpdateChecked)

local getFFlagUseAssetImportSession = require(Plugin.Src.Flags.getFFlagUseAssetImportSession)
local getFFlagAssetImportSessionCleanup = require(Plugin.Src.Flags.getFFlagAssetImportSessionCleanup)

return function(promptClosedHandler)
	return function(store)
		local session
		local settings, filename, statuses

		if (getFFlagUseAssetImportSession()) then
			session = AssetImportService:StartSessionWithPrompt()
			if session then
				settings = session:GetSettingsRoot()
				filename = session:GetFilename()
				statuses = session:GetCurrentStatusTable()
			end
		else
			 settings, filename, statuses = AssetImportService:ImportMeshWithPrompt()
		end

		if settings and filename then
			local instanceMap
			local previewInstance
			if getFFlagAssetImportSessionCleanup() then
				previewInstance = session:GetInstance(settings.Id)
			else
				if getFFlagUseAssetImportSession() then
					instanceMap = session:GetCurrentImportMap()
				else
					instanceMap = AssetImportService:GetCurrentImportMap()
				end
			end

			local checked = {}

			local function recurse(generation)
				for _, child in pairs(generation) do
					checked[child] = child["ShouldImport"]

					local children = child:GetChildren()
					if children then
						recurse(children)
					end
				end
			end

			recurse(settings:GetChildren())
			checked[settings] = true
			
			if getFFlagAssetImportSessionCleanup() then
				store:dispatch(UpdatePreviewInstance(previewInstance))
			else
				store:dispatch(SetInstanceMap(instanceMap))
			end

			store:dispatch(SetAssetSettings(settings))
			store:dispatch(SetFilename(filename))
			store:dispatch(SetSelectedSettingsItem(settings))
			store:dispatch(UpdateChecked(checked))
		end

		store:dispatch(SetImportStatuses(statuses))

		if (getFFlagUseAssetImportSession()) then
			store:dispatch(SetAssetImportSession(session))
		end

		if promptClosedHandler then
			if (getFFlagUseAssetImportSession()) then
				local success = settings ~= nil and filename ~= nil
				-- No session returned if no file was selected
				local closed = session == nil
				promptClosedHandler(success, closed)
			else
				local success = settings ~= nil and filename ~= nil
				-- An empty string is returned if no file was selected
				local closed = filename == ""
				promptClosedHandler(success, closed)
			end
		end
	end
end

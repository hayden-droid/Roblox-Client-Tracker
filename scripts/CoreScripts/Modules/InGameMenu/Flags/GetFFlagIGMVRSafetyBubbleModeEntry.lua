game:DefineFastFlag("IGMVRSafetyBubbleModeEntry2", false)

return function()
	return game:GetEngineFeature("EnableMaquettesSupport") -- enable with FFlag: UserMaquettesSupportEnabled
		or game:GetFastFlag("IGMVRSafetyBubbleModeEntry2")
end

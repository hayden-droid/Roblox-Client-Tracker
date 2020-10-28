local Page = script.Parent.Parent

return function(state, groupId)
	local metadata = state.Settings.Changed.groupMetadata or state.Settings.Current.groupMetadata
	local groupMetadata = metadata[groupId]

	return groupMetadata.Name
end
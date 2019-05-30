--[[
	An item that displays a list of collaborators who have permissions to access, edit, and manage the game
	These collaborators can be removed or have their permission level changed

	Props:
		PermissionsChanged(newPermissions) - Dispatch function to fire when permissions change
		GroupMetadataChanged(newGroupMetadata) - Dispatch function to fire when groupMetadata changes

		GroupMetadata - Id, Name, and permissions for groups
		Permissions - Permissions for all users/roles
		
		bool Enabled - Whether the component is enabled or not
		int [LayoutOrder = 0]
]]

local Plugin = script.Parent.Parent.Parent.Parent
local Roact = require(Plugin.Roact)
local Cryo = require(Plugin.Cryo)
local withTheme = require(Plugin.Src.Consumers.withTheme)
local withLocalization = require(Plugin.Src.Consumers.withLocalization)

local PermissionsConstants = require(Plugin.Src.Components.Permissions.PermissionsConstants)

local getThumbnailLoader = require(Plugin.Src.Consumers.getThumbnailLoader)
local CollaboratorItem = require(Plugin.Src.Components.Permissions.CollaboratorItem)
local GroupCollaboratorItem = require(Plugin.Src.Components.Permissions.GroupCollaboratorItem)
local createFitToContent = require(Plugin.Src.Components.createFitToContent)

local FitToContentWidget = createFitToContent("Frame", "UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 32),
})

local FitToContentList = createFitToContent("Frame", "UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 0),
})

local function getGroupCollaboratorPermissions(props, localized)
	local permissions = {
		{Key = PermissionsConstants.PlayKey, Display = localized.AccessPermissions.ActionDropdown.PlayLabel, Description = localized.AccessPermissions.ActionDropdown.PlayDescription},
		{Key = PermissionsConstants.EditKey, Display = localized.AccessPermissions.ActionDropdown.EditLabel, Description = localized.AccessPermissions.ActionDropdown.EditDescription},
	}
	
	if props.GroupOwnerUserId and props.GroupOwnerUserId == props.StudioUserId then
		permissions = Cryo.List.join(
			permissions,
			{Key = PermissionsConstants.AdminKey, Display = localized.AccessPermissions.ActionDropdown.AdminLabel, Description = localized.AccessPermissions.ActionDropdown.AdminDescription}
		)
	end
	
	return permissions
end

local function getUserCollaboratorPermissions(props, localized)
	local permissions = {
		{Key = PermissionsConstants.PlayKey, Display = localized.AccessPermissions.ActionDropdown.PlayLabel, Description = localized.AccessPermissions.ActionDropdown.PlayDescription},
		{Key = PermissionsConstants.EditKey, Display = localized.AccessPermissions.ActionDropdown.EditLabel, Description = localized.AccessPermissions.ActionDropdown.EditDescription},
	}
	
	if props.GroupOwnerUserId and props.GroupOwnerUserId == props.StudioUserId then
		permissions = Cryo.List.join(
			permissions,
			{Key = PermissionsConstants.AdminKey, Display = localized.AccessPermissions.ActionDropdown.AdminLabel, Description = localized.AccessPermissions.ActionDropdown.AdminDescription}
		)
	end
	
	return permissions
end

local function getLabelForAction(localized, action)
	if action == PermissionsConstants.NoAccessKey then
		return localized.AccessPermissions.ActionDropdown.NoAccessLabel
	elseif action == PermissionsConstants.PlayKey then
		return localized.AccessPermissions.ActionDropdown.PlayLabel
	elseif action == PermissionsConstants.EditKey then
		return localized.AccessPermissions.ActionDropdown.EditLabel
	elseif action == PermissionsConstants.AdminKey then
		return localized.AccessPermissions.ActionDropdown.AdminLabel
	else
		return ""
	end
end

local CollaboratorsWidget = Roact.PureComponent:extend("CollaboratorsWidget")

function CollaboratorsWidget:render()
	local props = self.props
	local thumbnailLoader = getThumbnailLoader(self)

	return withLocalization(function(localized)
		return withTheme(function(theme)
			local function rolePermissionChanged(roleId, newPermission)
				local roleData = props.Permissions[PermissionsConstants.RoleSubjectKey][roleId]
				local groupId = roleData[PermissionsConstants.GroupIdKey]

				local newGroupMetadata = Cryo.Dictionary.join(props.GroupMetadata, {[groupId] = Cryo.Dictionary.join(props.GroupMetadata[groupId], {Action=PermissionsConstants.NoAccessKey})})

				local newPermissions = 	Cryo.Dictionary.join(props.Permissions, {[PermissionsConstants.RoleSubjectKey]=Cryo.Dictionary.join(
											props.Permissions[PermissionsConstants.RoleSubjectKey], {[roleId]=Cryo.Dictionary.join(
												props.Permissions[PermissionsConstants.RoleSubjectKey][roleId], {[PermissionsConstants.ActionKey]=newPermission}
											)}
										)})
				
				props.PermissionsChanged(newPermissions)
				props.GroupMetadataChanged(newGroupMetadata)
			end

			local function groupPermissionChanged(groupId, newPermission)
				local newGroupMetadata = Cryo.Dictionary.join(props.GroupMetadata, {[groupId] = Cryo.Dictionary.join(props.GroupMetadata[groupId], {Action=newPermission})})

				local nonePermissions = {}
				for roleId,roleData in pairs(props.Permissions[PermissionsConstants.RoleSubjectKey]) do
					if roleData[PermissionsConstants.GroupIdKey] == groupId then
						nonePermissions[roleId] = Cryo.Dictionary.join(roleData, {[PermissionsConstants.ActionKey]=newPermission})
					end
				end

				local newPermissions = Cryo.Dictionary.join(props.Permissions, {[PermissionsConstants.RoleSubjectKey]=Cryo.Dictionary.join(
					props.Permissions[PermissionsConstants.RoleSubjectKey], nonePermissions
				)})

				props.PermissionsChanged(newPermissions)
				props.GroupMetadataChanged(newGroupMetadata)
			end

			local function userPermissionChanged(userId, newPermission)
				local newPermissions = 	Cryo.Dictionary.join(props.Permissions, {[PermissionsConstants.UserSubjectKey]=Cryo.Dictionary.join(
											props.Permissions[PermissionsConstants.UserSubjectKey], {[userId]=Cryo.Dictionary.join(
												props.Permissions[PermissionsConstants.UserSubjectKey][userId], {[PermissionsConstants.ActionKey]=newPermission}
											)}
										)})
				
				props.PermissionsChanged(newPermissions)
			end

			local function groupRemoved(groupId)
				local newGroupMetadata = Cryo.Dictionary.join(props.GroupMetadata, {[groupId] = Cryo.None})

				groupPermissionChanged(groupId, PermissionsConstants.NoAccessKey)

				props.GroupMetadataChanged(newGroupMetadata)
			end

			local function userRemoved(userId)
				local newPermissions = 	Cryo.Dictionary.join(props.Permissions, {[PermissionsConstants.UserSubjectKey]=Cryo.Dictionary.join(
											props.Permissions[PermissionsConstants.UserSubjectKey], {[userId]=Cryo.None}
										)})
				
				props.PermissionsChanged(newPermissions)
			end
		
			-- Sort groups by alphabetical order for collaborator list
			local groups = {}
			for groupId,groupData in pairs(props.GroupMetadata) do
				if game.CreatorType ~= Enum.CreatorType.Group or game.CreatorId ~= groupId then
					table.insert(groups, {Name=groupData.Name, Id=groupId})
				end
			end
			table.sort(groups, function(a,b)
				return a.Name < b.Name
			end)

			-- Sort users by alphabetical order for collaborator list
			local users = {}
			for userId,permission in pairs(props.Permissions[PermissionsConstants.UserSubjectKey]) do
				if game.CreatorType ~= Enum.CreatorType.User or game.CreatorId ~= userId then
					table.insert(users, {Name=permission[PermissionsConstants.SubjectNameKey], Id=permission[PermissionsConstants.SubjectIdKey], Action=permission[PermissionsConstants.ActionKey]})
				end
			end
			table.sort(users, function(a,b)
				return a.Name < b.Name
			end)
			
			-- Roact elements built from users and groups tables
			local userCollaborators = {}
			local groupCollaborators = {}
			
			for i,user in pairs(users) do
				userCollaborators["User"..i] = Roact.createElement(CollaboratorItem, {
					LayoutOrder = i,
					Enabled = props.Enabled,
					
					CollaboratorName = user.Name,
					CollaboratorId = user.Id,
					CollaboratorIcon = thumbnailLoader.getThumbnail(PermissionsConstants.UserSubjectKey, user.Id),

					Items = getUserCollaboratorPermissions(props, localized),
					Action = getLabelForAction(localized, user.Action),

					Removable = true,
					Removed = function() userRemoved(user.Id) end,
					PermissionChanged = function(newPermission) userPermissionChanged(user.Id, newPermission) end,
					HideLastSeparator = i ~= #users,
				})
			end
			for i,group in pairs(groups) do
				if game.CreatorType ~= Enum.CreatorType.Group or game.CreatorId ~= group.Id then
					groupCollaborators["Groups"..i] = Roact.createElement(GroupCollaboratorItem, {
						LayoutOrder = i,
						Enabled = props.Enabled,
						
						GroupName = group.Name,
						GroupId = group.Id,
						Rolesets = group.RolePermissions,
						Permissions = props.Permissions,
						Items = getGroupCollaboratorPermissions(props, localized),

						RolePermissionChanged = rolePermissionChanged,
						GroupPermissionChanged = groupPermissionChanged,
						
						Removable = true,
						Removed = function() groupRemoved(group.Id) end,
						HideLastSeparator = i ~= #groups,
						Thumbnails = props.Thumbnails,
					})
				end
			end

			return Roact.createElement(FitToContentWidget, {
				LayoutOrder = props.LayoutOrder or 0,
				BackgroundTransparency = 1,
			}, {
				UsersTitle = Roact.createElement("TextLabel", Cryo.Dictionary.join(theme.fontStyle.Subtitle, {
					LayoutOrder = 0,
					
					Text = "Users",
					TextXAlignment = Enum.TextXAlignment.Left,
					
					Visible = #users > 0,
					BackgroundTransparency = 1,
				})),
				
				Users = Roact.createElement(FitToContentList, {
					LayoutOrder = 1,
					BackgroundTransparency = 1,
				}, userCollaborators),
				
				GroupsTitle = Roact.createElement("TextLabel", Cryo.Dictionary.join(theme.fontStyle.Subtitle, {
					LayoutOrder = 2,
					
					Text = "Groups",
					TextXAlignment = Enum.TextXAlignment.Left,
					
					Visible = #groups > 0,
					BackgroundTransparency = 1,
				})),
				
				Groups = Roact.createElement(FitToContentList, {
					LayoutOrder = 3,
					BackgroundTransparency = 1,
				}, groupCollaborators),
			})
		end)
	end)
end

return CollaboratorsWidget
local ExperienceTileMetadata = script.Parent
local Tile = ExperienceTileMetadata.Parent
local App = Tile.Parent
local UIBlox = App.Parent
local Packages = UIBlox.Parent

local Cryo = require(Packages.Cryo)
local React = require(Packages.React)

local ImageSetLabel = require(UIBlox.Core.ImageSet.ImageSetComponent).Label
local GenericTextLabel = require(UIBlox.Core.Text.GenericTextLabel.GenericTextLabel)
local useStyle = require(UIBlox.Core.Style.useStyle)
local StyleTypes = require(UIBlox.App.Style.StyleTypes)

export type StyleProps = {
	-- Spacing between faces and label
	containerGap: number?,

	-- Spacing between two faces
	faceGroupGap: number?,

	-- Color of face icon background
	faceBackgroundColor: StyleTypes.ThemeItem?,
	-- Border thickness of face icon
	faceBorderWidth: number?,
	-- Color of face icon border
	faceBorderColor: StyleTypes.ThemeItem?,
	-- Radius of face icon border
	faceBorderRadius: number?,
	-- The width of face icon
	faceWidth: number?,
	-- The height of face icon
	faceHeight: number?,

	-- Color of badge background
	badgeBackgroundColor: StyleTypes.ThemeItem?,
	-- Border width of badge
	badgeBorderWidth: number?,
	-- Color of badge border
	badgeBorderColor: StyleTypes.ThemeItem?,
	-- Radius of badge border
	badgeBorderRadius: number?,
	-- Leading padding inside badge
	badgeSpacingLeading: number?,
	-- Trailing padding inside badge
	badgeSpacingTrailing: number?,
	-- Height of badge
	badgeHeight: number?,
	-- Color of badge content
	badgeContentColor: StyleTypes.ThemeItem?,

	-- Color of label content
	labelContentColor: StyleTypes.ThemeItem?,
}

export type Props = {
	-- A list of user IDs that are used to get avatars to show
	users: { [number]: string },
	-- Text to be displayed in label
	labelText: string?,

	-- Number of faces to be displayed
	faceGroupCount: number?,
	-- Max number to be displayed in badge
	maxBadgeDisplayNumber: number?,
	-- Size of FacePile
	size: UDim2?,
	-- Position of FacePile
	position: UDim2?,
	-- AnchorPoint of FacePile
	anchorPoint: Vector2?,
	-- LayoutOrder of FacePile
	layoutOrder: number?,

	-- Style props for component
	styleProps: StyleProps?,
}

type BadgeProps = {
	usersCount: number,
	layoutOrder: number,
	zIndex: number,
	maxDisplayNumber: number,
}

type FaceProps = {
	user: string,
	layoutOrder: number,
	zIndex: number,
}

type CornerStrokeProps = {
	borderWidth: number,
	borderColor: StyleTypes.ThemeItem,
	borderRadius: number,
}

local defaultProps = {
	size = UDim2.fromScale(1, 1),
	faceGroupCount = 3,
	maxBadgeDisplayNumber = 99,
	styleProps = {},
}

local defaultStyleProps = {
	containerGap = 6,

	faceGroupGap = -9,

	faceBorderWidth = 3,
	faceBorderRadius = 50,
	faceWidth = 24,
	faceHeight = 24,

	badgeBorderWidth = 3,
	badgeBorderRadius = 50,
	badgeSpacingLeading = 9,
	badgeSpacingTrailing = 9,
	badgeHeight = 24,
}

local function getAvatarImage(userId: string)
	return string.format("rbxthumb://type=AvatarHeadShot&id=%s&w=150&h=150", tostring(userId))
end

local function renderCornerStroke(props: CornerStrokeProps)
	return React.createElement(React.Fragment, nil, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, props.borderRadius),
		}),
		Stroke = React.createElement("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = props.borderColor.Color,
			Transparency = props.borderColor.Transparency,
			Thickness = props.borderWidth,
		}),
	})
end

local function renderBadge(props: BadgeProps, styleProps: StyleProps, style: StyleTypes.AppStyle)
	local text: string
	if props.usersCount > props.maxDisplayNumber then
		text = tostring(props.maxDisplayNumber) .. "+"
	else
		text = tostring(props.usersCount)
	end

	local theme = style.Theme
	local font = style.Font

	local badgeBackgroundColor = styleProps.badgeBackgroundColor or theme.ContextualPrimaryDefault
	local badgeBorderWidth = styleProps.badgeBorderWidth :: number
	local badgeBorderColor = styleProps.badgeBorderColor or style.Theme.BackgroundUIDefault
	local badgeBorderRadius = styleProps.badgeBorderRadius :: number
	local badgeSpacingLeading = styleProps.badgeSpacingLeading
	local badgeSpacingTrailing = styleProps.badgeSpacingTrailing
	local badgeHeight = styleProps.badgeHeight :: number
	local badgeContentColor = styleProps.badgeContentColor or theme.ContextualPrimaryContent

	return React.createElement("Frame", {
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex,
		Size = UDim2.fromOffset(0, badgeHeight),
		BorderSizePixel = 0,
		BackgroundColor3 = badgeBackgroundColor.Color,
		BackgroundTransparency = badgeBackgroundColor.Transparency,
		AutomaticSize = Enum.AutomaticSize.X,
	}, {
		renderCornerStroke({
			borderWidth = badgeBorderWidth,
			borderColor = badgeBorderColor,
			borderRadius = badgeBorderRadius,
		}),
		SizeConstraint = React.createElement("UISizeConstraint", {
			MinSize = Vector2.new(badgeHeight, 0),
		}),
		Content = React.createElement("TextLabel", {
			Size = UDim2.fromScale(0, 1),
			BorderSizePixel = 0,
			Text = text,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			Font = font.CaptionHeader.Font,
			TextSize = font.BaseSize * font.CaptionHeader.RelativeSize,
			TextColor3 = badgeContentColor.Color,
			TextTransparency = badgeContentColor.Transparency,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
		}, {
			Padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, badgeSpacingLeading),
				PaddingRight = UDim.new(0, badgeSpacingTrailing),
			}),
		}),
	})
end

local function renderFaceImage(props: FaceProps, styleProps: StyleProps, style: StyleTypes.AppStyle)
	local faceBackgroundColor = styleProps.faceBackgroundColor or style.Theme.TextDefault
	local faceBorderWidth = styleProps.faceBorderWidth :: number
	local faceBorderColor = styleProps.faceBorderColor or style.Theme.BackgroundUIDefault
	local faceBorderRadius = styleProps.faceBorderRadius :: number
	local faceWidth = styleProps.faceWidth :: number
	local faceHeight = styleProps.faceHeight :: number

	return React.createElement(ImageSetLabel, {
		LayoutOrder = props.layoutOrder,
		ZIndex = props.zIndex,
		Size = UDim2.fromOffset(faceWidth, faceHeight),
		Image = getAvatarImage(props.user),
		BackgroundColor3 = faceBackgroundColor.Color,
		BackgroundTransparency = faceBackgroundColor.Transparency,
		BorderSizePixel = 0,
	}, {
		renderCornerStroke({
			borderWidth = faceBorderWidth,
			borderColor = faceBorderColor,
			borderRadius = faceBorderRadius,
		}),
	})
end

local function renderFaces(props: Props, styleProps: StyleProps, style: StyleTypes.AppStyle)
	local users = props.users
	local faceGroupGap = styleProps.faceGroupGap
	local badgeBorderWidth = styleProps.badgeBorderWidth :: number
	local faceBorderWidth = styleProps.faceBorderWidth :: number
	local paddingTopBottom = math.max(badgeBorderWidth, faceBorderWidth)

	local faces = {
		ListLayout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, faceGroupGap),
		}),
		Padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, badgeBorderWidth),
			PaddingTop = UDim.new(0, paddingTopBottom),
			PaddingRight = UDim.new(0, faceBorderWidth),
			PaddingBottom = UDim.new(0, paddingTopBottom),
		}),
		Badge = renderBadge({
			usersCount = #users,
			layoutOrder = 0,
			zIndex = 0,
			maxDisplayNumber = props.maxBadgeDisplayNumber :: number,
		}, styleProps, style),
	}

	for i = 1, math.min(props.faceGroupCount :: number, #users) do
		faces["Face_" .. i] = renderFaceImage({
			user = users[i],
			layoutOrder = i,
			zIndex = -i,
		}, styleProps, style)
	end

	return React.createElement("Frame", {
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, faces :: any)
end

local function CoPlayFooter(passedProps: Props): React.ReactElement?
	local props = Cryo.Dictionary.join(defaultProps, passedProps)
	if not props.users or #props.users == 0 then
		return nil
	end

	local style = useStyle()
	local facesFrameSize, updateFacesFrameSize = React.useBinding(Vector2.new(0, 0))
	local styleProps = Cryo.Dictionary.join(defaultStyleProps, props.styleProps)

	local containerGap = styleProps.containerGap
	local labelContentColor = styleProps.labelContentColor or style.Theme.TextMuted

	local onFacesFrameSizeChange = React.useCallback(function(rbx)
		updateFacesFrameSize(rbx.AbsoluteSize)
	end, { updateFacesFrameSize })

	return React.createElement("Frame", {
		Size = props.size,
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
	}, {
		ListLayout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, containerGap),
		}),
		FacesFrame = React.createElement("Frame", {
			LayoutOrder = 1,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.XY,
			[React.Change.AbsoluteSize] = onFacesFrameSizeChange,
		}, {
			Faces = renderFaces(props, styleProps, style),
		}),
		LabelFrame = if props.labelText
			then React.createElement("Frame", {
				LayoutOrder = 2,
				Size = facesFrameSize:map(function(value: Vector2)
					return UDim2.new(1, -value.X - containerGap, 1, 0)
				end),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
			}, {
				Label = React.createElement(GenericTextLabel, {
					Size = UDim2.fromScale(1, 1),
					Text = props.labelText,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextWrapped = false,
					fontStyle = style.Font.CaptionBody,
					colorStyle = labelContentColor,
				}),
			})
			else nil,
	})
end

return CoPlayFooter

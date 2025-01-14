local GuiService = game:GetService("GuiService")

return {
	ChatInputBarFont = Enum.Font.GothamMedium,
	ChatInputBarFontFace = Font.new(
		"rbxasset://fonts/families/GothamSSm.json",
		Enum.FontWeight.Medium,
		Enum.FontStyle.Normal
	),

	ChatInputBarTextColor3 = Color3.fromRGB(255, 255, 255),
	ChatInputBarTextSize = 14,
	ChatInputBarTextStrokeColor = Color3.fromRGB(0, 0, 0),
	ChatInputBarTextStrokeTransparency = 0.5,

	ChatInputBarPlaceholderColor = Color3.fromRGB(178, 178, 178),

	ChatInputBarBackgroundColor = Color3.fromRGB(25, 27, 29),
	ChatInputBarBackgroundTransparency = 0.2,

	ChatInputBarBorderColor3 = Color3.fromRGB(255, 255, 255),
	ChatInputBarBorderTransparency = 0.8,
	ChatInputBarDefaultFocusKeyCode = Enum.KeyCode.Slash,

	ChatLayoutPosition = UDim2.new(0, 8, 0, 4),
	ChatLayoutAnchorPoint = Vector2.new(0, 0),

	ChatWindowSize = UDim2.fromScale(0.4, 0.25),

	ChatWindowFont = Font.new(
		"rbxasset://fonts/families/GothamSSm.json",
		Enum.FontWeight.Medium,
		Enum.FontStyle.Normal
	),
	ChatWindowTextColor3 = Color3.fromRGB(255, 255, 255),
	ChatWindowTextSize = 14,
	ChatWindowTextStrokeColor = Color3.fromRGB(0, 0, 0),
	ChatWindowTextStrokeTransparency = 0.5,

	ChatWindowBackgroundColor3 = Color3.fromRGB(25, 27, 29),
	ChatWindowBackgroundTransparency = 0.3,

	ChatWindowBackgroundFadeOutTime = 3.5,
	ChatWindowTextFadeOutTime = 30,

	ChatWindowMaxWidth = 475,
	ChatWindowMaxHeight = 275,

	DefaultChannelNames = {
		["RBXGeneral"] = true,
		["RBXSystem"] = true,
	},

	MessageCharacterLimit = 200,

	VERIFIED_EMOJI = utf8.char(0xE000),

	TopBarVerticalOffset = GuiService:GetGuiInset().Y,

	DefaultBubbleChatChildrenCustomizationProperties = {
		ImageLabel = {
			Image = "",
			ImageColor3 = Color3.new(1, 1, 1),
			ImageRectOffset = Vector2.new(),
			ImageRectSize = Vector2.new(),
			ScaleType = Enum.ScaleType.Stretch,
			SliceCenter = Rect.new(Vector2.new(), Vector2.new()),
			SliceScale = 1,
			TileSize = UDim2.fromScale(1, 1),
		},
		UIGradient = {
			Enabled = false,
			Color = ColorSequence.new(Color3.fromRGB(150, 150, 150), Color3.fromRGB(250, 250, 250)),
			Offset = Vector2.new(),
			Rotation = 0,
			Transparency = NumberSequence.new(0),
		},
		UICorner = {
			CornerRadius = UDim.new(0, 12),
		},
	},
}

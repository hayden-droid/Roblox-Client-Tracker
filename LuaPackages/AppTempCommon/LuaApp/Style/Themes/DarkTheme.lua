local ThemesRoot = script.Parent
local StylesRoot = ThemesRoot.Parent
local Colors = require(StylesRoot.Colors)

local theme = {
	BackgroundDefault = {
		Color = Colors.Slate,
		Transparency = 0,
	},
	BackgroundContrast = {
		Color = Colors.Carbon,
		Transparency = 0,
	},
	BackgroundMuted = {
		Color = Colors.Obsidian,
		Transparency = 0,
	},
	BackgroundUIDefault = {
		Color = Colors.Flint,
		Transparency = 0,
	},
	BackgroundUIContrast = {
		Color = Colors.Black,
		Transparency = 0.3, -- Alpha 0.7
	},
	BackgroundOnHover = {
		Color = Colors.White,
		Transparency = 0.9, -- Alpha 0.1
	},
	BackgroundOnPress = {
		Color = Colors.Black,
		Transparency = 0.7, -- Alpha 0.3
	},

	UIDefault = {
		Color = Colors.Graphite,
		Transparency = 0,
	},
	UIMuted = {
		Color = Colors.Black,
		Transparency = 0.3, -- Alpha 0.7
	},
	UIEmphasis = {
		Color = Colors.White,
		Transparency = 0.7, -- Alpha 0.3
	},

	ContextualPrimaryDefault = {
		Color = Colors.Green,
		Transparency = 0,
	},
	ContextualPrimaryOnHover = {
		Color = Colors.Green,
		Transparency = 0,
	},
	ContextualPrimaryContent = {
		Color = Colors.White,
		Transparency = 0,
	},

	SystemPrimaryDefault = {
		Color = Colors.White,
		Transparency = 0,
	},
	SystemPrimaryOnHover = {
		Color = Colors.White,
		Transparency = 0,
	},
	SystemPrimaryContent = {
		Color = Colors.Flint,
		Transparency = 0,
	},

	SecondaryDefault = {
		Color = Colors.White,
		Transparency = 0.3, -- 0.7 Alpha
	},
	SecondaryOnHover = {
		Color = Colors.White,
		Transparency = 0,
	},
	SecondaryContent = {
		Color = Colors.White,
		Transparency = 0.3, -- 0.7 Alpha
	},

	TextEmphasis = {
		Color = Colors.White,
		Transparency = 0,
	},
	TextDefault = {
		Color = Colors.Pumice,
		Transparency = 0,
	},
	TextMuted = {
		Color = Colors.White,
		Transparency = 0.3, -- 0.7 Alpha
	},

	Divider = {
		Color = Colors.Graphite,
		Transparency = 0,
	},
	Overlay = {
		Color = Colors.Black,
		Transparency = 0.3, -- 0.7 Alpha
	},
	DropShadow = {
		Color = Colors.Black,
		Transparency = 0,
	},
	NavigationBar = {
		Color = Colors.Carbon,
		Transparency = 0,
	},
	PlaceHolder = {
		Color = Colors.Flint,
		Transparency = 0.5, -- 0.5 Alpha
	},

	OnlineStatus = {
		Color = Colors.Green,
		Transparency = 0.5, -- 0.5 Alpha
	},
	OfflineStatus = {
		Color = Colors.White,
		Transparency = 0.3, -- 0.7 Alpha
	},

	Success = {
		Color = Colors.Green,
		Transparency = 0,
	},
	Alert = {
		Color = Colors.Red,
		Transparency = 0,
	},
}

return theme
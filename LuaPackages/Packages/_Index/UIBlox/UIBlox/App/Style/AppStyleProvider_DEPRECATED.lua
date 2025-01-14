--[[
	The is a wrapper for the style provider for apps.
]]
local Style = script.Parent
local Core = Style.Parent
local UIBlox = Core.Parent
local Packages = UIBlox.Parent
local Roact = require(Packages.Roact)
local t = require(Packages.t)
local Cryo = require(Packages.Cryo)

local StyleProvider = require(UIBlox.Core.Style.StyleProvider)

local getThemeFromName = require(Style.Themes.getThemeFromName)
local getFontFromName = require(Style.Fonts.getFontFromName)
local Constants = require(Style.Constants)
local Themes = require(script.Parent.Themes)

local DEFAULT_FONT = Constants.FontName.Gotham
local FONT_MAP = {
	[Constants.FontName.Gotham] = require(script.Parent.Fonts.Gotham),
}

local DEFAULT_THEME = Constants.ThemeName.Light
local THEME_MAP = {
	[Constants.ThemeName.Dark] = Themes.DarkTheme,
	[Constants.ThemeName.Light] = Themes.LightTheme,
}

local AppStyleProvider = Roact.Component:extend("AppStyleProvider")

AppStyleProvider.validateProps = t.strictInterface({
	-- The current style of the app.
	style = t.strictInterface({
		themeName = t.string,
		fontName = t.string,
		settings = t.optional(t.strictInterface({
			preferredTransparency = t.optional(t.number),
			reducedMotion = t.optional(t.boolean),
		})),
	}),
	[Roact.Children] = t.table,
})

function AppStyleProvider:render()
	local style = self.props.style
	local settings =
		Cryo.Dictionary.join(if style.settings == nil then {} else style.settings, Constants.DefaultSettings)
	local appStyle = {
		Font = getFontFromName(style.fontName, DEFAULT_FONT, FONT_MAP),
		Theme = getThemeFromName(style.themeName, DEFAULT_THEME, THEME_MAP),
		Settings = {
			PreferredTransparency = settings.preferredTransparency,
			ReducedMotion = settings.reducedMotion,
		},
	}
	return Roact.createElement(StyleProvider, {
		style = appStyle,
	}, self.props[Roact.Children])
end

return AppStyleProvider

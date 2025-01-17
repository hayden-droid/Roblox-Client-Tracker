local Validator = script.Parent
local Style = Validator.Parent
local App = Style.Parent
local UIBlox = App.Parent
local Packages = UIBlox.Parent

local t = require(Packages.t)

local validateFont = require(Validator.validateFont)
local validateSettings = require(Validator.validateSettings)

local UIBloxConfig = require(UIBlox.UIBloxConfig)
local validateTheme = if UIBloxConfig.useNewThemeColorPalettes
	then require(Validator.validateThemeNew)
	else require(Validator.validateTheme)

if UIBloxConfig.enableRoDSDesignTokenSupport then
	local validateTokens = require(Validator.validateTokens)
	local StylePalette = t.strictInterface({
		Theme = validateTheme,
		Font = validateFont,
		Tokens = t.optional(validateTokens),
		Settings = t.optional(validateSettings),
	})
	return StylePalette
else
	local StylePalette = t.strictInterface({
		Theme = validateTheme,
		Font = validateFont,
		Settings = t.optional(validateSettings),
	})
	return StylePalette
end

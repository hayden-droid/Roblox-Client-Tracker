local Roact = require(game:GetService("CorePackages").Roact)
local RobloxLocaleSelector = require(script.Parent.Parent.Components.RobloxLocaleSelector)
local Theming = require(script.Parent.Parent.Theming)

return function()
	it("mounts and unmounts", function()
		local element = Roact.createElement(Theming.ThemeProvider, {
			theme = Theming.createTheme({}),
		}, {
			Content = Roact.createElement(RobloxLocaleSelector, {
				AllLanguagesInfo = {
					localeInfoTable = {
						["en_us"] = {
							languageName = "English",
							languageCode = "en",
						},
						["zh_hans"] = {
							languageName = "Chinese (Simplified)",
							languageCode = "zh_cn",
						}
					},
					languageInfoTable = {},
				},
			}),
		})

		local handle = Roact.mount(element)
		Roact.unmount(handle)
	end)
end

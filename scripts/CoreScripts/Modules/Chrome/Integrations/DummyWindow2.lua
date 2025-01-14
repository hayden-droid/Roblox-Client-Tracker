local CorePackages = game:GetService("CorePackages")
local React = require(CorePackages.Packages.React)

local ChromeService = require(script.Parent.Parent.Service)
local CommonIcon = require(script.Parent.CommonIcon)
local Constants = require(script.Parent.Parent.Unibar.Constants)

return ChromeService:register({
	initialAvailability = ChromeService.AvailabilitySignal.Unavailable,
	id = "dummy_window_2",
	label = "Window",
	startingWindowPosition = UDim2.new(1, -245, 0, 95),
	components = {
		Icon = function(props)
			return CommonIcon("icons/menu/home_on")
		end,
		Window = function(props)
			return React.createElement("Frame", {
				BackgroundTransparency = 0,
				Size = UDim2.new(1, 0, 1, 0),
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = Constants.CORNER_RADIUS,
				}),
			})
		end,
	},
})

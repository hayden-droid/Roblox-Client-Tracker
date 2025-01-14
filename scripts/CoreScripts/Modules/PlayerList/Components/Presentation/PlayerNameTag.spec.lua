return function()
	local Players = game:GetService("Players")
	local CorePackages = game:GetService("CorePackages")
	local Roact = require(CorePackages.Roact)
	local Rodux = require(CorePackages.Rodux)
	local RoactRodux = require(CorePackages.RoactRodux)

	local Components = script.Parent.Parent
	local Connection = Components.Connection
	local LayoutValues = require(Connection.LayoutValues)
	local LayoutValuesProvider = LayoutValues.Provider

	local PlayerList = Components.Parent
	local CreateLayoutValues = require(PlayerList.CreateLayoutValues)

	local Reducers = PlayerList.Reducers
	local Reducer = require(Reducers.Reducer)

	local PlayerNameTag = require(script.Parent.PlayerNameTag)

	it("should create and destroy without errors", function()
		local layoutValues = CreateLayoutValues(false)

		local store = Rodux.Store.new(Reducer)

		local element = Roact.createElement(RoactRodux.StoreProvider, {
			store = store,
		}, {
			LayoutValues = Roact.createElement(LayoutValuesProvider, {
				layoutValues = layoutValues
			}, {
				PlayerNameTag = Roact.createElement(PlayerNameTag, {
					player = Players.LocalPlayer,
					isTitleEntry = false,
					isHovered = false,

					textStyle = {
						Color = Color3.new(1, 1, 1),
						Transparency = 1,
					},
					textFont = {
						Size = 20,
						MinSize = 20,
						Font = Enum.Font.Gotham,
					},
					layoutOrder = 0,
				})
			})
		})
		local instance = Roact.mount(element)
		Roact.unmount(instance)
	end)

	it("should create and destroy without errors tenfoot", function()
		local layoutValues = CreateLayoutValues(true)

		local store = Rodux.Store.new(Reducer)

		local element = Roact.createElement(RoactRodux.StoreProvider, {
			store = store,
		}, {
			LayoutValues = Roact.createElement(LayoutValuesProvider, {
				layoutValues = layoutValues
			}, {
				PlayerNameTag = Roact.createElement(PlayerNameTag, {
					player = Players.LocalPlayer,
					isTitleEntry = true,
					isHovered = true,

					textStyle = layoutValues.DefaultTextStyle,
					textFont = {
						Size = 32,
						MinSize = 32,
						Font = Enum.Font.Gotham,
					},
					layoutOrder = 0,
				})
			})
		})
		local instance = Roact.mount(element)
		Roact.unmount(instance)
	end)
end
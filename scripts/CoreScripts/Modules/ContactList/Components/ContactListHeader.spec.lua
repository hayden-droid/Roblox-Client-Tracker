return function()
	local CorePackages = game:GetService("CorePackages")
	local Roact = require(CorePackages.Roact)
	local Rodux = require(CorePackages.Rodux)
	local RoactRodux = require(CorePackages.RoactRodux)
	local UIBlox = require(CorePackages.UIBlox)
	local Reducer = require(script.Parent.Parent.Reducer)
	local ContactListHeader = require(script.Parent.ContactListHeader)
	local Pages = require(script.Parent.Parent.Enums.Pages)
	local AppDarkTheme = require(CorePackages.Workspace.Packages.Style).Themes.DarkTheme
	local AppFont = require(CorePackages.Workspace.Packages.Style).Fonts.Gotham
	local JestGlobals = require(CorePackages.JestGlobals)
	local expect = JestGlobals.expect

	local appStyle = {
		Font = AppFont,
		Theme = AppDarkTheme,
	}

	local mockState = function(currentPage, callDetailParticipants)
		return {
			Navigation = {
				currentPage = currentPage,
				callDetailParticipants = callDetailParticipants,
			},
		}
	end

	it("should mount and unmount without errors hidden", function()
		local store = Rodux.Store.new(Reducer, mockState(nil, nil), {
			Rodux.thunkMiddleware,
		})

		local element = Roact.createElement(RoactRodux.StoreProvider, {
			store = store,
		}, {
			StyleProvider = Roact.createElement(UIBlox.Core.Style.Provider, {
				style = appStyle,
			}, {
				ContactListHeader = Roact.createElement(ContactListHeader, {
					headerHeight = 48,
					currentPage = Pages.FriendList,
					dismissCallback = function() end,
				}),
			}),
		})

		local folder = Instance.new("Folder")
		local instance = Roact.mount(element, folder)

		local headerTextElement = folder:FindFirstChild("HeaderText", true)
		expect(headerTextElement).never.toBeNull()

		local dismissButtonElement = folder:FindFirstChild("DismissButton", true)
		expect(dismissButtonElement).never.toBeNull()

		Roact.unmount(instance)
	end)
end

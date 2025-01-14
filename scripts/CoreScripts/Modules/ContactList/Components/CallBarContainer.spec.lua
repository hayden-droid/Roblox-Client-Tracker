return function()
	local CorePackages = game:GetService("CorePackages")

	local Roact = require(CorePackages.Roact)
	local Rodux = require(CorePackages.Rodux)
	local RoactRodux = require(CorePackages.RoactRodux)
	local UIBlox = require(CorePackages.UIBlox)
	local JestGlobals = require(CorePackages.JestGlobals)
	local jestExpect = JestGlobals.expect

	local AppDarkTheme = require(CorePackages.Workspace.Packages.Style).Themes.DarkTheme
	local AppFont = require(CorePackages.Workspace.Packages.Style).Fonts.Gotham

	local Reducer = require(script.Parent.Parent.Reducer)
	local CallBarContainer = require(script.Parent.CallBarContainer)

	local CoreGui = game:GetService("CoreGui")
	local RobloxGui = CoreGui:WaitForChild("RobloxGui")
	local ContactList = RobloxGui.Modules.ContactList
	local dependencies = require(ContactList.dependencies)
	local RoduxCall = dependencies.RoduxCall

	local appStyle = {
		Font = AppFont,
		Theme = AppDarkTheme,
	}

	beforeAll(function(c: any)
		c.mockCurrentCall = {
			status = RoduxCall.Enums.Status.Accepting.rawValue(),
			callerId = 11111111,
			calleeId = 12345678,
			placeId = 789,
			callId = "123456",
			callerDisplayName = "Display Name 1",
			calleeDisplayName = "Display Name 2",
			instanceId = "gameId",
		}
	end)

	it("should mount and unmount without errors", function(c: any)
		local store = Rodux.Store.new(Reducer, { Call = { currentCall = c.mockCurrentCall } }, {
			Rodux.thunkMiddleware,
		})

		local element = Roact.createElement(RoactRodux.StoreProvider, {
			store = store,
		}, {
			StyleProvider = Roact.createElement(UIBlox.Core.Style.Provider, {
				style = appStyle,
			}, {
				CallBarContainer = Roact.createElement(CallBarContainer),
			}),
		})

		local folder = Instance.new("Folder")
		local instance = Roact.mount(element, folder)
		local callBarElement = folder:FindFirstChild("CallBar", true) :: ImageButton
		jestExpect(callBarElement).never.toBeNull()

		Roact.unmount(instance)
	end)
end

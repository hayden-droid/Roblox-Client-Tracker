local CorePackages = game:GetService("CorePackages")
local LuaSocialLibrariesDeps = require(CorePackages.LuaSocialLibrariesDeps)
local Lumberyak = require(CorePackages.Lumberyak)
local HttpRequest = LuaSocialLibrariesDeps.httpRequest

local logger = Lumberyak.Logger.new(nil, "ContactList")
local maxHttpRetries = game:DefineFastInt("ContactListHttpRetryCount", 3)
local httpLogger = logger:new("ContactList Networking")
local myHttpRequest = HttpRequest.config({
	requestFunction = function(url, requestMethod, requestOptions)
		httpLogger:info("Fetching: {}", string.format("[ requestMethod = %q, url = %q ]", requestMethod, url))
		return HttpRequest.requestFunctions.HttpRbxApi(url, requestMethod, requestOptions)
	end,
	postRequestFunction = function(response, request)
		httpLogger:debug(
			"Returned: {}",
			string.format(
				"[ requestMethod = %q, url = %q, statusCode = %s, body = %s ]",
				request.requestMethod,
				request.url,
				response.StatusCode,
				response.Body
			)
		)
	end,

	maxRetryCount = maxHttpRetries,
})

local myRoduxNetworking = LuaSocialLibrariesDeps.RoduxNetworking.config({
	keyPath = "NetworkStatus",
	networkImpl = myHttpRequest,
})

return {
	Hooks = {
		dependencyArray = require(CorePackages.Workspace.Packages.RoactUtils).Hooks.dependencyArray,
		useDispatch = require(CorePackages.Workspace.Packages.RoactUtils).Hooks.RoactRodux.useDispatch,
		useSelector = require(CorePackages.Workspace.Packages.RoactUtils).Hooks.RoactRodux.useSelector,
	},
	NetworkingCall = LuaSocialLibrariesDeps.NetworkingCall.config({
		roduxNetworking = myRoduxNetworking,
		useMockedResponse = true,
	}),
	RoduxCall = LuaSocialLibrariesDeps.RoduxCall.config({
		keyPath = "ContactList.Call",
	}),
	RoduxFriends = LuaSocialLibrariesDeps.RoduxFriends.config({
		keyPath = "ContactList.Friends",
	}),
	SocialLibraries = LuaSocialLibrariesDeps.SocialLibraries.config({}),
	UIBlox = require(CorePackages.UIBlox),
	enumerate = require(CorePackages.enumerate),
}

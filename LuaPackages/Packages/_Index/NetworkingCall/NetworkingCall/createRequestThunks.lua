--!strict
local networkingCallTypes = require(script.Parent.networkingCallTypes)

local networkRequests: any = script.Parent.networkRequests
local createGetCallHistory: (networkingCallTypes.Config) -> any = require(networkRequests.createGetCallHistory)

return function(config: networkingCallTypes.Config): networkingCallTypes.RequestThunks
	return {
		GetCallHistory = createGetCallHistory(config),
	}
end

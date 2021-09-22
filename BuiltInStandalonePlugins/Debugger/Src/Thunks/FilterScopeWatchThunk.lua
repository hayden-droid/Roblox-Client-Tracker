local Plugin = script.Parent.Parent.Parent

local Models = Plugin.Src.Models
local StepStateBundle = require(Models.StepStateBundle)
local TableTab = require(Models.Watch.TableTab)

local Actions = Plugin.Src.Actions
local SetVariablesScopeFilteredOut = require(Actions.Watch.SetVariablesScopeFilteredOut)
local ScopeFilterChange = require(Actions.Watch.ScopeFilterChange)

local function isScopeFiltered(enabledScopes, root, flattenedTree)
	local rowData = flattenedTree[root]
	assert(rowData ~= nil, ("FilterScopeWatchThunk got a nil node for path %s"):format(tostring(rowData)))

	for _, scope in ipairs(enabledScopes) do
		if string.find(rowData.scopeColumn, scope) then
			return false
		end
	end
	return true
end

-- Thunk
return function(enabledScopes)
	return function(store, contextItems)
		local state = store:getState()
		local common = state.Common
		local watch = state.Watch

		local token = common.debuggerStateTokenHistory[#common.debuggerStateTokenHistory]	
		local threadId = common.currentThreadId
		local frameNumber = common.threadIdToCurrentFrameNumber[threadId]

		local stepStateBundle = StepStateBundle.ctor(token, threadId, frameNumber)
		local isVariablesTab = watch.currentTab == TableTab.Variables

		local stateRoot = watch.stateTokenToRoots
		local stateFlat = watch.stateTokenToFlattenedTree
		
		local roots = stateRoot[token] and stateRoot[token][threadId] and stateRoot[token][threadId][frameNumber]
		if (roots == nil) then
			warn('unexpected nil in filter thunk')
			return
		end

		local tree = stateFlat[token]  and stateFlat[token][threadId] and stateFlat[token][threadId][frameNumber]
		if (tree == nil) then
			warn('unexpected nil in filter thunk')
			return
		end

		local rootsList = isVariablesTab and roots.Variables or roots.Watches
		local flattenedTree = isVariablesTab and tree.Variables or tree.Watches
		local textFilterMap = {}

		for index, root in pairs(rootsList) do
			local textFilteredOut = isScopeFiltered(enabledScopes, root, flattenedTree)
			textFilterMap[root] = textFilteredOut
		end
		store:dispatch(ScopeFilterChange(enabledScopes))
		store:dispatch(SetVariablesScopeFilteredOut(stepStateBundle, textFilterMap))
	end
end

local Plugin = script.Parent.Parent.Parent
local Rodux = require(Plugin.Packages.Rodux)
local Cryo = require(Plugin.Packages.Cryo)

local Actions = Plugin.Src.Actions
local SetCurrentThreadAction = require(Actions.Callstack.SetCurrentThread)
local SetCurrentFrameNumberAction = require(Actions.Callstack.SetCurrentFrameNumber)
local ResumedAction = require(Actions.Common.Resumed)
local Step = require(Actions.Common.Step)
local BreakpointHit = require(Actions.Common.BreakpointHit)
local AddThreadIdAction = require(Actions.Callstack.AddThreadId)
local SetFocusedDebuggerConnection = require(Actions.Common.SetFocusedDebuggerConnection)

local Framework = require(Plugin.Packages.Framework)
local Util = Framework.Util
local deepCopy = Util.deepCopy

local DebuggerStateToken = require(Plugin.Src.Models.DebuggerStateToken)

type ThreadId = number
type FrameNumber = number
type DebuggerConnectionId = number

type ThreadToFrameMap = {
	[ThreadId] : FrameNumber
}

type CommonStore = {
	debuggerConnectionIdToDST : {[DebuggerConnectionId] : DebuggerStateToken.DebuggerStateToken},
	currentDebuggerConnectionId : number,
	debuggerConnectionIdToCurrentThreadId : {[DebuggerConnectionId] : number},
	currentFrameMap : {[DebuggerConnectionId] : ThreadToFrameMap},
}

local productionStartStore = {
	debuggerConnectionIdToDST = {},
	currentDebuggerConnectionId = -1,
	debuggerConnectionIdToCurrentThreadId = {},
	currentFrameMap = {},
}

return Rodux.createReducer(productionStartStore, {
	[SetCurrentThreadAction.name] = function(state : CommonStore, action : SetCurrentThreadAction.Props)
		local newThreadMap = deepCopy(state.debuggerConnectionIdToCurrentThreadId)
		newThreadMap[state.currentDebuggerConnectionId] = action.currentThreadId

		return Cryo.Dictionary.join(state, {
			debuggerConnectionIdToCurrentThreadId = newThreadMap,
		})
	end,

	[SetCurrentFrameNumberAction.name] = function(state : CommonStore, action : SetCurrentFrameNumberAction.Props)
		local newCurrentFrameMap = deepCopy(state.currentFrameMap)

		assert(newCurrentFrameMap[state.currentDebuggerConnectionId] ~= nil)

		newCurrentFrameMap[state.currentDebuggerConnectionId][action.threadId] = action.currentFrame

		return Cryo.Dictionary.join(state, {
			currentFrameMap = newCurrentFrameMap
		})
	end,

	[ResumedAction.name] = function(state : CommonStore, action)
		local currentConnectionId = state.currentDebuggerConnectionId
		local currentThreadMap = deepCopy(state.debuggerConnectionIdToCurrentThreadId)
		local newCurrentFrameMap = deepCopy(state.currentFrameMap)

		local currentThreadId = currentThreadMap[currentConnectionId]

		assert(newCurrentFrameMap[currentConnectionId] ~= nil)
		assert(newCurrentFrameMap[currentConnectionId][currentThreadId] ~= nil)

		newCurrentFrameMap[currentConnectionId][currentThreadId] = nil
		currentThreadMap[currentConnectionId] = nil
		if currentThreadId == action.threadId then
			-- just pick the first threadID that is still valid if we are resuming the focused thread
			for k,v in pairs(newCurrentFrameMap[currentConnectionId]) do
				currentThreadMap[currentConnectionId] = k
				break
			end
		end
		
		return Cryo.Dictionary.join(state, {
			debuggerConnectionIdToCurrentThreadId = currentThreadMap,
			currentFrameMap = newCurrentFrameMap
		})
	end,

	[Step.name] = function(state : CommonStore, action : Step.Props)
		local newDebuggerConnectionMap = deepCopy(state.debuggerConnectionIdToDST)
		newDebuggerConnectionMap[action.debuggerStateToken.debuggerConnectionId] = action.debuggerStateToken
		
		return Cryo.Dictionary.join(state, {
			debuggerConnectionIdToDST = newDebuggerConnectionMap,
		})
	end,

	[BreakpointHit.name] = function(state : CommonStore, action : BreakpointHit.Props)
		local newDebuggerConnectionMap = deepCopy(state.debuggerConnectionIdToDST)
		newDebuggerConnectionMap[action.debuggerStateToken.debuggerConnectionId] = action.debuggerStateToken

		return Cryo.Dictionary.join(state, {
			debuggerConnectionIdToDST = newDebuggerConnectionMap,
		})
	end,

	[AddThreadIdAction.name] = function(state : CommonStore, action : AddThreadIdAction.Props)
		local newState = {}
		newState.debuggerConnectionIdToCurrentThreadId = deepCopy(state.debuggerConnectionIdToCurrentThreadId)
		assert(newState.debuggerConnectionIdToCurrentThreadId[state.currentDebuggerConnectionId] ~= action.threadId)

		if (newState.debuggerConnectionIdToCurrentThreadId[state.currentDebuggerConnectionId] == nil) then
			newState.debuggerConnectionIdToCurrentThreadId[state.currentDebuggerConnectionId] = action.threadId
		end

		newState.currentFrameMap = deepCopy(state.currentFrameMap)
		if newState.currentFrameMap[state.currentDebuggerConnectionId] == nil then
			newState.currentFrameMap[state.currentDebuggerConnectionId] = {}
		end
		newState.currentFrameMap[state.currentDebuggerConnectionId][action.threadId] = 1

		return Cryo.Dictionary.join(state, newState)
	end,

	[SetFocusedDebuggerConnection.name] = function(state : CommonStore, action : SetFocusedDebuggerConnection.Props)
		return Cryo.Dictionary.join(state, {
			currentDebuggerConnectionId = action.debuggerConnectionId
		})
	end,
})

--[[ Finished Transition ]]--
local baseTransition = require(script.Parent.Parent.Parent:WaitForChild("BaseStateMachine"):WaitForChild("BaseTransitionModule"))

local Finished = baseTransition:inherit()
Finished.name = script.Name
Finished.destinationName = "Freefall"
Finished.sourceName = "Jumping"
Finished.priority = 3

function Finished:Test(stateMachine)
	-- TODO: Add measurement for peak height reached
	return false
end

return Finished
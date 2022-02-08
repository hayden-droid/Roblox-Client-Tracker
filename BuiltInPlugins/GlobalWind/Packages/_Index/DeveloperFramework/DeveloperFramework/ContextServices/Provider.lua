--[[
	Provides a context item so that it can be used in the Roact tree.

	Required Props:
		ContextItem ContextItem: The context item to provide.

	Optional Props:
		Signal UpdateSignal: A signal that is fired when the context item
			is updated. This component listens to the signal to know when
			to update itself. When the signal fires, it should pass `self`.
			The Signal class can be found in Util.
]]

-- DEPRECATED: Replaced by React.createContext provider
-- TODO FFlagDevFrameworkUseCreateContext: Remove this file when flag is retired
local FFlagDevFrameworkUseCreateContext = game:GetFastFlag("DevFrameworkUseCreateContext")
local FFlagDebugDevFrameworkWarnMapToPropsUsed = game:GetFastFlag("DebugDevFrameworkWarnMapToPropsUsed")
if FFlagDebugDevFrameworkWarnMapToPropsUsed and FFlagDevFrameworkUseCreateContext then
	-- StudioService isn't always available, so ignore if an error is thrown trying to access
	local ok, hasInternalPermission = pcall(function()
		return game:GetService("StudioService"):HasInternalPermission()
	end)
	if ok and hasInternalPermission then
		warn("[DeveloperFramework] Provider is deprecated and should not be used.")
	end
	return {}
end

local Framework = script.Parent.Parent
local Roact = require(Framework.Parent.Roact)
local Typecheck = require(Framework.Util).Typecheck

local Provider = Roact.PureComponent:extend("Provider")
Typecheck.wrap(Provider, script)

function Provider:init(props)
	local contextItem = props.ContextItem
	local key = contextItem.Key
	local value = contextItem
	local updateSignal = props.UpdateSignal

	self.state = {
		value = value,
	}

	self._context[key] = {
		value = value,
		updateSignal = updateSignal,
	}

	if updateSignal then
		self.connection = updateSignal:Connect(function(newValue)
			self:setState({
				value = newValue,
			})
		end)
	end
end

function Provider:render()
	local props = self.props
	local state = self.state
	local contextItem = props.ContextItem
	local key = contextItem.Key
	local value = state.value

	self._context[key].value = value
	return Roact.oneChild(self.props[Roact.Children])
end

function Provider:willUnmount()
	if self.connection then
		self.connection:Disconnect()
	end
end

return Provider

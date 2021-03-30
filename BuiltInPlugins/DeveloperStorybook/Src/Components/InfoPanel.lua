--[[
	The main screen of the Developer storybook.
	Displays the story for the currently selected component.
]]
local Main = script.Parent.Parent.Parent
local Types = require(Main.Src.Types)
local Roact = require(Main.Packages.Roact)
local RoactRodux = require(Main.Packages.RoactRodux)

local Framework = require(Main.Packages.Framework)
local ContextServices = Framework.ContextServices

local Dash = Framework.Dash
local assign = Dash.assign
local forEach = Dash.forEach
local keys = Dash.keys
local join = Dash.join
local joinDeep = Dash.joinDeep
local map = Dash.map
local mapOne = Dash.mapOne

local sort = table.sort

local UI = Framework.UI
local ScrollingFrame = UI.ScrollingFrame
local Decoration = UI.Decoration
local Pane = UI.Pane
local TextLabel = Decoration.TextLabel

local PanelEntry = require(Main.Src.Components.PanelEntry)
local PropsList = require(Main.Src.Components.PropsList)
local Footer = require(Main.Src.Components.Footer)
local StylesList = require(Main.Src.Components.StylesList)
local Controls = require(Main.Src.Components.Controls)
local makeInstanceHost = require(Main.Src.Components.InstanceHost)
local StoryHost = require(Main.Src.Components.StoryHost)
local ModuleLoader = require(Main.Src.Util.ModuleLoader)
local ThemeSwitcher = Framework.Style.ThemeSwitcher

local STYLE_DESCRIPTION = [[These values make up the component's Style table, which can be extended:]]

type Props = {
	SelectedStory: Types.StoryItem?,
	Plugin: any,
	Stylizer: any,
}
type State = {
	storyError: string?,
	storyProps: Types.StoryProps?
}

local InfoPanel = Roact.PureComponent:extend("InfoPanel")

function InfoPanel:init()
	self.state = {
		storyError = nil,
		storyProps = nil,
	} :: State
	self.storyRef = Roact.createRef()
end

function InfoPanel:didUpdate(prevProps: Props)
	local props = self.props
	local story = props.SelectedStory
	-- Don't make a change if the story selection hasn't changed
	if prevProps.SelectedStory ~= story then
		self:setState({
			storyError = Roact.None,
		})
		local storyProps = self.state.storyProps
		if storyProps and storyProps.definition.destroy then
			-- Clean up the old story if a destructor is provided
			storyProps.definition.destroy(storyProps)
		end
		-- Avoid a breakpoint or yield in the scripts we are requiring from propagating a NoYield error up through Roact
		spawn(function()
			self:updateStory(story)
		end)
	end
end

function InfoPanel:setControls(changes: Types.StoryControls)
	self:setState({
		storyProps = joinDeep(self.state.storyProps, {
			controls = changes
		})
	})
end

-- Asynchronously load the next story and update our state with the result
function InfoPanel:updateStory(storyItem: Types.StoryItem)
	if not storyItem or not storyItem.Script then
		self:setState({
			storyError = Roact.None,
			storyProps = Roact.None,
		})
		return
	end
	-- Try loading the story with the module loader
	local ok, err = xpcall(function()
		local storybook = storyItem.Storybook
		local construct = ModuleLoader:load(storyItem.Script)
		-- Construct the story definition
		local storyDefinition = self:getStoryDefinition(storyItem, construct, storybook)
		local controls = {}
		-- Add the controls to the storyProps state
		if storyDefinition.controls then
			controls = map(storyDefinition.controls, function(value: any)
				-- Assign the first value of a multi-select control by default
				if typeof(value) == "table" then
					return value[1]
				else
					return value
				end
			end)
		end
		local storyProps = {
			controls = controls,
			setControls = function(changes)
				self:setControls(changes)
			end,
			script = storyItem.Script,
			definition = storyDefinition,
			docs = storyItem.Docs,
			story = storyDefinition.story,
		}
		if storyDefinition.create then
			storyDefinition.create(storyProps)
		end
		-- Update our state after an async update
		self:setState({
			storyError = Roact.None,
			storyProps = storyProps,
		})
	end, function(err)
		return err .. "\n" .. debug.traceback()
	end)
	if not ok then
		warn("Story render failed", err)
		-- Display the error with loading the story
		self:setState({
			storyError = err,
			storyProps = Roact.None,
		})
	end
end

--[[
	Allow stories to be provided in a range of different formats.
	@param storyItem - the item in the tree row that represents the story
	@param construct - the return value from the ModuleScript
	@param storybook - a table implementing Storybook from the spec
]]

function InfoPanel:getStoryDefinition(storyItem: Types.StoryItem, construct: Types.Story, storybook: Types.Storybook): Types.StoryDefinition
	local definition = {
		name = storyItem.Name,
		summary = "",
		roact = storybook.roact or ModuleLoader:load(Main.Packages.Roact),
		source = storyItem.Script,
	} :: Types.StoryDefinition
	local isFnStory = typeof(construct) == "function"
	if isFnStory then
		local host = Instance.new("Frame")
		host.Size = UDim2.fromScale(1, 1)
		host.BackgroundTransparency = 1
		local ok, result = pcall(function()
			return construct(host)
		end)
		local isDeprecatedLifecycleFunction = ok and typeof(result) == "function"
		if isDeprecatedLifecycleFunction then
			definition.story = self:getRoactComponent(host, definition.roact)
			definition.destroy = result
		else
			definition.story = construct
		end
	elseif typeof(construct) == "table" then
		local component = self:getRoactComponent(construct, definition.roact)
		if component then
			definition.story = component
		else
			-- The construct is a StoryDefinition
			assign(definition, construct)
			if definition.story then
				definition.story = self:getRoactComponent(definition.story, definition.roact)
			end
			if definition.stories then
				definition.stories = map(definition.stories, function(subStory, key)
					local subComponent = self:getRoactComponent(subStory, definition.roact)
					if subComponent then
						return {
							name = key,
							summary = "",
							story = subComponent
						}
					else
						return join(subStory, {
							story = self:getRoactComponent(subStory.story, definition.roact)
						})
					end
				end)
			end
		end
	end
	if storybook.definition then
		assign(definition, storybook.definition)
	end
	if storybook.mapDefinition then
		definition = storybook.mapDefinition(definition)
		assert(typeof(definition) == "table", "Storybook mapDefinition should return the definition")
	end
	if storybook.mapStory then
		if definition.story then
			definition.story = storybook.mapStory(definition.story)
		end
		if definition.stories then
			for _, subDefinition in pairs(definition.stories) do
				subDefinition.story = storybook.mapStory(subDefinition.story)
			end
		end
	end
	return definition
end

function InfoPanel:getRoactComponent(input: Types.Story, roact: Types.Roact): Types.RoactComponent?
	local isInstance = typeof(input) == "Instance"
	local isRoactElement = typeof(input) == "table" and input.component ~= nil
	local isRoactComponent = typeof(input) == "table" and input.__componentName ~= nil
	local isRoactFn = typeof(input) == "function"
	if isInstance then
		return function()
			return roact.createElement(makeInstanceHost(roact), {
				Instance = input
			})
		end
	elseif isRoactElement then
		return function()
			return input
		end
	elseif isRoactComponent or isRoactFn then
		return input
	else
		return nil
	end
end

function InfoPanel:render()
	local props = self.props
	local state = self.state
	local style = props.Stylizer
	local sizes = style.Sizes
	local order = 0
	local function nextOrder()
		order = order + 1
		return order
	end

	if self.state.storyError then
		return Roact.createElement(Pane, {
			Style = "Box",
			Padding = sizes.OuterPadding,
			Size = UDim2.new(1, -sizes.Gutter, 1, -sizes.TopBar),
			Position = UDim2.new(1, 0, 0, sizes.TopBar),
			AnchorPoint = Vector2.new(1, 0),
		}, {
			Scroller = Roact.createElement(ScrollingFrame, {
				Size = UDim2.fromScale(1, 1),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
			}, {
				Prompt = Roact.createElement(TextLabel, {
					Size = UDim2.fromScale(1, 0),
					Text = "An error occurred when loading the story:\n\n" .. self.state.storyError,
					TextColor = style.ErrorColor,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					AutomaticSize = Enum.AutomaticSize.Y,
				})
			})
		})
	end

	local storyProps: Types.StoryProps = state.storyProps
	
	if not storyProps then
		return Roact.createElement(Pane, {
			Style = "BorderBox",
			Size = UDim2.new(1, -sizes.Gutter, 1, -sizes.TopBar),
			Position = UDim2.new(1, 0, 0, sizes.TopBar),
			AnchorPoint = Vector2.new(1, 0),
			Layout = Enum.FillDirection.Vertical,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Spacing = 20,
		}, {
			Banner = Roact.createElement("ImageLabel", {
				BackgroundTransparency = 1,
				Image = "rbxasset://textures/DeveloperStorybook/Banner.png",
				Size = UDim2.fromOffset(95, 95),
				LayoutOrder = 1,
			}),
			Prompt = Roact.createElement(TextLabel, {
				Text = "Select a story from the tree",
				TextWrapped = true,
				LayoutOrder = 2,
				AutomaticSize = Enum.AutomaticSize.XY,
			}),
		})
	end

	local definition = storyProps.definition
	local docs = definition.docs

	local isRunningAsPlugin = typeof(props.Plugin:get().OpenScript) == "function"

	local children = {
		Header = Roact.createElement(PanelEntry, {
			Header = definition.name,
			Description = definition.summary,
			LayoutOrder = nextOrder(),
		})
	}

	if mapOne(storyProps.controls) ~= nil then
		children.Controls = Roact.createElement(Controls, {
			Controls = storyProps.definition.controls or {},
			ControlState = storyProps.controls,
			LayoutOrder = nextOrder(),
			SetControls = function(changes)
				self:setControls(changes)
			end
		})
	end

	if definition.story then
		children.Story = Roact.createElement(StoryHost, {
			StoryRef = self.storyRef,
			LayoutOrder = nextOrder(),
			StoryProps = storyProps,
			ThemeName = ThemeSwitcher.getThemeName(),
		})
	end

	if definition.stories then
		-- Sub-stories are sorted
		local subStoryKeys = keys(definition.stories)
		sort(subStoryKeys)
		forEach(subStoryKeys, function(key: string | number)
			local subDefinition = definition.stories[key]
			-- Load one host per sub-story
			local subStory = Roact.createElement(StoryHost, {
				StoryRef = self.storyRef,
				Name = subDefinition.name,
				Summary = subDefinition.summary,
				LayoutOrder = nextOrder(),
				StoryProps = join(storyProps, {
					story = self:getRoactComponent(subDefinition.story),
					key = key
				}),
				ThemeName = ThemeSwitcher.getThemeName(),
			})
			children["Story " .. key] = subStory
		end)
	end

	assign(children, {
		RequiredProps = docs and docs.Required and Roact.createElement(PropsList, {
			Header = "Required Props",
			LayoutOrder = nextOrder(),
			Props = docs.Required,
		}),
		OptionalProps = docs and docs.Optional and Roact.createElement(PropsList, {
			Header = "Optional Props",
			LayoutOrder = nextOrder(),
			Props = docs.Optional,
		}),
		Styles = docs and docs.Style and Roact.createElement(StylesList, {
			Header = "Styles",
			LayoutOrder = nextOrder(),
			ComponentName = definition.name
		}),
		StyleValues = docs and docs.Style and Roact.createElement(PropsList, {
			Header = "Style Values",
			Description = STYLE_DESCRIPTION,
			LayoutOrder = nextOrder(),
			Props = docs.Style,
		}),
	})

	return Roact.createElement(Pane, {
		Style = "BorderBox",
		Layout = Enum.FillDirection.Vertical,
		Size = UDim2.new(1, -sizes.Gutter, 1, -sizes.TopBar),
		Position = UDim2.new(1, 0, 0, sizes.TopBar),
		AnchorPoint = Vector2.new(1, 0),
		Padding = {
			Top = sizes.OuterPadding,
			Left = sizes.OuterPadding,
			Bottom = sizes.OuterPadding,
			Right = sizes.InnerPadding,
		},
	}, {
		ScrollingFrame = Roact.createElement(ScrollingFrame, {
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 1, -sizes.TopBar),
			CanvasSize = UDim2.fromScale(1, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, {
			Content = Roact.createElement(Pane, {
				Layout = Enum.FillDirection.Vertical,
				AutomaticSize = Enum.AutomaticSize.Y,
				Spacing = sizes.InnerPadding,
				[Roact.Ref] = self.storyRef,
			}, children),
		}),
		Footer = isRunningAsPlugin and Roact.createElement(Pane, {
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, sizes.TopBar)
		}, {
			Content = Roact.createElement(Footer, {
				StoryRef = self.storyRef
			})
		})
	})
end

ContextServices.mapToProps(InfoPanel, {
	Stylizer = ContextServices.Stylizer,
	Plugin = ContextServices.Plugin
})

InfoPanel = RoactRodux.connect(
	function(state, props)
		return {
			CurrentTheme = state.Stories.theme,
			SelectedStory = state.Stories.selectedStory,
		}
	end
)(InfoPanel)

return InfoPanel

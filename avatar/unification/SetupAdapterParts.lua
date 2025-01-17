-- SetupAdapterParts.lua
-- Setup a newly spawned R15 character to emulate an R6 character
-- The character will have "adapter parts" added to it which old script can operate on
local SetupAdapterParts = {}

local CollectionService = game:GetService("CollectionService")

-- AdapterReference.rbxm is set up as { AdapterReference {Left Arm {...}, Right Arm {...},...}, CollisionHead {...} }
-- i.e. CollisionHead and AdapterReference are at then same level
local AdapterReference = script:WaitForChild("AdapterReference")
local CollisionHead = script:WaitForChild("CollisionHead")
AdapterReference.Parent = nil
CollisionHead.Parent = nil

local Character = script.Parent
local AdaptInstance = require(Character:WaitForChild("AdaptInstance"))

local ALWAYS_TRANSPARENT_PART_TAG = "__RBX__LOCKED_TRANSPARENT"

local AestheticParts = {
	LeftUpperLeg = true,
	LeftLowerLeg = true,
	LeftFoot = true,

	RightUpperLeg = true,
	RightLowerLeg = true,
	RightFoot = true,

	LowerTorso = true,
	UpperTorso = true,

	LeftUpperArm = true,
	LeftLowerArm = true,
	LeftHand = true,

	RightUpperArm = true,
	RightLowerArm = true,
	RightHand = true,
}

local JointFixes = {
	UpperTorso = {
		RightShoulderRigAttachment = {
			JointOwner = "RightUpperArm",
			ConnectedPart = "UpperTorso",
			Translation = Vector3.new(0, -0.268, 0),
		},

		LeftShoulderRigAttachment = {
			JointOwner = "LeftUpperArm",
			ConnectedPart = "UpperTorso",
			Translation = Vector3.new(0, -0.268, 0),
		},
	},

	RightUpperArm = {
		RightShoulderRigAttachment = {
			JointOwner = "RightUpperArm",
			ConnectedPart = "UpperTorso",
			Translation = Vector3.new(0, -0.269, 0),
		},
	},

	LeftUpperArm = {
		LeftShoulderRigAttachment = {
			JointOwner = "LeftUpperArm",
			ConnectedPart = "UpperTorso",
			Translation = Vector3.new(0, -0.269, 0),
		},
	},
}

local PartNameToAdapter = {}
local AdapterToParts = {}

local WeldPartNames = {}

local connections = {}
local fixedAttachments = {}

local function addToFixedAttachments(instance)
	fixedAttachments[instance] = true

	local conn
	conn = instance:GetPropertyChangedSignal("Parent"):Connect(function()
		if not instance.Parent then
			fixedAttachments[instance] = nil
			conn:Disconnect()
		end
	end)
end

local function maintainPropertyValue(instance, prop, value)
	local function setPropValue()
		if instance[prop] ~= value then
			instance[prop] = value
		end
	end

	table.insert(connections, instance:GetPropertyChangedSignal(prop):Connect(setPropValue))
	setPropValue()
end

local function rebuildJoint(parentAttachment, partForJointAttachment)
	local jointName = parentAttachment.Name:gsub("RigAttachment", "")
	local motor = partForJointAttachment.Parent:FindFirstChild(jointName)
	if not motor then
		motor = Instance.new("Motor6D")
	end
	motor.Name = jointName

	motor.Part0 = parentAttachment.Parent
	motor.Part1 = partForJointAttachment.Parent

	motor.C0 = parentAttachment.CFrame
	motor.C1 = partForJointAttachment.CFrame

	motor.Parent = partForJointAttachment.Parent
end

local function fixJoints(part)
	for attachmentName, info in pairs(JointFixes[part.Name]) do
		local attachment = part:FindFirstChild(attachmentName)
		if not attachment or not attachment:IsA("Attachment") then
			continue
		end

		local connectedPart = Character:FindFirstChild(info.ConnectedPart)
		local jointParent = Character:FindFirstChild(info.JointOwner)
		if not connectedPart or not jointParent then
			continue
		end

		local connectAttachment = connectedPart:FindFirstChild(attachmentName)
		local jointAttachment = jointParent:FindFirstChild(attachmentName)
		if
			not connectAttachment
			or not jointAttachment
			or not connectAttachment:IsA("Attachment")
			or not jointAttachment:IsA("Attachment")
		then
			continue
		end

		if fixedAttachments[attachment] then
			continue
		end
		addToFixedAttachments(attachment)

		local originalPositionValue = attachment:FindFirstChild("OriginalPosition")
		if originalPositionValue and originalPositionValue:IsA("Vector3Value") then
			originalPositionValue.Value = originalPositionValue.Value + info.Translation
		end
		attachment.Position = attachment.Position + info.Translation

		rebuildJoint(connectAttachment, jointAttachment)
	end
end

local function setUpAestheticPart(part)
	maintainPropertyValue(part, "Massless", true)
	maintainPropertyValue(part, "CanCollide", false)
	maintainPropertyValue(part, "CanTouch", false)
	maintainPropertyValue(part, "CanQuery", false)
end

local function setUpPart(part)
	if AestheticParts[part.Name] then
		setUpAestheticPart(part)
	end

	if JointFixes[part.Name] then
		fixJoints(part)
	end
end

local function weldParts(weldPart, weldTo)
	if not weldPart or not weldTo then
		return
	end

	local weldName = weldPart.Name .. weldTo.Name
	local weld = weldPart:FindFirstChild(weldName)
	if not weld then
		weld = Instance.new("Weld")
	end

	weld.Name = weldName
	weld.Part0 = weldPart
	weld.Part1 = weldTo
	weld.C0 = CFrame.new(0, weldPart.Size.Y / 2, 0)
	weld.C1 = CFrame.new(0, weldTo.Size.Y / 2, 0)
	weld.Parent = weldPart
	return weld
end

local function onWeldDestroyed(adapter)
	local parts = AdapterToParts[adapter]
	for part, _ in parts do
		part:BreakJoints()
	end
end

local function setUpAdapterPart(adapter)
	local newAdapter = adapter:Clone()
	newAdapter:ClearAllChildren()
	newAdapter.Parent = Character

	local adapterChildren = adapter:GetChildren()
	for _, child in adapterChildren do
		PartNameToAdapter[child.Name] = newAdapter
		AdapterToParts[newAdapter] = {}
		if child:FindFirstChildWhichIsA("Weld") then
			WeldPartNames[child.Name] = true

			local weldTo = Character:FindFirstChild(child.Name)
			weldParts(newAdapter, weldTo)
		end
	end

	return newAdapter
end

local function onAdaptedPartAdded(part)
	local adapter = PartNameToAdapter[part.Name]

	if WeldPartNames[part.Name] then
		adapter.Color = part.Color
		adapter.Transparency = part.Transparency
		local weld = weldParts(adapter, part)
		table.insert(
			connections,
			weld.AncestryChanged:Connect(function(_, parent)
				if parent then
					return
				end

				onWeldDestroyed(adapter)
			end)
		)
	end

	AdaptInstance(part, adapter)
	AdapterToParts[adapter][part] = true
end

local function onChildAdded(child)
	if child:IsA("BasePart") then
		setUpPart(child)
		if PartNameToAdapter[child.Name] then
			onAdaptedPartAdded(child)
		end
	end
	if child:IsA("Humanoid") then
		child.BreakJointsOnDeath = false
	end
end

local function onChildRemoved(child)
	if child:IsA("BasePart") and PartNameToAdapter[child.Name] then
		local adapter = PartNameToAdapter[child.Name]
		AdapterToParts[adapter][child] = nil
	end
end

local function onAncestryChanged(_, parent)
	if parent == nil then
		for _, connection in connections do
			connection:Disconnect()
		end
		table.clear(connections)
	end
end

local function createHead()
	local newHead = CollisionHead:Clone()
	newHead:ClearAllChildren()
	newHead.Parent = Character

	local headChildren = CollisionHead:GetChildren()
	for _, child in headChildren do
		--the only child under the CollisionHead is the Head. I only kept this formatting due to the AdapterReference
		local part = Character:FindFirstChild(child.Name)
		if not part	then
			continue
		end
		if child:FindFirstChildWhichIsA("Weld") then
			local weldTo = Character:FindFirstChild(child.Name)
			weldParts(newHead, weldTo)
		end
		setUpAestheticPart(part)
	end
	CollectionService:AddTag(newHead, ALWAYS_TRANSPARENT_PART_TAG)
end

function SetupAdapterParts.setupCharacter()
	for _, child in AdapterReference:GetChildren() do
		local adapter = setUpAdapterPart(child)
		CollectionService:AddTag(adapter, ALWAYS_TRANSPARENT_PART_TAG)
	end
	AdapterReference:Destroy()

	table.insert(connections, Character.ChildAdded:Connect(onChildAdded))
	table.insert(connections, Character.ChildRemoved:Connect(onChildRemoved))
	table.insert(connections, Character.AncestryChanged:Connect(onAncestryChanged))

	for _, child in Character:GetChildren() do
		onChildAdded(child)
	end

	createHead()
end

return SetupAdapterParts

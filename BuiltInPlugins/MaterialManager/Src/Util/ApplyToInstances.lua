local Plugin = script.Parent.Parent.Parent
local _Types = require(Plugin.Src.Types)

return function(instances: _Types.Array<Instance>, baseMaterial: Enum.Material, materialVariant: string?)
	for _, instance in ipairs(instances) do
		if instance:IsA("BasePart") then
			instance.Material = baseMaterial
			instance.MaterialVariant = materialVariant or ""
		end

		if instance:IsA("Model") then
			local descendants = instance:GetDescendants()
			for _, descendant in ipairs(descendants) do
				if descendant:IsA("BasePart") then
					descendant.Material = baseMaterial
					descendant.MaterialVariant = materialVariant or ""
				end
			end
		end
	end
end

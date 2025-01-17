-- This file just provides a convenient interface to query for images
local GetImageSetData = require(script.Parent.GetImageSetData)
local FALLBACK_IMAGES = require(script.Parent.FallbackImages)
local ImagesTypes = require(script.Parent.ImagesTypes)

local GuiService = game:GetService("GuiService")

local CorePackages = script:FindFirstAncestor("CorePackages")
local success, scale = pcall(GuiService.GetResolutionScale, GuiService)

if not success or not CorePackages then
	scale = 1
end

local sourceData
-- scale should match the exact image scale used
sourceData, scale = GetImageSetData(scale)

local function getPackagePath(): string?
	local packageRoot = script.Parent.Parent.Parent

	if CorePackages == nil then
		-- We're not running in CI as a core script, no internal path
		return nil
	end

	local path = {}
	local current: Instance? = packageRoot
	while current ~= nil and current ~= CorePackages do
		table.insert(path, 1, current.Name)
		current = current.Parent
	end

	return "LuaPackages/" .. table.concat(path, "/")
end

local function getImagePath(packagePath: string?, imageName: string): string
	if packagePath == nil then
		-- fallback to an uploaded image
		return FALLBACK_IMAGES[imageName]
	else
		return string.format("rbxasset://%s/AppImageAtlas/%s.png", packagePath, imageName)
	end
end

local packagePath = getPackagePath()
local Images = {
	ImagesResolutionScale = scale,
}

export type ImageSetImage = ImagesTypes.ImageSetImage

export type Images = ImagesTypes.Images

for key, value in pairs(sourceData) do
	assert(typeof(value) == "table", "invalid sourceData from GetImageSetData for scale " .. tostring(scale))
	local imageProps = {}
	for imageKey, imageValue in pairs(value) do
		if imageKey == "ImageSet" then
			imageProps.Image = getImagePath(packagePath, imageValue)
		else
			imageProps[imageKey] = imageValue
		end
	end
	Images[key] = imageProps :: ImageSetImage
end

-- Attach a metamethod to guard against typos
setmetatable(Images, {
	__index = function(_, key)
		error(("%q is not a valid member of Images"):format(tostring(key)), 2)
	end,
})

return Images

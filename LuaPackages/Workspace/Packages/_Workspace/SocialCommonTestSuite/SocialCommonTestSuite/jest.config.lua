local Root = script.Parent
local Packages = Root.Parent

return {
	projects = {
		require(Packages.SocialCommon)["jest.config"],
		require(Packages.InvisibleMode)["jest.config"],
	} :: { ModuleScript },
}

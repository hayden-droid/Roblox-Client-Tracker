local PYMKCarousel = script.Parent.Parent.Parent
local dependencies = require(PYMKCarousel.dependencies)
local SocialLibraries = dependencies.SocialLibraries

local getDeepValue = SocialLibraries.Dictionary.getDeepValue
local llama = dependencies.llama

local Constants = require(PYMKCarousel.Common.Constants)
local ModelTypes = require(PYMKCarousel.Common.ModelTypes)

local SocialCommon = dependencies.SocialCommon
local RecommendationSourceEnum = SocialCommon.Enums.RecommendationSourceEnum

local getFFlagSocialMoveRecsSource = dependencies.getFFlagSocialMoveRecsSource

type RecommendationsList = {
	[number]: ModelTypes.Recommendation,
}

local filterOutPYMKRecommendationIds = function(recommendations: RecommendationsList)
	return function(state: any): RecommendationsList
		local PYMKRecommendationIds = getDeepValue(
			state,
			string.format(
				"%s.Friends.recommendations.bySource.%s",
				Constants.RODUX_KEY,
				if getFFlagSocialMoveRecsSource()
					then RecommendationSourceEnum.HomepagePYMKCarousel
					else Constants.RECS_SOURCE
			)
		) or {}

		return llama.List.filter(recommendations, function(recommendation)
			return PYMKRecommendationIds[recommendation.id]
		end)
	end
end

return filterOutPYMKRecommendationIds

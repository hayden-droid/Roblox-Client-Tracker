local typeDefs = require(script.typeDefs)
local resolvers = require(script.resolvers)
local generatedTypes = require(script.generatedTypes)

export type OmniFeed = generatedTypes.OmniFeed
export type OmniFeedMetadata = generatedTypes.OmniFeedMetadata

return {
	typeDefs = typeDefs,
	resolvers = resolvers,
	generatedTypes = generatedTypes,
}


module.exports = class RoadDefinition
  constructor: (@id, @image) ->

  @from_json: (json) ->
    new RoadDefinition(json.id, json.image)

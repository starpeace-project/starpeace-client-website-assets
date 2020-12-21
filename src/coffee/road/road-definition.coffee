
module.exports = class RoadDefinition
  constructor: (@id, @image) ->

  @fromJson: (json) ->
    new RoadDefinition(json.id, json.image)

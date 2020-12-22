
module.exports = class OverlayDefinition
  constructor: (@id, @image, @tileWidth, @tileHeight) ->

  @fromJson: (json) ->
    new OverlayDefinition(json.id, json.image, json.tileWidth, json.tileHeight)

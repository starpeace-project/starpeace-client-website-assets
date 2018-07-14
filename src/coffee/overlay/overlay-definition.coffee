
module.exports = class OverlayDefinition
  constructor: (@id, @image, @tile_width, @tile_height) ->

  @from_json: (json) ->
    new OverlayDefinition(json.id, json.image, json.tile_width, json.tile_height)

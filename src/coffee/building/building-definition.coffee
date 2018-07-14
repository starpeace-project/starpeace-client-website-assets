
path = require('path')

_ = require('lodash')

class BuildingDefinition
  constructor: (@id, @image, @zone, @tile_width, @tile_height, @effects) ->

  to_compiled_json: () ->
    {
      @id
      @image
      @tile_width
      @tile_height
    }

  @from_json: (json) ->
    new BuildingDefinition(json.id, json.image, json.zone, json.tile_width, json.tile_height, json.effects)

module.exports = BuildingDefinition

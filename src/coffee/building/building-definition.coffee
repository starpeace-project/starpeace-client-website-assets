
path = require('path')

_ = require('lodash')

class BuildingDefinition
  constructor: (@id, @image, @tile_width, @tile_height) ->

  to_compiled_json: () ->
    {
      @id
      @image
      @tile_width
      @tile_height
    }

  @from_json: (json) ->
    new BuildingDefinition(json.id, json.image, json.tile_width, json.tile_height)

module.exports = BuildingDefinition

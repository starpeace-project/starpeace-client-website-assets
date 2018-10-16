
path = require('path')

_ = require('lodash')

class BuildingDefinition
  constructor: (@id, @image_path, @zone, @hit_area, @tile_width, @tile_height, @effects) ->

  to_compiled_json: () ->
    {
      @id
      @image
      @hit_area
      @tile_width
      @tile_height
    }

  @from_json: (json) ->
    new BuildingDefinition(json.id, json.image, json.zone, json.hit_area, json.tile_width, json.tile_height, json.effects)

module.exports = BuildingDefinition

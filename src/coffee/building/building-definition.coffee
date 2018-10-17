
path = require('path')

_ = require('lodash')

class BuildingDefinition
  constructor: (@id, @image_path, @zone, @category, @industry_type, @hit_area, @tile_width, @tile_height, @effects) ->

  to_compiled_json: (atlas) ->
    json = {
      w: @tile_width
      h: @tile_height
      hit_area: @hit_area || []
      zone: @zone
      category: @category
      industry_type: @industry_type
      atlas: atlas
      frames: @frame_ids
    }
    json.effects = @effects if @effects?.length
    json

  @from_json: (json) ->
    new BuildingDefinition(json.id, json.image, json.zone, json.category, json.industry_type, json.hit_area, json.tile_width, json.tile_height, json.effects)

module.exports = BuildingDefinition

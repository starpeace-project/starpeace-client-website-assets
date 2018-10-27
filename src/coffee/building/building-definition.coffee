
path = require('path')

_ = require('lodash')

class BuildingDefinition
  constructor: (@id, @image_path, @construction_id, @zone, @category, @industry_type, @hit_area, @tile_width, @tile_height, @effects, @required_invention_ids, @resource_flows) ->
    @seal_ids = []

  to_compiled_json: (atlas) ->
    json = {
      id: @id
      w: @tile_width
      h: @tile_height
      hit_area: @hit_area || []
      construction_id: @construction_id
      seal_ids: _.uniq(@seal_ids)
      zone: @zone
      category: @category
      industry_type: @industry_type
      atlas: atlas
      frames: @frame_ids
    }
    json.effects = @effects if @effects?.length
    json.required_invention_ids = @required_invention_ids if @required_invention_ids?.length
    json.resource_flows = @resource_flows if @resource_flows?.length
    json

  @from_json: (json) ->
    new BuildingDefinition(json.id, json.image, json.construction_id, json.zone, json.category, json.industry_type,
        json.hit_area, json.tile_width, json.tile_height, json.effects, json.required_inventions, json.resource_flow)

module.exports = BuildingDefinition

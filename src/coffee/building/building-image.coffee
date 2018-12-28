
path = require('path')

_ = require('lodash')

module.exports = class BuildingImage
  constructor: (@id) ->

  to_compiled_json: (atlas) ->
    json = {
      id: @id
      w: @tile_width
      h: @tile_height
      hit_area: @hit_area || []
      atlas: atlas
      frames: @frame_ids
    }
    json.effects = @effects if @effects?.length
    json

  @from_json: (json) ->
    image = new BuildingImage(json.id)
    image.image_path = json.image
    image.tile_width = json.tile_width
    image.tile_height = json.tile_height
    image.hit_area = json.hit_area
    image.effects = json.effects || []
    image

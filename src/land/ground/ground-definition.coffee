
path = require('path')
crypto = require('crypto')

_ = require('lodash')
Jimp = require('jimp')

LandAttributes = require('../land-attributes')


class GroundDefinition

  constructor: () ->
    @id = Number.NaN
    @map_color = Number.NaN
    @seasons = new Set()
    @planet_type = LandAttributes.PLANET_TYPES.other
    @zone = LandAttributes.ZONES.other
    @type = LandAttributes.TYPES.other

    @textures_by_orientation_type = {}

  key: () ->
    "ground.#{@id.toString().padStart(3, '0')}.#{@zone}"

  texture_keys: () ->
   _.map(_.values(@textures_by_orientation_type), (texture) -> texture.key)

  valid: () ->
    !isNaN(@id)  && !isNaN(@map_color) && !@missing_texture_keys().length

  is_center: () -> _.some(_.values(@textures_by_orientation_type), (texture) -> texture.type == 'center')

  missing_texture_keys: () ->
    _.difference(['0deg', '90deg', '180deg', '270deg'], Object.keys(@textures_by_orientation_type))

  populate_texture_keys: () ->
    root = @textures_by_orientation_type['0deg']
    for orientation in ['90deg', '180deg', '270deg']
      continue if @textures_by_orientation_type[orientation]?
      @textures_by_orientation_type[orientation] = {
        type: LandAttributes.rotate_type(key.type, orientation)
        key: root.key
      }

  to_json: () ->
    {
      @id
      @map_color
      @zone
      seasons: Array.from(@seasons)
      textures: @textures_by_orientation_type
    }

  to_compiled_json: () ->
    {
      @id
      @map_color
      @zone
      is_coast: @zone == LandAttributes.ZONES.water && !@is_center()
    }

  @fromJson: (json) ->
    tile = new GroundDefinition()
    tile.id = json.id
    tile.map_color = json.map_color
    tile.seasons = new Set(json.seasons || [LandAttributes.SEASONS.winter, LandAttributes.SEASONS.spring, LandAttributes.SEASONS.summer, LandAttributes.SEASONS.fall])
    tile.planet_type = json.planet_type || LandAttributes.PLANET_TYPES.earth # FIXME: TODO: stop this default
    tile.zone = json.zone || LandAttributes.ZONES.other
    tile.type = json.type || LandAttributes.TYPES.other
    tile.textures_by_orientation_type = json.textures || {}

    tile

module.exports = GroundDefinition

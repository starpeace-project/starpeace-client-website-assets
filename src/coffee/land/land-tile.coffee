
path = require('path')
crypto = require('crypto')

_ = require('lodash')
Jimp = require('jimp')

LandTileKey = require('./land-tile-key')

#
# simple representation of land tile metadata; originally from /LandClasses/*.ini
#
class LandTile
  id: Number.NaN
  map_color: Number.NaN

  constructor: () ->
    @image_keys = {}

  safe_id: () ->
    return @id unless isNaN(@id)
    _.find(_.map(@image_keys, (key) -> key.id), (id) -> !isNaN(id))

  valid: () ->
    has_id = !isNaN(@safe_id())
    has_id && !isNaN(@map_color) && !@missing_image_keys().length && @valid_image_keys(has_id)

  valid_image_keys: (has_id) ->
    _.findIndex(@image_keys, (key) -> !key.valid(has_id)) < 0

  root_key: () ->
    @key || @image_keys['0deg']

  safe_image_key: () ->
    "land.#{@safe_id().toString().padStart(3, '0')}.#{@root_key().zone}.#{@root_key().type}.#{@root_key().variant}.bmp"

  missing_image_keys: () ->
    _.difference(['0deg', '90deg', '180deg', '270deg'], Object.keys(@image_keys))

  populate_image_keys: () ->
    missing_keys = 
    root_key = @image_keys['0deg']

    for missing_key in @missing_image_keys()
      rotated_type = LandTileKey.rotate_type(root_key.type, missing_key)
      @image_keys[missing_key] = LandTileKey.with_new_type(root_key, rotated_type)

  to_json: () ->
    root_key = @root_key()
    keys = _.fromPairs(_.map(_.toPairs(@image_keys), (pair) -> [pair[0], pair[1].safe_image_key()]))
    {
      @id
      @map_color
      zone: root_key.zone
      type: root_key.type
      variant: root_key.variant
      image_keys: keys
    }


  @from_json: (json) ->
    tile = new LandTile()
    tile.id = json.id

    json.image_keys = { '0deg':json.path } if json.path?

    if json.image_keys?
      tile.image_keys[orientation] = LandTileKey.parse(key) for orientation,key of json.image_keys

    tile.key = tile.image_keys['0deg']
    tile.map_color = json.map_color
    tile

module.exports = LandTile



path = require('path')
rbp = require('rectangle-bin-pack')

_ = require('lodash')
Jimp = require('jimp')

TEXTURE_WIDTH = 2048
TEXTURE_HEIGHT = 2048

class LandSpritesheet
  constructor: (@planet_type, @variant, @data_to_pack) ->
    console.log "#{@data_to_pack.length} tiles packed into #{@planet_type}.#{@variant}"

  texture_file_name: () -> "land.#{@planet_type}.texture.#{@variant}.png"

  render_to_texture: () ->
    image = new Jimp(TEXTURE_WIDTH, TEXTURE_HEIGHT)

    for data in @data_to_pack
      data.texture.image.scan(0, 0, data.texture.image.bitmap.width, data.texture.image.bitmap.height, (x, y, idx) ->
        red = this.bitmap.data[idx + 2] # red and blue are flipped?
        green = this.bitmap.data[idx + 1]
        blue  = this.bitmap.data[idx + 0] # red and blue are flipped?
        alpha = this.bitmap.data[idx + 3]
        return if red == 0 && green == 0 && blue == 255

        image.setPixelColor(Jimp.rgbaToInt(red, green, blue, alpha), x + data.x, y + data.y)
      )

    image

  data_json: () ->
    _.map(@data_to_pack, (data) ->
      {
        name: data.key
        position: {
          x: data.x
          y: data.y
        }
        dimension: {
          w: data.w
          h: data.h
        }
      }
    )

  @pack_textures: (planet_type, textures, texture_keys_used) ->
    data_to_pack = []
    for texture in textures
      spritesheet_key = texture.key_for_spritesheet()
      continue unless texture_keys_used.has(spritesheet_key)
      data_to_pack.push {
        key: spritesheet_key
        texture: texture
        w: texture.image.bitmap.width
        h: texture.image.bitmap.height
      }

    spritesheets = []
    spritesheet_index = 0
    while data_to_pack.length
      rbp.solveSync({w: TEXTURE_WIDTH, h: TEXTURE_HEIGHT}, data_to_pack)
      packed_until = _.findIndex(data_to_pack, (texture) -> !texture.x? || !texture.y?)
      packed_until = data_to_pack.length if packed_until < 0
      spritesheets.push new LandSpritesheet(planet_type, spritesheet_index, data_to_pack.slice(0, packed_until))
      data_to_pack = data_to_pack.slice(packed_until)
      spritesheet_index += 1
    spritesheets

module.exports = LandSpritesheet


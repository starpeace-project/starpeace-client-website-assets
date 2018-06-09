
path = require('path')
fs = require('fs-extra')
ShelfPack = require('@mapbox/shelf-pack')

_ = require('lodash')
Jimp = require('jimp')


DEBUG_MODE = true

class Spritesheet
  constructor: (@width, @height, @packed_texture_data) ->
    console.log "#{@packed_texture_data.length} textures packed into spritesheet"

  render_to_texture: (filter_blue, filter_white, filter_grey) ->
    image = new Jimp(@width, @height)

    for data in @packed_texture_data
      bitmap = data.texture.image.bitmap
      for y in [0...bitmap.height]
        for x in [0...bitmap.width]
          index = data.texture.image.getPixelIndex(x, y)

          red = bitmap.data[index + 2] # red and blue are flipped?
          green = bitmap.data[index + 1]
          blue  = bitmap.data[index + 0] # red and blue are flipped?
          alpha = bitmap.data[index + 3]
          continue if filter_blue && red == 0 && green == 0 && blue == 255
          continue if filter_white && red == 255 && green == 255 && blue == 255
          continue if filter_grey && red == 247 && green == 247 && blue == 247
  
          image.setPixelColor(Jimp.rgbaToInt(red, green, blue, alpha), x + data.x, y + data.y)

    image

  save_texture: (output_dir, texture_name, filter_blue, filter_white, filter_grey) ->
    texture_file = path.join(output_dir, texture_name)
    fs.mkdirsSync(path.dirname(texture_file))
    console.log "spritesheet texture saved to #{texture_file}"
    @render_to_texture(filter_blue, filter_white, filter_grey).write(texture_file)

  frames_json: () ->
    json = {}
    for data in @packed_texture_data
      json[data.key] = {
        frame: {
          x: data.x
          y: data.y
          w: data.w
          h: data.h
        }
      }
    json

  save_atlas: (output_dir, texture_name, atlas_name) ->
    json = {
      meta: {
        image: "./#{texture_name}"
      }
      frames: @frames_json()
    }

    spritesheet_atlas = path.join(output_dir, atlas_name)
    fs.mkdirsSync(path.dirname(spritesheet_atlas))
    fs.writeFileSync(spritesheet_atlas, if DEBUG_MODE then JSON.stringify(json, null, 2) else JSON.stringify(json))
    console.log "spritesheet atlas saved to #{spritesheet_atlas}"


  @pack_textures: (textures, texture_keys_used, width, height) ->
    data_to_pack = []
    for texture in textures
      spritesheet_key = texture.key_for_spritesheet()
      continue unless spritesheet_key?.length && texture_keys_used.has(spritesheet_key)

      data_to_pack.push {
        key: spritesheet_key
        texture: texture
        w: texture.width()
        h: texture.height()
      }

    spritesheets = []
    while data_to_pack.length
      sprite = new ShelfPack(width, height, { autoResize: false })
      sprite.pack(data_to_pack, { inPlace: true })

      packed_until = _.findIndex(data_to_pack, (texture_data) -> !texture_data.x? || !texture_data.y?)
      packed_until = data_to_pack.length if packed_until < 0
      spritesheets.push new Spritesheet(width, height, data_to_pack.slice(0, packed_until))
      data_to_pack = data_to_pack.slice(packed_until)

    spritesheets

module.exports = Spritesheet


_ = require('lodash')
path = require('path')
fs = require('fs-extra')
Jimp = require('jimp')
ShelfPack = require('@mapbox/shelf-pack')

Utils = require('../utils/utils')

DEBUG_MODE = true

class Spritesheet
  constructor: (@index, @width, @height, @packed_texture_data) ->
    console.log " [OK] #{@packed_texture_data.length} textures packed into spritesheet"

  render_to_texture: () ->
    image = new Jimp(@width, @height)

    for data in @packed_texture_data
      bitmap = data.texture.bitmap
      for y in [0...bitmap.height]
        for x in [0...bitmap.width]
          index = data.texture.getPixelIndex(x, y)
          image.setPixelColor(Jimp.rgbaToInt(bitmap.data[index + 0], bitmap.data[index + 1], bitmap.data[index + 2], bitmap.data[index + 3]), x + data.x, y + data.y)
    image

  save_texture: (output_dir, texture_name) ->
    texture_file = path.join(output_dir, texture_name)
    fs.mkdirsSync(path.dirname(texture_file))
    console.log " [OK] spritesheet texture saved to #{texture_file}"
    @render_to_texture().write(texture_file)

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

  save_atlas: (output_dir, texture_name, atlas_name, debug_mode) ->
    json = {
      meta: {
        image: "./#{texture_name}"
      }
      frames: @frames_json()
    }

    spritesheet_atlas = path.join(output_dir, atlas_name)
    fs.mkdirsSync(path.dirname(spritesheet_atlas))
    fs.writeFileSync(spritesheet_atlas, if debug_mode then JSON.stringify(json, null, 2) else JSON.stringify(json))
    console.log " [OK] spritesheet atlas saved to #{spritesheet_atlas}"

  @data_from_texture: (texture, texture_keys_used) ->
    spritesheet_key = texture.key_for_spritesheet()
    return null unless spritesheet_key?.length && (!texture_keys_used.size || texture_keys_used.has(spritesheet_key))

    image_for_sheet = Utils.clone_image(texture.image.bitmap, texture.filter_mode())
    image_for_sheet.resize(texture.target_width, Jimp.AUTO) if texture.target_width? && texture.width() != texture.target_width

    {
      key: spritesheet_key
      texture: image_for_sheet
      w: image_for_sheet.bitmap.width
      h: image_for_sheet.bitmap.height
    }

  @add_group_to_spritesheet: (sprite, group) ->
    added_bins = []
    for texture in group
      bin = sprite.packOne(texture.w, texture.h, texture.key)
      added_bins.push(bin) if bin?

    if added_bins.length == group.length
      for texture,index in group
        texture.x = added_bins[index].x
        texture.y = added_bins[index].y
    else
      sprite.unref(bin) for bin in added_bins

    added_bins.length == group.length

  @add_solo_to_spritesheet: (sprite, solo) ->
    bin = sprite.packOne(solo.w, solo.h, solo.key)
    if bin?
      solo.x = bin.x
      solo.y = bin.y
    bin?

  @pack_textures: (textures, texture_keys_used, width, height) ->
    groups_to_pack = []
    solo_to_pack = []
    for texture in textures
      is_array = Array.isArray(texture)

      if is_array && texture.length > 1
        groups_to_pack.push(_.compact(_.map(texture, (t) -> Spritesheet.data_from_texture(t, texture_keys_used))))
      else
        data = Spritesheet.data_from_texture((if is_array then texture[0] else texture), texture_keys_used)
        solo_to_pack.push(data) if data?

    groups_to_pack.sort((lhs, rhs) -> rhs[0].h - lhs[0].h)
    solo_to_pack.sort((lhs, rhs) -> rhs.h - lhs.h)

    spritesheets = []
    current_data = []
    current_sheet = new ShelfPack(width, height, { autoResize: false })
    while groups_to_pack.length
      if Spritesheet.add_group_to_spritesheet(current_sheet, groups_to_pack[0])
        current_data.push(data) for data in groups_to_pack.shift()
      else
        while solo_to_pack.length && Spritesheet.add_solo_to_spritesheet(current_sheet, solo_to_pack[0])
          current_data.push(solo_to_pack.shift())
        spritesheets.push new Spritesheet(spritesheets.length, width, height, current_data)
        current_data = []
        current_sheet = new ShelfPack(width, height, { autoResize: false })
      true

    while solo_to_pack.length
      if Spritesheet.add_solo_to_spritesheet(current_sheet, solo_to_pack[0])
        current_data.push(solo_to_pack.shift())
      else
        spritesheets.push new Spritesheet(spritesheets.length, width, height, current_data)
        current_data = []
        current_sheet = new ShelfPack(width, height, { autoResize: false })
      true

    spritesheets.push(new Spritesheet(spritesheets.length, width, height, current_data)) if current_data.length
    spritesheets

module.exports = Spritesheet

crypto = require('crypto')
_ = require('lodash')
path = require('path')
fs = require('fs')

Jimp = require('jimp')
streamToArray = require('stream-to-array')
gifFrames = require('gif-frames')

class Utils
  @random_md5: () ->
    data = (Math.random() * new Date().getTime()) + "asdf" + (Math.random() * 1000000) + "fdsa" +(Math.random() * 1000000)
    crypto.createHash('md5').update(data).digest('hex')

  @format_color: (color) ->
    "#{color.toString().padStart(10)} (##{Number(color).toString(16).padStart(6, '0')}"

  @clone_image: (source_bitmap, swap_rb, filter_mode) ->
    image = new Jimp(source_bitmap.width, source_bitmap.height)
    image.background(0x00000000)

     # red and blue are flipped in land bmp's
    r_index = if swap_rb then 2 else 0
    b_index = if swap_rb then 0 else 2

    for y in [0...source_bitmap.height]
      for x in [0...source_bitmap.width]
        index = image.getPixelIndex(x, y)
        red = source_bitmap.data[index + r_index]
        green = source_bitmap.data[index + 1]
        blue  = source_bitmap.data[index + b_index]
        alpha = source_bitmap.data[index + 3]
        # continue if filter_mode.black && red == 0 && green == 0 && blue == 0
        continue if filter_mode.blue && red == 0 && green == 0 && blue == 255
        continue if filter_mode.white && red == 255 && green == 255 && blue == 255
        continue if filter_mode.grey && red == 247 && green == 247 && blue == 247
        continue if filter_mode.grey160 && red == 160 && green == 160 && blue == 160

        image.setPixelColor(Jimp.rgbaToInt(red, green, blue, alpha), x, y)

    image

  @load_and_group_animation: (image_file_paths) ->
    Promise.all(_.map(image_file_paths, (file_path) -> new Promise (done) ->
      gifFrames({ url: file_path, frames: 'all', outputType: 'png' })
        .then (data) -> done(data)
        .catch (error) -> console.log "failed to load #{file_path}"
    ))
    .then (frame_groups) -> new Promise (done) ->
      Promise.all(_.map(frame_groups, (group) -> Utils.group_to_buffer(group))).then(done)

  @group_to_buffer: (frame_group) ->
    new Promise (done) ->
      Promise.all(_.map(frame_group, (frame) -> new Promise (inner_done) ->
        streamToArray(frame.getImage()).then (parts) ->
          Jimp.read(Buffer.concat(_.map(parts, (part) -> Buffer.from(part)))).then (image) ->
            inner_done([frame.frameIndex, image])
      )).then(done)


module.exports = Utils

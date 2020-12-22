crypto = require('crypto')
_ = require('lodash')
path = require('path')
fs = require('fs')

Jimp = require('jimp')
streamToArray = require('stream-to-array')
gifFrames = require('gif-frames')

ConsoleProgressUpdater = require('./console-progress-updater')

class Utils
  @random_md5: () ->
    data = (Math.random() * new Date().getTime()) + "asdf" + (Math.random() * 1000000) + "fdsa" +(Math.random() * 1000000)
    crypto.createHash('md5').update(data).digest('hex')

  @format_color: (color) ->
    "#{color.toString().padStart(10)} (##{Number(color).toString(16).padStart(6, '0')}"

  @clone_image: (source_bitmap, filter_mode) ->
    image = new Jimp(source_bitmap.width, source_bitmap.height)
    image.background(0x00000000)

    for y in [0...source_bitmap.height]
      for x in [0...source_bitmap.width]
        index = image.getPixelIndex(x, y)
        red = source_bitmap.data[index + 0]
        green = source_bitmap.data[index + 1]
        blue  = source_bitmap.data[index + 2]
        alpha = source_bitmap.data[index + 3]
        # continue if filter_mode.black && red == 0 && green == 0 && blue == 0
        continue if filter_mode.blue && red == 0 && green == 0 && blue == 255
        continue if filter_mode.white && red == 255 && green == 255 && blue == 255
        continue if filter_mode.grey && red == 247 && green == 247 && blue == 247
        continue if filter_mode.grey160 && red == 160 && green == 160 && blue == 160
        continue if filter_mode.road_colors && (red == 39 && green == 84 && blue == 99 || red == 255 && green == 255 && blue == 255)

        image.setPixelColor(Jimp.rgbaToInt(red, green, blue, alpha), x, y)

    image

  @load_and_group_animation: (root_dir, image_file_paths, show_progress=false) ->
    progress_updater = new ConsoleProgressUpdater(image_file_paths.length) if show_progress
    Promise.all(_.map(image_file_paths, (file_path) -> new Promise (done) ->
      gif_path = if root_dir? then path.resolve(root_dir, file_path) else file_path
      gifFrames({ url: gif_path, frames: 'all', outputType: 'png' })
        .then (data) ->
          progress_updater.next() if progress_updater?
          done(data)
        .catch (error) -> console.log "failed to load #{file_path}"
    ))
    .then (frame_groups) -> new Promise (done) ->
      progress_updater = new ConsoleProgressUpdater(3 * _.sum(_.map(frame_groups, 'length'))) if show_progress
      Promise.all(_.map(frame_groups, (group) -> Utils.group_to_buffer(group, progress_updater))).then(done)

  @group_to_buffer: (frame_group, progress_updater) ->
    new Promise (done) ->
      Promise.all(_.map(frame_group, (frame) -> new Promise (inner_done) ->
        progress_updater.next() if progress_updater?
        streamToArray(frame.getImage()).then (parts) ->
          progress_updater.next() if progress_updater?
          Jimp.read(Buffer.concat(_.map(parts, (part) -> Buffer.from(part)))).then (image) ->
            progress_updater.next() if progress_updater?
            inner_done([frame.frameIndex, image])
      )).then(done)


module.exports = Utils

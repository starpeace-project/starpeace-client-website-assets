
_ = require('lodash')
Jimp = require('jimp')

ConsoleProgressUpdater = require('../utils/console-progress-updater')
FileUtils = require('../utils/file-utils')
Texture = require('../texture/texture')
Utils = require('../utils/utils')


module.exports = class RoadTexture extends Texture
  constructor: (@file_path, image, @target_width) ->
    super(image)

    @_swap_rb_of_rgb = @file_path.indexOf('.bmp') > 0
    @id = @file_path.replace('.bmp', '').replace('.png', '')
    @target_height = image.height * (image.width / @target_width)

  toString: () -> "#{@id} => #{@width()}x#{@height()}"

  target_width: () -> @target_width

  key_for_spritesheet: () -> @id

  filter_mode: () -> { road_colors: true }
  swap_rb_of_rgb: () -> @_swap_rb_of_rgb

  @load: (road_dir) ->
    new Promise (fulfill, reject) ->
      console.log "loading road textures from #{road_dir}\n"

      image_file_paths = _.filter(FileUtils.read_all_files_sync(road_dir), (file_path) -> file_path.indexOf('legacy') < 0 && (file_path.endsWith('.bmp') || file_path.endsWith('.png')))
      Promise.all(_.map(image_file_paths, (file_path) -> Jimp.read(file_path)))
        .then (images) ->
          progress = new ConsoleProgressUpdater(images.length)
          _.map(_.zip(image_file_paths, images), (pair) ->
            image = new RoadTexture(pair[0].substring(road_dir.length + 1), pair[1], 64)
            progress.next()
            image
          )
        .then fulfill
        .catch reject


_ = require('lodash')
Jimp = require('jimp')

ConsoleProgressUpdater = require('../utils/console-progress-updater')
FileUtils = require('../utils/file-utils')
Texture = require('../texture/texture')
Utils = require('../utils/utils')


module.exports = class ConcreteTexture extends Texture
  constructor: (@file_path, image, @target_width) ->
    super(image)

    @id = @file_path.replace('.png', '')
    @target_height = image.height * (image.width / @target_width)

  toString: () -> "#{@id} => #{@width()}x#{@height()}"

  target_width: () -> @target_width

  key_for_spritesheet: () -> @id

  filter_mode: () -> { black: false, blue: false, white: false, grey: false, green: false, grey160: false }


  @load: (concrete_dir) ->
    new Promise (fulfill, reject) ->
      console.log "loading concrete textures from #{concrete_dir}\n"

      image_file_paths = _.filter(FileUtils.read_all_files_sync(concrete_dir), (file_path) -> file_path.indexOf('legacy') < 0 && file_path.endsWith('.png'))
      Promise.all(_.map(image_file_paths, (file_path) -> Jimp.read(file_path)))
        .then (images) ->
          progress = new ConsoleProgressUpdater(images.length)
          _.map(_.zip(image_file_paths, images), (pair) ->
            image = new ConcreteTexture(pair[0].substring(concrete_dir.length + 1), pair[1], 64)
            progress.next()
            image
          )
        .then fulfill
        .catch reject

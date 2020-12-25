_ = require('lodash')
Jimp = require('jimp')

ConsoleProgressUpdater = require('../utils/console-progress-updater')
FileUtils = require('../utils/file-utils')
Utils = require('../utils/utils')

module.exports = class Texture
  constructor: (@id, @image, @target_width, @target_height) ->
    @target_height = @image.height * (@image.width / @target_width) if @target_width? && !@target_height?

  toString: () -> "#{@id} => #{@width()}x#{@height()}"

  width: () -> @image?.bitmap?.width || 0
  height: () -> @image?.bitmap?.height || 0

  key_for_spritesheet: () -> @id

  filter_mode: () -> { }

  get_frame_textures: (root_id, width, height) -> [new Texture(root_id, @image, width, height)]

  @load: (directory) ->
    console.log "loading animated textures from #{directory}\n"

    image_file_paths = _.filter(FileUtils.read_all_files_sync(directory), (file_path) -> file_path.indexOf('legacy') < 0 && (file_path.endsWith('.bmp') || file_path.endsWith('.png')))
    progress = new ConsoleProgressUpdater(image_file_paths.length)
    images = await Promise.all(_.map(image_file_paths, (file_path) ->
      img = Jimp.read(file_path)
      progress.next()
      img
    ))

    _.map(_.zip(image_file_paths, images), (pair) ->
      file_path = pair[0].substring(directory.length + 1)
      image = new Texture(file_path.replace('.bmp', '').replace('.png', ''), pair[1])
      image.file_path = file_path
      image
    )

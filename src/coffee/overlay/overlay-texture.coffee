
_ = require('lodash')
path = require('path')
Jimp = require('jimp')

OverlayFrameTexture = require('./overlay-frame-texture')
ConsoleProgressUpdater = require('../utils/console-progress-updater')
FileUtils = require('../utils/file-utils')
Utils = require('../utils/utils')

module.exports = class OverlayTexture
  constructor: (@file_path, @image) ->
    @id = @file_path.replace('.png', '')

  get_frame_textures: (root_id, width, height) ->
    [new OverlayFrameTexture("#{root_id}.#{@id}", @image, width, height)]

  @load: (overlay_dir) ->
    new Promise (fulfill, reject) ->
      console.log "loading overlay textures from #{overlay_dir}\n"

      image_file_paths = _.filter(FileUtils.read_all_files_sync(overlay_dir), (file_path) -> file_path.indexOf('legacy') < 0 && file_path.endsWith('.png'))
      Promise.all(_.map(image_file_paths, (file_path) -> Jimp.read(file_path)))
        .then (images) ->
          progress = new ConsoleProgressUpdater(images.length)
          _.map(_.zip(image_file_paths, images), (pair) ->
            image = new OverlayTexture(pair[0].substring(overlay_dir.length + 1), pair[1])
            progress.next()
            image
          )
        .then fulfill
        .catch reject

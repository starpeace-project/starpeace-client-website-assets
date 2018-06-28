
path = require('path')
crypto = require('crypto')

_ = require('lodash')
Jimp = require('jimp')

LandAttributes = require('../land-attributes')

Texture = require('../../texture/texture')
ConsoleProgressUpdater = require('../../utils/console-progress-updater')
FileUtils = require('../../utils/file-utils')


class TreeTexture extends Texture
  constructor: (@directory, @file_path, image) ->
    super(image)

    @planet_type = LandAttributes.planet_type_from_value(@file_path)
    @season = LandAttributes.season_from_value(@file_path)

    key_match = /tree\.(\S+)\.(\S+)\.bmp/.exec(path.basename(@file_path))
    if key_match
      @variant = key_match[2]
      @zone = LandAttributes.zone_from_value(key_match[1])
    else
      @variant = Number.NaN
      @zone = LandAttributes.ZONES.other

  ideal_file_name: () ->
    "tree.#{@zone}.#{@variant.toString().padStart(2, '0')}.bmp"

  key_for_spritesheet: () ->
    "#{@season}.#{@zone}.#{@variant.toString().padStart(2, '0')}"

  filter_mode: () -> { blue: true, white: true, grey: true, green: false }

  @load: (land_dir) ->
    new Promise (fulfill, reject) ->
      console.log "loading tree textures from #{land_dir}\n"

      image_file_paths = _.filter(FileUtils.read_all_files_sync(land_dir), (file_path) -> path.basename(file_path).startsWith('tree') && file_path.endsWith('.bmp'))
      Promise.all(_.map(image_file_paths, (file_path) -> Jimp.read(file_path)))
      .then (images) ->
        progress = new ConsoleProgressUpdater(images.length)
        _.map(_.zip(image_file_paths, images), (pair) ->
          image = new TreeTexture(land_dir, pair[0].substring(land_dir.length + 1), pair[1])
          progress.next()
          image
        )
      .then fulfill
      .catch(reject)

module.exports = TreeTexture

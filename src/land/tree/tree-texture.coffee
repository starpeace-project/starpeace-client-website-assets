_ = require('lodash')
path = require('path')
crypto = require('crypto')
Jimp = require('jimp')

LandAttributes = require('../land-attributes')
Texture = require('../../common/texture')
ConsoleProgressUpdater = require('../../utils/console-progress-updater')
FileUtils = require('../../utils/file-utils')


module.exports = class TreeTexture extends Texture
  constructor: (@directory, @file_path, image) ->
    super(null, image)

    @planet_type = LandAttributes.planet_type_from_value(@file_path)
    @season = LandAttributes.season_from_value(@file_path)

    key_match = /tree\.(\S+)\.(\S+)\.bmp/.exec(path.basename(@file_path))
    if key_match
      @variant = key_match[2]
      @zone = LandAttributes.zone_from_value(key_match[1])
    else
      @variant = Number.NaN
      @zone = LandAttributes.ZONES.other

  ideal_file_name: () -> "tree.#{@zone}.#{@variant.toString().padStart(2, '0')}.bmp"
  key_for_spritesheet: () -> "#{@season}.#{@zone}.#{@variant.toString().padStart(2, '0')}"

  filter_mode: () -> { blue: true, white: true, grey: true }

  @load: (land_dir) ->
    console.log "loading tree textures from #{land_dir}\n"

    image_file_paths = _.filter(FileUtils.read_all_files_sync(land_dir), (file_path) -> path.basename(file_path).startsWith('tree') && file_path.endsWith('.bmp'))
    progress = new ConsoleProgressUpdater(image_file_paths.length)
    images = await Promise.all(_.map(image_file_paths, (file_path) ->
      img = Jimp.read(file_path)
      progress.next()
      img
    ))

    _.map(_.zip(image_file_paths, images), (pair) -> new TreeTexture(land_dir, pair[0].substring(land_dir.length + 1), pair[1]))

_ = require('lodash')
path = require('path')
crypto = require('crypto')
Jimp = require('jimp')

Texture = require('../../common/texture')
LandAttributes = require('../land-attributes')
ConsoleProgressUpdater = require('../../utils/console-progress-updater')
FileUtils = require('../../utils/file-utils')


class GroundTexture extends Texture
  constructor: (@directory, @file_path, image) ->
    super(null, image)

    @hash = GroundTexture.image_hash(@image.bitmap.width, @image.bitmap.height, @image.bitmap.data)
    @map_color = GroundTexture.calculate_map_color(@image.bitmap.width, @image.bitmap.height, @image.bitmap.data)

    @planet_type = LandAttributes.planet_type_from_value(@file_path)
    @season = LandAttributes.season_from_value(@file_path)

    attributes = LandAttributes.parse(path.basename(@file_path))
    @id = attributes.id
    @zone = attributes.zone
    @type = attributes.type
    @variant = attributes.variant


  ideal_file_name: () -> "ground.#{@id.toString().padStart(3, '0')}.#{@zone}.#{@type}.#{@variant}.bmp"
  key_for_spritesheet: () -> "#{@season}.#{@id.toString().padStart(3, '0')}.#{@zone}.#{@type}.#{@variant}"

  filter_mode: () -> { blue: true, grey: true }

  has_valid_attributes: () ->
    @planet_type != LandAttributes.PLANET_TYPES.other && @season != LandAttributes.SEASONS.other &&
      !isNaN(@id) &&
      @zone != LandAttributes.ZONES.other &&
      @type != LandAttributes.TYPES.other &&
      !isNaN(@variant)

  has_valid_file_name: () ->
    @ideal_file_name() == path.basename(@file_path)


  @image_hash: (width, height, bitmap_data) ->
    return 0 unless width && height && bitmap_data
    data = ''
    for y in [0...height]
      for x in [0...width]
        index = y * width + x
        data += (bitmap_data[index] + bitmap_data[index + 1] + bitmap_data[index + 2] + bitmap_data[index + 3])
    crypto.createHash('md5').update(data).digest('hex')

  @calculate_map_color: (width, height, bitmap_data) ->
    return 0 unless width && height && bitmap_data
    count = 0
    r = 0
    g = 0
    b = 0
    for y in [0...height]
      for x in [0...width]
        index = y * width + x
        continue if (bitmap_data[index + 3] == 255) ||
          (bitmap_data[index] == 0 && bitmap_data[index + 1] == 255 && bitmap_data[index + 2] == 255) ||
          (bitmap_data[index] == 255 && bitmap_data[index + 1] == 255 && bitmap_data[index + 2] == 255)
        r += bitmap_data[index + 2]
        g += bitmap_data[index + 1]
        b += bitmap_data[index + 0]
        count += 1
    ((r / count) << 16) | ((g / count) << 8) | ((b / count) << 0)

  @load: (land_dir) ->
    new Promise (fulfill, reject) ->
      console.log "loading land textures from #{land_dir}\n"

      image_file_paths = _.filter(FileUtils.read_all_files_sync(land_dir), (file_path) -> path.basename(file_path).startsWith('ground') && file_path.endsWith('.bmp'))
      Promise.all(_.map(image_file_paths, (file_path) -> Jimp.read(file_path)))
      .then (images) ->
        progress = new ConsoleProgressUpdater(images.length)
        _.map(_.zip(image_file_paths, images), (pair) ->
          image = new GroundTexture(land_dir, pair[0].substring(land_dir.length + 1), pair[1])
          progress.next()
          image
        )
      .then fulfill
      .catch(reject)

module.exports = GroundTexture

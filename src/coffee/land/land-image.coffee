
path = require('path')
crypto = require('crypto')

_ = require('lodash')
Jimp = require('jimp')

LandTileKey = require('./land-tile-key')

#
# simple representation of land tile metadata; originally from /LandClasses/*.ini
#
class LandImage
  constructor: (@key, @directory, @file_path, @image) ->
    @hash = LandImage.image_hash(@image)
    @map_color = LandImage.calculate_map_color(@image)

  valid: () ->
    @key.valid() && @key.safe_image_key() == path.basename(@file_path)

  @image_hash: (image) ->
    return 0 unless image
    data = ''
    for y in [0...image.bitmap.height]
      for x in [0...image.bitmap.width]
        index = y * image.bitmap.width + x
        data += (image.bitmap.data[index] + image.bitmap.data[index + 1] + image.bitmap.data[index + 2] + image.bitmap.data[index + 3])
    crypto.createHash('md5').update(data).digest("hex")

  @calculate_map_color: (image) ->
    return 0 unless image
    count = 0
    r = 0
    g = 0
    b = 0
    for y in [0...image.bitmap.height]
      for x in [0...image.bitmap.width]
        pixel = image.getPixelColor(x, y)
        continue if pixel == 0x0000FFFF || pixel == 0xFF0000FF || pixel == 0x00FF00FF || pixel == 0xFFFFFFFF
        rgba = Jimp.intToRGBA(pixel)
        r += rgba.r
        g += rgba.g
        b += rgba.b
        count += 1
    ((r / count) << 16) | ((g / count) << 8) | ((b / count) << 0) 

  @from: (directory, file_path, image) ->
    new LandImage(LandTileKey.parse(path.basename(file_path)), directory, file_path, image)


module.exports = LandImage


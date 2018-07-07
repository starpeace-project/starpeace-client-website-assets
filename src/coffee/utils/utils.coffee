
path = require('path')
fs = require('fs')
Jimp = require('jimp')

class Utils
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

module.exports = Utils

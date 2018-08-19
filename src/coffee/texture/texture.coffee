
class Texture
  constructor: (@image) ->

  width: () -> @image?.bitmap?.width || 0
  height: () -> @image?.bitmap?.height || 0

  key_for_spritesheet: () -> null

  filter_mode: () -> { blue: false, white: false, grey: false, green: false, grey160:false }

  swap_rb_of_rgb: () -> false

module.exports = Texture

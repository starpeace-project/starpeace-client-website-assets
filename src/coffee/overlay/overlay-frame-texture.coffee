
Texture = require('../texture/texture')

module.exports = class OverlayFrameTexture extends Texture
  constructor: (@id, image, @target_width, @target_height) ->
    super(image)

  toString: () -> "#{@id} => #{@width()}x#{@height()}"

  target_width: () -> @target_width

  key_for_spritesheet: () -> @id

  filter_mode: () -> { black: false, blue: false, white: false, grey: false, green: false, grey160: false }

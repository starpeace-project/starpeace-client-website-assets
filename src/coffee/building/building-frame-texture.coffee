
path = require('path')

_ = require('lodash')

Texture = require('../texture/texture')

class BuildingFrameTexture extends Texture
  constructor: (@id, image, @target_width) ->
    super(image)


  toString: () -> "#{@id} => #{@width()}x#{@height()}"

  target_width: () -> @target_width

  key_for_spritesheet: () -> @id

  filter_mode: () -> { black: true, blue: true, white: true, grey: true, green: true, grey160: true }

module.exports = BuildingFrameTexture

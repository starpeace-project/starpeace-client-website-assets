_ = require('lodash')
path = require('path')

Texture = require('../common/texture')

module.exports = class BuildingFrameTexture extends Texture
  constructor: (id, image, target_width) ->
    super(id, image, target_width)

  filter_mode: () -> { blue: true, grey: true, green: true, grey160: true }

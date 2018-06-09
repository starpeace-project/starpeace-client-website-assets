
class Texture
  constructor: (@image) ->

  width: () -> @image?.bitmap?.width || 0
  height: () -> @image?.bitmap?.height || 0

  key_for_spritesheet: () -> null

module.exports = Texture

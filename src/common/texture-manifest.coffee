
module.exports = class TextureManifest
  constructor: (@textures) ->
    @by_file_path = {}
    @by_file_path[texture.file_path] = texture for texture in @textures

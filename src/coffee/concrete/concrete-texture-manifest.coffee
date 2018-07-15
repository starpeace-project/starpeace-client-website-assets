
ConcreteTexture = require('./concrete-texture')

module.exports = class ConcreteTextureManifest
  constructor: (@all_textures) ->
    @by_file_path = {}
    @by_file_path[texture.file_path] = texture for texture in @all_textures

  @load: (land_dir) ->
    new Promise (fulfill, reject) ->
      ConcreteTexture.load(land_dir)
        .then (textures) ->
          console.log "found and loaded #{textures.length} concrete textures into manifest\n"
          fulfill(new ConcreteTextureManifest(textures))
        .catch reject

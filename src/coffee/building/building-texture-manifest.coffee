
path = require('path')
crypto = require('crypto')
_ = require('lodash')

BuildingTexture = require('./building-texture')

class BuildingTextureManifest
  constructor: (@all_textures) ->
    @by_id = {}
    @by_file_path = {}

    for texture in @all_textures
      @by_file_path[texture.file_path] = texture
      @by_id[texture.id] = texture

  @load: (land_dir) ->
    new Promise (fulfill, reject) ->
      BuildingTexture.load(land_dir)
        .then (textures) ->
          console.log "found and loaded #{textures.length} building textures into manifest\n"
          fulfill(new BuildingTextureManifest(textures))
        .catch reject

module.exports = BuildingTextureManifest

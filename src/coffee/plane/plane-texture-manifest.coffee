
path = require('path')
crypto = require('crypto')
_ = require('lodash')

PlaneTexture = require('./plane-texture')

module.exports = class PlaneTextureManifest
  constructor: (@all_textures) ->
    @by_file_path = {}

    for texture in @all_textures
      @by_file_path[texture.file_path] = texture

  @load: (land_dir) ->
    new Promise (fulfill, reject) ->
      PlaneTexture.load(land_dir)
        .then (textures) ->
          console.log "found and loaded #{textures.length} plane textures into manifest\n"
          fulfill(new PlaneTextureManifest(textures))
        .catch reject

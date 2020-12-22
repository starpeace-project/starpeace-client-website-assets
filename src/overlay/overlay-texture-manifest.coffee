
path = require('path')
crypto = require('crypto')
_ = require('lodash')

OverlayTexture = require('./overlay-texture')

module.exports = class OverlayTextureManifest
  constructor: (@all_textures) ->
    @by_file_path = {}

    for texture in @all_textures
      @by_file_path[texture.file_path] = texture

  @load: (land_dir) ->
    new Promise (fulfill, reject) ->
      OverlayTexture.load(land_dir)
        .then (textures) ->
          console.log "found and loaded #{textures.length} overlay textures into manifest\n"
          fulfill(new OverlayTextureManifest(textures))
        .catch reject

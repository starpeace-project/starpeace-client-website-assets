
path = require('path')
crypto = require('crypto')
_ = require('lodash')

EffectTexture = require('./effect-texture')

module.exports = class EffectTextureManifest
  constructor: (@all_textures) ->
    @by_file_path = {}

    for texture in @all_textures
      @by_file_path[texture.file_path] = texture

  @load: (effect_dir) ->
    new Promise (fulfill, reject) ->
      EffectTexture.load(effect_dir)
        .then (textures) ->
          console.log "found and loaded #{textures.length} effect textures into manifest\n"
          fulfill(new EffectTextureManifest(textures))
        .catch reject

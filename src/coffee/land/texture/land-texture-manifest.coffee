
path = require('path')
crypto = require('crypto')

_ = require('lodash')
Jimp = require('jimp')

LandTexture = require('./land-texture')

ConsoleProgressUpdater = require('../../utils/console-progress-updater')
FileUtils = require('../../utils/file-utils')


class LandTextureManifest
  constructor: (@all_textures) ->


  @load: (land_dir) ->
    new Promise (fulfill, reject) ->
      LandTexture.load(land_dir)
        .then (textures) ->
          console.log "found and loaded #{textures.length} land textures into manifest\n"
          fulfill(new LandTextureManifest(textures))
        .catch reject

module.exports = LandTextureManifest

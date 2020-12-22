

GroundTexture = require('./ground-texture')


class GroundTextureManifest
  constructor: (@all_textures) ->

  for_planet_type: (planet_type) ->
    textures = []
    for texture in @all_textures
      textures.push texture if texture.planet_type == planet_type
    Array.from(textures)

  @load: (land_dir) ->
    new Promise (fulfill, reject) ->
      GroundTexture.load(land_dir)
        .then (textures) ->
          console.log "found and loaded #{textures.length} ground textures into manifest\n"
          fulfill(new GroundTextureManifest(textures))
        .catch reject

module.exports = GroundTextureManifest

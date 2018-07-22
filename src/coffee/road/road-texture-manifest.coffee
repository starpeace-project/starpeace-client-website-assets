
RoadTexture = require('./road-texture')

module.exports = class RoadTextureManifest
  constructor: (@all_textures) ->
    @by_file_path = {}
    @by_file_path[texture.file_path] = texture for texture in @all_textures

  @load: (road_dir) ->
    new Promise (fulfill, reject) ->
      RoadTexture.load(road_dir)
        .then (textures) ->
          console.log "found and loaded #{textures.length} road textures into manifest\n"
          fulfill(new RoadTextureManifest(textures))
        .catch reject

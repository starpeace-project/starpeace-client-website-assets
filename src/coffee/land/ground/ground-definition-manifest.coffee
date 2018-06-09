
path = require('path')
fs = require('fs')

_ = require('lodash')

GroundDefinition = require('./ground-definition')


class GroundDefinitionManifest
  constructor: (@all_tiles) ->
    @tiles_from_metadata = {
      by_id: {}
      by_color: {}
      by_key: {}
    }

    for tile in @all_tiles
      (@tiles_from_metadata.by_id[tile.id] ||= []).push tile
      (@tiles_from_metadata.by_color[tile.map_color] ||= []).push = tile
      (@tiles_from_metadata.by_key[tile.key()] ||= []).push = tile

  for_planet_type: (planet_type) ->
    definitions = []
    for tile in @all_tiles
      definitions.push tile if tile.planet_type == planet_type
    Array.from(definitions)

  @load: (land_dir) ->
    new Promise (fulfill, reject) ->
      console.log "loading ground definition manifest from #{land_dir}\n"

      manifest = new GroundDefinitionManifest(_.map(JSON.parse(fs.readFileSync(path.join(land_dir, 'ground-manifest.json'))), GroundDefinition.from_json))
      console.log "found and loaded #{manifest.all_tiles.length} ground definitions\n"
      fulfill(manifest)

module.exports = GroundDefinitionManifest

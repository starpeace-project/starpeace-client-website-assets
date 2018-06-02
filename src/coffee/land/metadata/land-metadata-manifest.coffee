
path = require('path')
fs = require('fs')

_ = require('lodash')

LandTile = require('./land-tile')


class LandMetadataManifest
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


  @load: (land_dir) ->
    new Promise (fulfill, reject) ->
      console.log "loading land metadata manifest from #{land_dir}\n"

      manifest = new LandMetadataManifest(_.map(JSON.parse(fs.readFileSync(path.join(land_dir, 'manifest.json'))), LandTile.from_json))
      console.log "found and loaded #{manifest.all_tiles.length} tile metadata\n"
      fulfill(manifest)

module.exports = LandMetadataManifest

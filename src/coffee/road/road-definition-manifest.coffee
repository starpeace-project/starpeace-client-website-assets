
_ = require('lodash')
fs = require('fs')
path = require('path')

RoadDefinition = require('./road-definition')

module.exports = class RoadDefinitionManifest
  constructor: (@all_definitions) ->

  @load: (road_dir) ->
    new Promise (fulfill, reject) ->
      console.log "loading road definition manifest from #{road_dir}\n"

      manifest = new RoadDefinitionManifest(_.map(JSON.parse(fs.readFileSync(path.join(road_dir, 'road-manifest.json'))), RoadDefinition.fromJson))
      console.log "found and loaded #{manifest.all_definitions.length} road definitions\n"
      fulfill(manifest)

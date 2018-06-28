
path = require('path')
fs = require('fs')

_ = require('lodash')

BuildingDefinition = require('./building-definition')


class BuildingDefinitionManifest
  constructor: (@all_definitions) ->

  @load: (building_dir) ->
    new Promise (fulfill, reject) ->
      console.log "loading building definition manifest from #{building_dir}\n"

      manifest = new BuildingDefinitionManifest(_.map(JSON.parse(fs.readFileSync(path.join(building_dir, 'building-manifest.json'))), BuildingDefinition.from_json))
      console.log "found and loaded #{manifest.all_definitions.length} building definitions\n"
      fulfill(manifest)

module.exports = BuildingDefinitionManifest

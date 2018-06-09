
path = require('path')
fs = require('fs')

_ = require('lodash')

TreeDefinition = require('./tree-definition')


class TreeDefinitionManifest
  constructor: (@all_definitions) ->

  for_planet_type: (planet_type) ->
    definitions = []
    for definition in @all_definitions
      definitions.push definition if definition.planet_type == planet_type
    definitions

  @load: (land_dir) ->
    new Promise (fulfill, reject) ->
      console.log "loading tree definition manifest from #{land_dir}\n"

      manifest = new TreeDefinitionManifest(_.map(JSON.parse(fs.readFileSync(path.join(land_dir, 'tree-manifest.json'))), TreeDefinition.from_json))
      console.log "found and loaded #{manifest.all_definitions.length} tree definitions\n"
      fulfill(manifest)

module.exports = TreeDefinitionManifest

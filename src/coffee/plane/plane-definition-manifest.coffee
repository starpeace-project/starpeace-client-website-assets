
path = require('path')
fs = require('fs')

_ = require('lodash')

PlaneDefinition = require('./plane-definition')

module.exports = class PlaneDefinitionManifest
  constructor: (@all_definitions) ->

  @load: (plane_dir) ->
    new Promise (fulfill, reject) ->
      console.log " [OK] loading plane definition manifest from #{plane_dir}"
      manifest = new PlaneDefinitionManifest(_.map(JSON.parse(fs.readFileSync(path.join(plane_dir, 'plane-manifest.json'))), PlaneDefinition.from_json))
      console.log " [OK] found and loaded #{manifest.all_definitions.length} plane definitions\n"
      fulfill(manifest)

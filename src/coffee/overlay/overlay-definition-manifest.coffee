
path = require('path')
fs = require('fs')

_ = require('lodash')

OverlayDefinition = require('./overlay-definition')

module.exports = class OverlayDefinitionManifest
  constructor: (@all_definitions) ->

  @load: (plane_dir) ->
    new Promise (fulfill, reject) ->
      console.log "loading overlay definition manifest from #{plane_dir}\n"

      manifest = new OverlayDefinitionManifest(_.map(JSON.parse(fs.readFileSync(path.join(plane_dir, 'overlay-manifest.json'))), OverlayDefinition.from_json))
      console.log "found and loaded #{manifest.all_definitions.length} overlay definitions\n"
      fulfill(manifest)

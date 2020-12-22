
_ = require('lodash')
fs = require('fs')
path = require('path')

ConcreteDefinition = require('./concrete-definition')

module.exports = class ConcreteDefinitionManifest
  constructor: (@all_definitions) ->

  @load: (concrete_dir) ->
    new Promise (fulfill, reject) ->
      console.log "loading concrete definition manifest from #{concrete_dir}\n"

      manifest = new ConcreteDefinitionManifest(_.map(JSON.parse(fs.readFileSync(path.join(concrete_dir, 'concrete-manifest.json'))), ConcreteDefinition.fromJson))
      console.log "found and loaded #{manifest.all_definitions.length} concrete definitions\n"
      fulfill(manifest)

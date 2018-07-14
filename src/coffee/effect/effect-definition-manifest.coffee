
path = require('path')
fs = require('fs')

_ = require('lodash')

EffectDefinition = require('./effect-definition')

module.exports = class EffectDefinitionManifest
  constructor: (@all_definitions) ->

  @load: (effect_dir) ->
    new Promise (fulfill, reject) ->
      console.log "loading effect definition manifest from #{effect_dir}\n"

      manifest = new EffectDefinitionManifest(_.map(JSON.parse(fs.readFileSync(path.join(effect_dir, 'effect-manifest.json'))), EffectDefinition.from_json))
      console.log "found and loaded #{manifest.all_definitions.length} effect definitions\n"
      fulfill(manifest)

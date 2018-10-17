
path = require('path')
fs = require('fs-extra')
_ = require('lodash')

InventionDefinitionManifest = require('../invention/invention-definition-manifest')

DEBUG_MODE = false


write_assets = (output_dir) -> ([invention_definition_manifest]) ->
  new Promise (done) ->
    write_promises = []

    definitions = []
    definitions.push definition.to_compiled_json() for key,definition of invention_definition_manifest.all_definitions

    json = {
      inventions: definitions
    }

    metadata_file = path.join(output_dir, "invention.metadata.json")
    fs.mkdirsSync(path.dirname(metadata_file))
    fs.writeFileSync(metadata_file, if DEBUG_MODE then JSON.stringify(json, null, 2) else JSON.stringify(json))
    console.log "invention metadata saved to #{metadata_file}"

    Promise.all(write_promises).then (result) ->
      process.stdout.write '\n'
      done()


class CombineInventionManifest
  @combine: (inventions_dir, target_dir) ->
    new Promise (done, error) ->
      Promise.all [ InventionDefinitionManifest.load(inventions_dir) ]
        .then write_assets(target_dir)
        .then done
        .catch error

module.exports = CombineInventionManifest

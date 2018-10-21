
path = require('path')
fs = require('fs-extra')
_ = require('lodash')

InventionDefinitionManifest = require('../invention/invention-definition-manifest')

DEBUG_MODE = false


write_assets = (translations_manifest, output_dir) -> ([invention_definition_manifest]) ->
  new Promise (done) ->

    definitions = []
    for key,invention of invention_definition_manifest.all_definitions
      definitions.push invention.to_compiled_json()

      translations_manifest.accumulate_i18n_text(invention.name_key(), invention.name)
      translations_manifest.accumulate_i18n_text(invention.description_key(), invention.description)

    json = {
      inventions: definitions
    }

    metadata_file = path.join(output_dir, "invention.metadata.json")
    fs.mkdirsSync(path.dirname(metadata_file))
    fs.writeFileSync(metadata_file, if DEBUG_MODE then JSON.stringify(json, null, 2) else JSON.stringify(json))
    console.log "invention metadata saved to #{metadata_file}\n"

    done()


class CombineInventionManifest
  @combine: (translations_manifest, inventions_dir, target_dir) ->
    new Promise (done, error) ->
      Promise.all [ InventionDefinitionManifest.load(inventions_dir) ]
        .then write_assets(translations_manifest, target_dir)
        .then done
        .catch error

module.exports = CombineInventionManifest

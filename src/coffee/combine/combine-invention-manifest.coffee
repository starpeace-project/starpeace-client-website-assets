
path = require('path')
fs = require('fs-extra')
_ = require('lodash')

{
  InventionDefinition
} = require('@starpeace/starpeace-assets-types')

FileUtils = require('../utils/file-utils')

DEBUG_MODE = false


load_inventions = (inventions_dir) ->
  new Promise (done, error) ->
    try
      console.log " [OK] loading invention configurations from #{inventions_dir}"
      definitions = _.map(FileUtils.parse_to_json(inventions_dir, ['.json'], []), InventionDefinition.from_json)
      console.log " [OK] found #{definitions.length} invention definitions"

      done({ definitions })
    catch err
      error(err)

write_assets = (translations_manifest, output_dir) -> (combine_results) ->
  new Promise (done) ->
    for key,invention of combine_results.definitions
      translations_manifest.accumulate_i18n_text("invention.#{invention.id}.name", invention.name)
      translations_manifest.accumulate_i18n_text("invention.#{invention.id}.description", invention.description)

    json = {
      inventions: _.map(combine_results.definitions, (definition) ->
        {
          id: definition.id
          category: definition.category
          industry_type: definition.industry_type
          depends_on: definition.depends_on
          name_key: "invention.#{definition.id}.name"
          description_key: "invention.#{definition.id}.description"
          properties: definition.properties
        }
      )
    }

    metadata_file = path.join(output_dir, "invention.metadata.json")
    fs.mkdirsSync(path.dirname(metadata_file))
    fs.writeFileSync(metadata_file, if DEBUG_MODE then JSON.stringify(json, null, 2) else JSON.stringify(json))
    console.log " [OK] invention metadata saved to #{metadata_file}\n"

    done()


class CombineInventionManifest
  @combine: (translations_manifest, inventions_dir, target_dir) ->
    new Promise (done, error) ->
      load_inventions(inventions_dir)
        .then write_assets(translations_manifest, target_dir)
        .then done
        .catch error

module.exports = CombineInventionManifest

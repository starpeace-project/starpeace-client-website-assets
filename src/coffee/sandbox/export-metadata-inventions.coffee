
path = require('path')
fs = require('fs-extra')
_ = require('lodash')

STARPEACE = require('@starpeace/starpeace-assets-types')

ExportConfiguration = require('./export-configuration')
FileUtils = require('../utils/file-utils')

load_inventions = (inventions_dir) ->
  new Promise (done, error) ->
    try
      console.log " [OK] loading invention configurations from #{inventions_dir}"
      definitions = _.map(FileUtils.parse_to_json(inventions_dir, ['.json'], []), STARPEACE.invention.InventionDefinition.fromJson)
      console.log " [OK] found #{definitions.length} invention definitions"

      done({ definitions })
    catch err
      error(err)

write_assets = (output_dir) -> (combine_results) ->
  new Promise (done) ->
    json = {
      inventions: _.map(combine_results.definitions, (definition) -> definition.toJson())
    }

    metadata_file = path.join(output_dir, "metadata-invention.json")
    fs.mkdirsSync(path.dirname(metadata_file))
    fs.writeFileSync(metadata_file, if ExportConfiguration.DEBUG_MODE then JSON.stringify(json, null, 2) else JSON.stringify(json))
    console.log "\n [OK] invention metadata saved to #{metadata_file}\n"

    done()


class ExportMetadataInventions
  @export: (assets_dir, target_dir) ->
    new Promise (done, error) ->
      inventions_dir = path.join(assets_dir, 'inventions')
      load_inventions(inventions_dir)
        .then write_assets(target_dir)
        .then done
        .catch error

module.exports = ExportMetadataInventions

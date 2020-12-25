_ = require('lodash')
path = require('path')
fs = require('fs-extra')

STARPEACE = require('@starpeace/starpeace-assets-types')

ExportConfiguration = require('./export-configuration')
FileUtils = require('../utils/file-utils')
Utils = require('../utils/utils')

load_buildings = (buildings_dir) ->
  new Promise (done, error) ->
    try
      console.log " [OK] loading building configurations from #{buildings_dir}"
      definitions = _.map(FileUtils.parse_to_json(buildings_dir, ['.json'], ['-image.json', '-simulation.json']), STARPEACE.building.BuildingDefinition.fromJson)
      simulation_definitions = _.map(FileUtils.parse_to_json(buildings_dir, ['-simulation.json'], []), STARPEACE.building.simulation.BuildingSimulationDefinitionParser.fromJson)
      console.log " [OK] found #{definitions.length} building definitions"
      console.log " [OK] found #{simulation_definitions.length} simulation definitions\n"

      done({ definitions, simulation_definitions })
    catch err
      error(err)

write_assets = (output_dir) -> (combine_results) ->
  new Promise (done) ->
    write_promises = []

    json = {
      definitions: _.map(combine_results.definitions, (definition) -> definition.toJson())
      simulationDefinitions: _.map(combine_results.simulation_definitions, (definition) -> definition.toJson())
    }

    metadata_file = path.join(output_dir, "metadata-building.json")
    fs.mkdirsSync(path.dirname(metadata_file))
    fs.writeFileSync(metadata_file, if ExportConfiguration.DEBUG_MODE then JSON.stringify(json, null, 2) else JSON.stringify(json))
    console.log "\n [OK] building metadata saved to #{metadata_file}"

    Promise.all(write_promises).then (result) ->
      process.stdout.write '\n'
      done()


class ExportMetadataBuildings
  @export: (assets_dir, target_dir) ->
    buildings_dir = path.join(assets_dir, 'buildings')
    new Promise (done, error) ->
      load_buildings(buildings_dir)
        .then write_assets(target_dir)
        .then done
        .catch error

module.exports = ExportMetadataBuildings

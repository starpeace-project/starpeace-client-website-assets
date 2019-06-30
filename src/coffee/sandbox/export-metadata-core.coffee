
path = require('path')
fs = require('fs-extra')
_ = require('lodash')

STARPEACE = require('@starpeace/starpeace-assets-types')

ExportConfiguration = require('./export-configuration')
FileUtils = require('../utils/file-utils')
Utils = require('../utils/utils')

load_buildings = (assets_dir) ->
  new Promise (done, error) ->
    try
      industry_dir = path.join(assets_dir, 'industry')
      seals_dir = path.join(assets_dir, 'seals')

      console.log " [OK] loading city zones from #{industry_dir}"
      city_zones = _.map(FileUtils.parse_to_json(industry_dir, ['city-zones.json'], []), STARPEACE.industry.CityZone.from_json)
      console.log " [OK] found #{city_zones.length} city zone definitions\n"

      console.log " [OK] loading industry categories from #{industry_dir}"
      industry_categories = _.map(FileUtils.parse_to_json(industry_dir, ['industry-categories.json'], []), STARPEACE.industry.IndustryCategory.from_json)
      console.log " [OK] found #{industry_categories.length} industry category definitions\n"

      console.log " [OK] loading industry types from #{industry_dir}"
      industry_types = _.map(FileUtils.parse_to_json(industry_dir, ['industry-types.json'], []), STARPEACE.industry.IndustryType.from_json)
      console.log " [OK] found #{industry_types.length} industry type definitions\n"

      console.log " [OK] loading levels from #{industry_dir}"
      levels = _.map(FileUtils.parse_to_json(industry_dir, ['levels.json'], []), STARPEACE.industry.Level.from_json)
      console.log " [OK] found #{levels.length} levels definitions\n"

      console.log " [OK] loading resource types from #{industry_dir}"
      resource_types = _.map(FileUtils.parse_to_json(industry_dir, ['resource-types.json'], []), STARPEACE.industry.ResourceType.from_json)
      console.log " [OK] found #{resource_types.length} resource type definitions\n"

      console.log " [OK] loading resource units from #{industry_dir}"
      resource_units = _.map(FileUtils.parse_to_json(industry_dir, ['resource-units.json'], []), STARPEACE.industry.ResourceUnit.from_json)
      console.log " [OK] found #{resource_units.length} resource unit definitions\n"

      console.log " [OK] loading seal configurations from #{seals_dir}"
      seals = _.map(FileUtils.parse_to_json(seals_dir, [], []), STARPEACE.seal.CompanySeal.from_json)
      console.log " [OK] found #{seals.length} seal definitions\n"

      done({ city_zones, industry_categories, industry_types, levels, resource_types, resource_units, seals })
    catch err
      error(err)

write_assets = (output_dir) -> (export_results) ->
  new Promise (done) ->
    write_promises = []

    json = {
      cityZones: _.map(export_results.city_zones, (item) -> item.toJSON())
      industryCategories: _.map(export_results.industry_categories, (item) -> item.toJSON())
      industryTypes: _.map(export_results.industry_types, (item) -> item.toJSON())
      levels: _.map(export_results.levels, (item) -> item.toJSON())
      resourceTypes: _.map(export_results.resource_types, (item) -> item.toJSON())
      resourceUnits: _.map(export_results.resource_units, (item) -> item.toJSON())
      seals: _.map(export_results.seals, (item) -> item.toJSON())
    }

    metadata_file = path.join(output_dir, "metadata-core.json")
    fs.mkdirsSync(path.dirname(metadata_file))
    fs.writeFileSync(metadata_file, if ExportConfiguration.DEBUG_MODE then JSON.stringify(json, null, 2) else JSON.stringify(json))
    console.log "\n [OK] core metadata saved to #{metadata_file}"

    Promise.all(write_promises).then (result) ->
      process.stdout.write '\n'
      done()


class ExportMetadataCore
  @export: (assets_dir, target_dir) ->
    new Promise (done, error) ->
      load_buildings(assets_dir)
        .then write_assets(target_dir)
        .then done
        .catch error

module.exports = ExportMetadataCore


path = require('path')
fs = require('fs-extra')

_ = require('lodash')

FileUtils = require('./utils/file-utils')
Utils = require('./utils/utils')

parameters = require('yargs').argv

export_buildings = parameters.type?.indexOf('b') >= 0
export_inventions = parameters.type?.indexOf('i') >= 0

unless (export_buildings || export_inventions) && process.argv.length >= 4
  console.log "missing options: grunt export --type=[b][i]"
  process.exit(1)

root = process.cwd()
assets_dir = path.join(root, process.argv[2])
target_dir = path.join(root, process.argv[3])

console.log "assets root directory: #{assets_dir}"
console.log "translations root directory: #{target_dir}"
console.log "\n-------------------------------------------------------------------------------\n"

unique_hash = Utils.random_md5()

if export_inventions
  inventions_dir = path.join(assets_dir, 'inventions')
  inventions_output_dir = path.join(target_dir, 'inventions')
  unique_inventions_output_dir = path.join(inventions_output_dir, unique_hash)
  fs.mkdirsSync(unique_inventions_output_dir)

  console.log "exporting invention translations..."
  console.log "invention assets directory: #{inventions_dir}"
  console.log "invention translations directory: #{inventions_output_dir}"

  inventions_json_by_id = {}

  json_file_paths = _.filter(FileUtils.read_all_files_sync(inventions_dir), (file_path) -> file_path.endsWith('.json'))
  for json_path in (json_file_paths || [])
    console.log "attempting to parse #{json_path}"
    inventions_json_by_id[key] = invention for key,invention of JSON.parse(fs.readFileSync(json_path))

  inventions_export_lines = {}
  inventions_export_lines[type] = [] for type in ['DE', 'EN', 'ES', 'FR', 'IT', 'PT']

  all_lines_en = {}
  for id,invention_json of inventions_json_by_id
    if invention_json.name['EN']?.length && !all_lines_en[invention_json.name['EN']]?
      all_lines_en[invention_json.name['EN']] = true
      inventions_export_lines['EN'].push invention_json.name['EN']
      inventions_export_lines[type].push invention_json.name[type] for type in ['DE', 'ES', 'FR', 'IT', 'PT']

    if invention_json.description['EN']?.length && !all_lines_en[invention_json.description['EN']]?
      all_lines_en[invention_json.description['EN']] = true
      inventions_export_lines['EN'].push invention_json.description['EN']
      inventions_export_lines[type].push invention_json.description[type] for type in ['DE', 'ES', 'FR', 'IT', 'PT']

  for type in ['DE', 'EN', 'ES', 'FR', 'IT', 'PT']
    inventions_export_file = path.join(unique_inventions_output_dir, "translations.#{type.toLowerCase()}.txt")
    fs.mkdirsSync(path.dirname(inventions_export_file))
    fs.writeFileSync(inventions_export_file, inventions_export_lines[type].join('\n'))
    console.log inventions_export_file


if export_buildings
  building_asset_dir = path.join(assets_dir, 'buildings')
  building_translation_dir = path.join(target_dir, 'buildings')
  unique_building_translation_dir = path.join(building_translation_dir, unique_hash)
  fs.mkdirsSync(unique_building_translation_dir)

  console.log "exporting building translations..."
  console.log "building assets directory: #{building_asset_dir}"
  console.log "building translations directory: #{building_translation_dir}"

  building_translations = {}

  json_file_paths = _.filter(FileUtils.read_all_files_sync(building_asset_dir), (file_path) -> file_path.endsWith('.json'))
  for json_path in (json_file_paths || [])
    console.log "attempting to parse #{json_path}"
    buildings_data = JSON.parse(fs.readFileSync(json_path))

    for building in buildings_data
      if building.name?
        name_en = building.name.en || building.name.EN
        continue if building_translations[name_en]?
        building_translations[name_en] = {
          'DE': building.name.de || building.name.DE || name_en
          'EN': name_en
          'ES': building.name.es || building.name.ES || name_en
          'FR': building.name.fr || building.name.FR || name_en
          'IT': building.name.it || building.name.IT || name_en
          'PT': building.name.pt || building.name.PT || name_en
        }

  for type in ['DE', 'EN', 'ES', 'FR', 'IT', 'PT']
    buildings_export_file = path.join(unique_building_translation_dir, "translations.#{type.toLowerCase()}.txt")
    fs.mkdirsSync(path.dirname(buildings_export_file))
    fs.writeFileSync(buildings_export_file, _.map(building_translations, (translate) -> translate[type]).join('\n'))
    console.log buildings_export_file

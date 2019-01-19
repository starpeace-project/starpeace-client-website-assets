
path = require('path')
fs = require('fs-extra')

_ = require('lodash')

FileUtils = require('./utils/file-utils')
Utils = require('./utils/utils')


root = process.cwd()
assets_dir = path.join(root, process.argv[2])
target_dir = path.join(root, process.argv[3])

assets_inventions_dir = path.join(assets_dir, 'inventions')
translations_inventions_dir = path.join(target_dir, 'inventions')

console.log "assets directory: #{assets_dir}"
console.log "translations directory: #{target_dir}"
console.log "\n-------------------------------------------------------------------------------\n"

inventions_lines = {}
inventions_lines['DE'] = fs.readFileSync(path.join(translations_inventions_dir, 'translations.de.txt')).toString().split('\n')
inventions_lines['EN'] = fs.readFileSync(path.join(translations_inventions_dir, 'translations.en.txt')).toString().split('\n')
inventions_lines['ES'] = fs.readFileSync(path.join(translations_inventions_dir, 'translations.es.txt')).toString().split('\n')
inventions_lines['FR'] = fs.readFileSync(path.join(translations_inventions_dir, 'translations.fr.txt')).toString().split('\n')
inventions_lines['IT'] = fs.readFileSync(path.join(translations_inventions_dir, 'translations.it.txt')).toString().split('\n')
inventions_lines['PT'] = fs.readFileSync(path.join(translations_inventions_dir, 'translations.pt.txt')).toString().split('\n')

unless inventions_lines['EN'].length == inventions_lines['DE'].length && inventions_lines['EN'].length == inventions_lines['ES'].length &&
      inventions_lines['EN'].length == inventions_lines['FR'].length && inventions_lines['EN'].length == inventions_lines['IT'].length &&
      inventions_lines['EN'].length == inventions_lines['PT'].length
  console.log "missing translations, make sure all translations.txt are complete:"
  console.log "DE: #{inventions_lines['DE'].length}"
  console.log "EN: #{inventions_lines['EN'].length}"
  console.log "ES: #{inventions_lines['ES'].length}"
  console.log "FR: #{inventions_lines['FR'].length}"
  console.log "IT: #{inventions_lines['IT'].length}"
  console.log "PT: #{inventions_lines['PT'].length}"
  process.exit(1)

language_values = {}
for line in [0..inventions_lines['EN'].length]
  en_value = inventions_lines['EN'][line]
  continue unless en_value?.length
  language_values[en_value] = {
    'DE': inventions_lines['DE'][line]
    'ES': inventions_lines['ES'][line]
    'FR': inventions_lines['FR'][line]
    'IT': inventions_lines['IT'][line]
    'PT': inventions_lines['PT'][line]
  }

json_file_paths = _.filter(FileUtils.read_all_files_sync(assets_inventions_dir), (file_path) -> file_path.endsWith('.json'))
for json_path in (json_file_paths || [])
  console.log "attempting to parse #{json_path}"

  output_json = {}
  for key,invention_json of JSON.parse(fs.readFileSync(json_path))
    if invention_json.name['EN']?.length
      name_values = language_values[invention_json.name['EN']]
      if name_values?
        invention_json.name = {
          'DE': name_values['DE'] || invention_json.name['DE'] || invention_json.name['EN']
          'EN': invention_json.name['EN']
          'ES': name_values['ES'] || invention_json.name['ES'] || invention_json.name['EN']
          'FR': name_values['FR'] || invention_json.name['FR'] || invention_json.name['EN']
          'IT': name_values['IT'] || invention_json.name['IT'] || invention_json.name['EN']
          'PT': name_values['PT'] || invention_json.name['PT'] || invention_json.name['EN']
        }
      else
        console.log "missing translations for name '#{invention_json.name['EN']}'"

    if invention_json.description['EN']?.length
      description_values = language_values[invention_json.description['EN']]
      if description_values?
        invention_json.description = {
          'DE': description_values['DE'] || invention_json.description['DE'] || invention_json.description['EN']
          'EN': invention_json.description['EN']
          'ES': description_values['ES'] || invention_json.description['ES'] || invention_json.description['EN']
          'FR': description_values['FR'] || invention_json.description['FR'] || invention_json.description['EN']
          'IT': description_values['IT'] || invention_json.description['IT'] || invention_json.description['EN']
          'PT': description_values['PT'] || invention_json.description['PT'] || invention_json.description['EN']
        }
      else
        console.log "missing translations for description '#{invention_json.description['EN']}'"

    output_json[key] = invention_json

  fs.writeFileSync(json_path, JSON.stringify(output_json, null, 2))

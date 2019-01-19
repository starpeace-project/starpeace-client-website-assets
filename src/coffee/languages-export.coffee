
path = require('path')
fs = require('fs-extra')

_ = require('lodash')

FileUtils = require('./utils/file-utils')
Utils = require('./utils/utils')


root = process.cwd()
assets_dir = path.join(root, process.argv[2])
target_dir = path.join(root, process.argv[3])

unique_hash = Utils.random_md5()

inventions_dir = path.join(assets_dir, 'inventions')
inventions_output_dir = path.join(target_dir, 'inventions')
unique_inventions_output_dir = path.join(inventions_output_dir, unique_hash)

fs.mkdirsSync(unique_inventions_output_dir)

console.log "input directory: #{assets_dir}"
console.log "output directory: #{target_dir}"
console.log "\n-------------------------------------------------------------------------------\n"

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

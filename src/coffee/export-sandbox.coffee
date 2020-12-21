_ = require('lodash')
path = require('path')
fs = require('fs-extra')

ExportMetadataBuildings = require('./sandbox/export-metadata-buildings')
ExportMetadataInventions = require('./sandbox/export-metadata-inventions')

Utils = require('./utils/utils')


console.log "\n===============================================================================\n"
console.log " export-sandbox.js - https://www.starpeace.io\n"
console.log " export default game configurations for use with game client sandbox\n"
console.log " see README.md for more details"
console.log "\n===============================================================================\n"


root = process.cwd()
assets_dir = path.join(root, process.argv[2])
target_dir = path.join(root, process.argv[3])

fs.mkdirsSync(target_dir)

console.log "input directory: #{assets_dir}"
console.log "output directory: #{target_dir}"

console.log "\n-------------------------------------------------------------------------------\n"

jobs = []
jobs.push(ExportMetadataBuildings.export(assets_dir, target_dir))
jobs.push(ExportMetadataInventions.export(assets_dir, target_dir))

Promise.all(jobs)
  .then ->
    console.log "\nfinished successfully, thank you for using export-sandbox.js!"

  .catch (error) ->
    console.log "there was an error during execution:"
    console.log error
    process.exit(1)

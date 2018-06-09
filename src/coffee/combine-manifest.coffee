
path = require('path')
fs = require('fs-extra')

_ = require('lodash')
Jimp = require('jimp')
sharp = require('sharp')

CombineLandManifest = require('./combine/combine-land-manifest')
CombineMapManifest = require('./combine/combine-map-manifest')


console.log "\n===============================================================================\n"
console.log " combine-manifest.js - https://www.starpeace.io\n"
console.log " combine game textures and generate summary metadata for use with game client\n"
console.log " see README.md for more details"
console.log "\n===============================================================================\n"


root = process.cwd()
source_dir = path.join(root, process.argv[2])
target_dir = path.join(root, process.argv[3])

console.log "input directory: #{source_dir}"
console.log "output directory: #{target_dir}"

console.log "\n-------------------------------------------------------------------------------\n"

land_dir = path.join(source_dir, 'land')
maps_dir = path.join(source_dir, 'maps')

Promise.all([
  CombineLandManifest.combine(land_dir, target_dir),
  CombineMapManifest.combine(maps_dir, target_dir)
])
  .then(() ->
    console.log "\nfinished successfully, thank you for using combine-manifest.js!"
  )
  .catch((error) ->
    console.log "there was an error during execution:"
    console.log error
  )


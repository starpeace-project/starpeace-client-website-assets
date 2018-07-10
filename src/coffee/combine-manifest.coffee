
path = require('path')
fs = require('fs-extra')

_ = require('lodash')
Jimp = require('jimp')
sharp = require('sharp')

CombineLandManifest = require('./combine/combine-land-manifest')
CombineMapManifest = require('./combine/combine-map-manifest')
CombineStaticNews = require('./combine/combine-static-news')
CombineBuildingManifest = require('./combine/combine-building-manifest')
CombinePlaneManifest = require('./combine/combine-plane-manifest')

SKIP_LAND = false
SKIP_MAPS = false
SKIP_NEWS = false
SKIP_BUILDINGS = false
SKIP_PLANES = false

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

image_dir = path.join(source_dir, 'images')
land_dir = path.join(image_dir, 'land')
maps_dir = path.join(image_dir, 'maps')
news_dir = path.join(source_dir, 'news')
buildings_dir = path.join(image_dir, 'buildings')
planes_dir = path.join(image_dir, 'planes')

jobs = []
jobs.push(CombineLandManifest.combine(land_dir, target_dir)) unless SKIP_LAND
jobs.push(CombineMapManifest.combine(maps_dir, target_dir)) unless SKIP_MAPS
jobs.push(CombineStaticNews.combine(news_dir, target_dir)) unless SKIP_NEWS
jobs.push(CombineBuildingManifest.combine(buildings_dir, target_dir)) unless SKIP_BUILDINGS
jobs.push(CombinePlaneManifest.combine(planes_dir, target_dir)) unless SKIP_PLANES

Promise.all(jobs)
  .then(() ->
    console.log "\nfinished successfully, thank you for using combine-manifest.js!"
  )
  .catch((error) ->
    console.log "there was an error during execution:"
    console.log error
  )

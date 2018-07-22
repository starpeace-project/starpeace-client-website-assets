
path = require('path')
fs = require('fs-extra')

_ = require('lodash')
Jimp = require('jimp')
sharp = require('sharp')

CombineBuildingManifest = require('./combine/combine-building-manifest')
CombineConcreteManifest = require('./combine/combine-concrete-manifest')
CombineEffectManifest = require('./combine/combine-effect-manifest')
CombineLandManifest = require('./combine/combine-land-manifest')
CombineMapManifest = require('./combine/combine-map-manifest')
CombineOverlayManifest = require('./combine/combine-overlay-manifest')
CombinePlaneManifest = require('./combine/combine-plane-manifest')
CombineRoadManifest = require('./combine/combine-road-manifest')
CombineStaticNews = require('./combine/combine-static-news')

SKIP_BUILDINGS = false
SKIP_CONCRETE = false
SKIP_EFFECTS = false
SKIP_LAND = false
SKIP_MAPS = false
SKIP_NEWS = false
SKIP_OVERLAYS = false
SKIP_PLANES = false
SKIP_ROADS = false

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
buildings_dir = path.join(image_dir, 'buildings')
concrete_dir = path.join(image_dir, 'concrete')
effects_dir = path.join(image_dir, 'effects')
land_dir = path.join(image_dir, 'land')
maps_dir = path.join(image_dir, 'maps')
news_dir = path.join(source_dir, 'news')
overlays_dir = path.join(image_dir, 'overlays')
planes_dir = path.join(image_dir, 'planes')
roads_dir = path.join(image_dir, 'roads')

jobs = []
jobs.push(CombineBuildingManifest.combine(buildings_dir, target_dir)) unless SKIP_BUILDINGS
jobs.push(CombineConcreteManifest.combine(concrete_dir, target_dir)) unless SKIP_CONCRETE
jobs.push(CombineEffectManifest.combine(effects_dir, target_dir)) unless SKIP_EFFECTS
jobs.push(CombineLandManifest.combine(land_dir, target_dir)) unless SKIP_LAND
jobs.push(CombineMapManifest.combine(maps_dir, target_dir)) unless SKIP_MAPS
jobs.push(CombineOverlayManifest.combine(overlays_dir, target_dir)) unless SKIP_OVERLAYS
jobs.push(CombinePlaneManifest.combine(planes_dir, target_dir)) unless SKIP_PLANES
jobs.push(CombineRoadManifest.combine(roads_dir, target_dir)) unless SKIP_ROADS
jobs.push(CombineStaticNews.combine(news_dir, target_dir)) unless SKIP_NEWS

Promise.all(jobs)
  .then(() ->
    console.log "\nfinished successfully, thank you for using combine-manifest.js!"
  )
  .catch((error) ->
    console.log "there was an error during execution:"
    console.log error
  )

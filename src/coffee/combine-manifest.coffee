
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
CombineStaticMusic = require('./combine/combine-static-music')
CombineStaticNews = require('./combine/combine-static-news')

Utils = require('./utils/utils')

SKIP_BUILDINGS = false
SKIP_CONCRETE = false
SKIP_EFFECTS = false
SKIP_LAND = false
SKIP_MAPS = false
SKIP_MUSIC = false
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

unique_hash = Utils.random_md5()
target_with_version = path.join(target_dir, unique_hash)

fs.mkdirsSync(target_with_version)

console.log "input directory: #{source_dir}"
console.log "output directory: #{target_dir}"

console.log "\n-------------------------------------------------------------------------------\n"

image_dir = path.join(source_dir, 'images')
sound_dir = path.join(source_dir, 'sounds')

buildings_dir = path.join(image_dir, 'buildings')
concrete_dir = path.join(image_dir, 'concrete')
effects_dir = path.join(image_dir, 'effects')
land_dir = path.join(image_dir, 'land')
maps_dir = path.join(image_dir, 'maps')
music_dir = path.join(sound_dir, 'music')
news_dir = path.join(source_dir, 'news')
overlays_dir = path.join(image_dir, 'overlays')
planes_dir = path.join(image_dir, 'planes')
roads_dir = path.join(image_dir, 'roads')

jobs = []
jobs.push(CombineBuildingManifest.combine(buildings_dir, target_with_version)) unless SKIP_BUILDINGS
jobs.push(CombineConcreteManifest.combine(concrete_dir, target_with_version)) unless SKIP_CONCRETE
jobs.push(CombineEffectManifest.combine(effects_dir, target_with_version)) unless SKIP_EFFECTS
jobs.push(CombineLandManifest.combine(land_dir, target_with_version)) unless SKIP_LAND
jobs.push(CombineMapManifest.combine(maps_dir, target_with_version)) unless SKIP_MAPS
jobs.push(CombineOverlayManifest.combine(overlays_dir, target_with_version)) unless SKIP_OVERLAYS
jobs.push(CombinePlaneManifest.combine(planes_dir, target_with_version)) unless SKIP_PLANES
jobs.push(CombineRoadManifest.combine(roads_dir, target_with_version)) unless SKIP_ROADS
jobs.push(CombineStaticMusic.combine(music_dir, target_with_version)) unless SKIP_MUSIC
jobs.push(CombineStaticNews.combine(news_dir, target_with_version)) unless SKIP_NEWS

Promise.all(jobs)
  .then(() ->
    console.log "\nfinished successfully, thank you for using combine-manifest.js!"
  )
  .catch((error) ->
    console.log "there was an error during execution:"
    console.log error
  )

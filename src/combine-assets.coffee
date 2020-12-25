_ = require('lodash')
path = require('path')
fs = require('fs-extra')

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
CombineSignManifest = require('./combine/combine-sign-manifest')

GeneratePlanetAnimations = require('./planet/generate-planet-animations')

Utils = require('./utils/utils')

SKIP = {
  # BUILDINGS: true
  # CONCRETE: true
  # EFFECTS: true
  # LAND: true
  # MAPS: true
  # MUSIC: true
  # NEWS: true
  # OVERLAYS: true
  # PLANES: true
  # ROADS: true
  # SIGNS: true
  # PLANET_ANIMATIONS: true
}


console.log "\n===============================================================================\n"
console.log " combine-assets.js - https://www.starpeace.io\n"
console.log " combine game textures and generate summary metadata for use with game client\n"
console.log " see README.md for more details"
console.log "\n===============================================================================\n"


root = process.cwd()
source_dir = path.join(root, process.argv[2])
assets_dir = path.join(root, process.argv[3])
target_dir = path.join(root, process.argv[4])

unique_hash = Utils.random_md5()
target_with_version = path.join(target_dir, unique_hash)

fs.mkdirsSync(target_with_version)

console.log "input directory: #{assets_dir}"
console.log "output directory: #{target_dir}"

console.log "\n-------------------------------------------------------------------------------\n"

sound_dir = path.join(assets_dir, 'sounds')

concrete_dir = path.join(assets_dir, 'concrete')
effects_dir = path.join(assets_dir, 'effects')
land_dir = path.join(assets_dir, 'land')
maps_dir = path.join(assets_dir, 'maps')
music_dir = path.join(sound_dir, 'music')
news_dir = path.join(assets_dir, 'news')
overlays_dir = path.join(assets_dir, 'overlays')
planes_dir = path.join(assets_dir, 'planes')
roads_dir = path.join(assets_dir, 'roads')
signs_dir = path.join(assets_dir, 'signs')

jobs = []
jobs.push(CombineBuildingManifest.combine(assets_dir, target_with_version)) unless SKIP.BUILDINGS
jobs.push(CombineConcreteManifest.combine(concrete_dir, target_with_version)) unless SKIP.CONCRETE
jobs.push(CombineEffectManifest.combine(effects_dir, target_with_version)) unless SKIP.EFFECTS
jobs.push(CombineLandManifest.combine(land_dir, target_with_version)) unless SKIP.LAND
jobs.push(CombineMapManifest.combine(maps_dir, target_with_version)) unless SKIP.MAPS
jobs.push(CombineStaticMusic.combine(music_dir, target_with_version)) unless SKIP.MUSIC
jobs.push(CombineStaticNews.combine(news_dir, target_with_version)) unless SKIP.NEWS
jobs.push(CombineOverlayManifest.combine(overlays_dir, target_with_version)) unless SKIP.OVERLAYS
jobs.push(CombinePlaneManifest.combine(planes_dir, target_with_version)) unless SKIP.PLANES
jobs.push(CombineRoadManifest.combine(roads_dir, target_with_version)) unless SKIP.ROADS
jobs.push(CombineSignManifest.combine(signs_dir, target_with_version)) unless SKIP.SIGNS

Promise.all(jobs)
  .then -> if SKIP.PLANET_ANIMATIONS then Promise.resolve(true) else GeneratePlanetAnimations.combine(source_dir, maps_dir, target_with_version)
  .then ->
    console.log "\nfinished successfully, thank you for using combine-assets.js!"

  .catch (error) ->
    console.log "there was an error during execution:"
    console.log error
    process.exit(1)

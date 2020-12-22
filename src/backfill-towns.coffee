_ = require('lodash')
path = require('path')
fs = require('fs-extra')

Jimp = require('jimp')

FileUtils = require('./utils/file-utils')
Utils = require('./utils/utils')


load_configurations = (maps_dir) ->
  planets = []
  for file_path in FileUtils.read_all_files_sync(maps_dir, (file_path) -> file_path.endsWith('.json')).sort()
    mapId = _.replace(path.basename(file_path), '.json', '')

    boundaries_image = await Jimp.read(path.join(maps_dir, "#{mapId}.towns.bmp"))
    planets.push {
      id: mapId
      bitmap: boundaries_image.bitmap
      towns: JSON.parse(fs.readFileSync(file_path)).towns
    }
  planets

backfill_boundaries = (target_dir) -> (planet_configs) ->
  match_colors = true
  for planet in planet_configs
    pixels = planet.bitmap.data
    colors = new Set()
    for y in [0...planet.bitmap.height]
      for x in [0...planet.bitmap.width]
        pixel_index = (y * planet.bitmap.width + x) * 4
        color = ((pixels[pixel_index + 0] << 16) & 0xFF0000) | ((pixels[pixel_index + 1] << 8) & 0x00FF00) | ((pixels[pixel_index + 2] << 0) & 0x0000FF)
        colors.add(color)

    color_towns = {}
    for town in planet.towns
      pixel_index = (town.mapY * planet.bitmap.width + town.mapX) * 4
      color = ((pixels[pixel_index + 0] << 16) & 0xFF0000) | ((pixels[pixel_index + 1] << 8) & 0x00FF00) | ((pixels[pixel_index + 2] << 0) & 0x0000FF)
      color_hex = color.toString(16)
      color_towns[color_hex] = [] unless color_towns[color_hex]?
      color_towns[color_hex].push(town.name)
      town.color = color

      # if planet.id == 'taramoc'
      #   img = new Jimp(planet.bitmap.width, planet.bitmap.height)
      #   img.setPixelColor(0xFFFFFF, town.mapX, town.mapY) for town in planet.towns
      #   img.write('towns.png')

    if planet.towns.length == colors.size && colors.size == Object.keys(color_towns).length
      console.log "planet map #{planet.id} matches towns and colors"

    else
      match_colors = false
      console.log "planet map #{planet.id} has #{planet.towns.length} towns, #{colors.size} total colors, and #{Object.keys(color_towns).length} unique town colors"
      console.log _.map(Array.from(colors).sort(), (v) -> v.toString(16))
      console.log color_towns

      if colors.size > Object.keys(color_towns).length
        console.log "not using colors: #{_.difference(_.map(Array.from(colors).sort(), (v) -> v.toString(16)), Object.keys(color_towns))}"


  if match_colors
    console.log "all colors match, should write out"

    fs.mkdirsSync(target_dir)
    for planet in planet_configs
      fs.writeFileSync(path.join(target_dir, "#{planet.id}.json"), JSON.stringify({ towns: planet.towns }, null, 2))
      console.log "write #{path.join(target_dir, "#{planet.id}.json")}"

console.log "\n===============================================================================\n"
console.log " backfill-towns.js - https://www.starpeace.io\n"
console.log " backfill town configurations from bountry textures\n"
console.log " see README.md for more details"
console.log "\n===============================================================================\n"


root = process.cwd()
assets_dir = path.join(root, process.argv[2])
target_dir = path.join(root, process.argv[3])

fs.mkdirsSync(target_dir)

console.log "input directory: #{assets_dir}"
console.log "output directory: #{target_dir}"

console.log "\n-------------------------------------------------------------------------------\n"

maps_dir = path.join(assets_dir, 'maps')

load_configurations(maps_dir)
  .then backfill_boundaries(target_dir)
  .then ->
    console.log "\nfinished successfully, thank you for using backfill-towns.js!"

  .catch (error) ->
    console.log "there was an error during execution:"
    console.log error
    process.exit(1)

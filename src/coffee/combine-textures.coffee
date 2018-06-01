
path = require('path')
fs = require('fs-extra')

_ = require('lodash')
Jimp = require('jimp')
readlineSync = require('readline-sync')
rbp = require('rectangle-bin-pack')

LandManifest = require('./land/land-manifest')
MapImage = require('./maps/map-image')

Utils = require('./utils/utils')

TEXTURE_WIDTH = 2048
TEXTURE_HEIGHT = 2048

# FIXME: TODO: add other planets
PLANETS = new Set(['earth'])
# FIXME: TODO: add other orientations
ORIENTATIONS = new Set(['0deg'])


aggregate_textures_by_planet = (land_manifest) ->
  new Promise (done) ->
    planet_tile_images = {}
    planet_textures_to_pack = {}

    for tile in land_manifest.metadata_tiles
      for orientation in Object.keys(tile.image_keys)
        continue unless ORIENTATIONS.has(orientation)
        image_key = tile.image_keys[orientation]
        for image in (land_manifest.image_key_images[image_key.safe_image_key()] || [])
          planet = image.planet()
          continue unless PLANETS.has(planet)
          season = image.season()

          data_to_pack = {
            id: tile.id
            tile: tile
            image: image
            w: image.image.bitmap.width
            h: image.image.bitmap.height
          }

          planet_tile_images[planet] = {} unless planet_tile_images[planet]?
          planet_tile_images[planet][orientation] = {} unless planet_tile_images[planet][orientation]?
          planet_tile_images[planet][orientation][season] = {} unless planet_tile_images[planet][orientation][season]?
          planet_tile_images[planet][orientation][season][tile.id] = data_to_pack

          planet_textures_to_pack[planet] = [] unless planet_textures_to_pack[planet]?
          planet_textures_to_pack[planet].push data_to_pack

    console.log "found and aggregated #{Object.keys(planet_textures_to_pack).length} planets"
    for planet,textures of planet_textures_to_pack
      console.log "found and aggregated #{textures.length} land images for planet #{planet}"

    process.stdout.write '\n'
    done([land_manifest, planet_tile_images, planet_textures_to_pack])

determine_planet_textures_packing = ([land_manifest, planet_tile_images, planet_textures_to_pack]) ->
  new Promise (done) ->
    planet_texture_groups = {}
    for planet in Object.keys(planet_textures_to_pack)
      planet_texture_groups[planet] = [] unless planet_texture_groups[planet]?
      to_pack = planet_textures_to_pack[planet]

      while to_pack.length
        rbp.solveSync({w: TEXTURE_WIDTH, h: TEXTURE_HEIGHT}, to_pack)
        packed_until = _.findIndex(to_pack, (texture) -> !texture.x? || !texture.y?)
        packed_until = to_pack.length if packed_until < 0
        planet_texture_groups[planet].push to_pack.slice(0, packed_until)
        to_pack = to_pack.slice(packed_until)

      console.log "land images for planet #{planet} can be combined into #{planet_texture_groups[planet].length} textures"

    process.stdout.write '\n'
    done([land_manifest, planet_tile_images, planet_texture_groups])

pack_planet_textures = ([land_manifest, planet_tile_images, planet_texture_groups]) ->
  new Promise (done) ->
    planet_textures = {}
    for planet in Object.keys(planet_texture_groups)
      planet_textures[planet] = [] unless planet_textures[planet]?

      for group in planet_texture_groups[planet]
        image = new Jimp(TEXTURE_WIDTH, TEXTURE_HEIGHT)

        for tile_image in group
          tile_image.texture_index = planet_textures[planet].length

          tile_image.image.image.scan(0, 0, tile_image.image.image.bitmap.width, tile_image.image.image.bitmap.height, (x, y, idx) ->
            red = this.bitmap.data[idx + 2] # red and blue are flipped?
            green = this.bitmap.data[idx + 1]
            blue  = this.bitmap.data[idx + 0] # red and blue are flipped?
            alpha = this.bitmap.data[idx + 3]
            return if red == 0 && green == 0 && blue == 255

            image.setPixelColor(Jimp.rgbaToInt(red, green, blue, alpha), x + tile_image.x, y + tile_image.y)
          )

        planet_textures[planet].push image

    done([land_manifest, planet_tile_images, planet_textures])

write_planet_texture_images = (output_dir) -> ([land_manifest, planet_tile_images, planet_textures]) ->
  new Promise (done) ->
    write_promises = []
    planet_texture_index_file = {}
    for planet,textures of planet_textures
      planet_texture_index_file[planet] = {} unless planet_texture_index_file[planet]?
      for texture,index in textures
        planet_texture_index_file[planet][index] = "#{planet}.texture.land.#{index}.png"
        texture_file = path.join(output_dir, planet_texture_index_file[planet][index])

        console.log "land texture for planet #{planet} saved to #{texture_file}"
        write_promises.push texture.write(texture_file)

    Promise.all(write_promises).then (result) ->
      process.stdout.write '\n'
      done([land_manifest, planet_tile_images, planet_texture_index_file])

write_planet_texture_metadata = (output_dir) -> ([land_manifest, planet_tile_images, planet_texture_index_file]) ->
  new Promise (done) ->
    write_promises = []
    for planet,images of planet_tile_images
      json = {
        planet: planet
        texture_land_images: _.values(planet_texture_index_file[planet])
        definitions: {}
        orientations: {}
      }

      for tile in land_manifest.metadata_tiles
        json.definitions[tile.id] = {
          id: tile.id
          map_color: tile.map_color
          zone: tile.key.zone
          variant: tile.key.variant
        }

      for orientation,tiles of planet_tile_images[planet]
        json.orientations[orientation] = {}
        for season,season_tiles of tiles
          json.orientations[orientation][season] = {} unless json.orientations[orientation][season]?
          for tile_id,tile_data of season_tiles
            json.orientations[orientation][season][tile_data.id] = {
              id: tile_id
              type: tile_data.tile.key.type
              w: tile_data.w
              h: tile_data.h
              x: tile_data.x
              y: tile_data.y
              texture_land_image: planet_texture_index_file[planet][tile_data.texture_index]
            }

      metadata_file = path.join(output_dir, "#{planet}.metadata.land.json")
      write_promises.push new Promise (write_done) -> fs.writeFile(metadata_file, JSON.stringify(json), (error, value) -> write_done([planet, metadata_file]))

    Promise.all(write_promises).then (result_paths) ->
      console.log "land metadata for planet #{planet} saved to #{file_path}" for [planet, file_path] in result_paths
      process.stdout.write '\n'
      done(land_manifest)

write_map_images = (output_dir) -> (map_images) ->
  new Promise (done) ->
    write_promises = []
    for image in map_images
      converted_image = new Jimp(image.image.bitmap.width, image.image.bitmap.height)
      image.image.scan(0, 0, image.image.bitmap.width, image.image.bitmap.height, (x, y, idx) ->
        red = this.bitmap.data[idx + 2] # red and blue are flipped?
        green = this.bitmap.data[idx + 1]
        blue  = this.bitmap.data[idx + 0] # red and blue are flipped?
        alpha = this.bitmap.data[idx + 3]
        return if red == 0 && green == 0 && blue == 255

        converted_image.setPixelColor(Jimp.rgbaToInt(red, green, blue, alpha), x, y)
      )

      texture_file = path.join(output_dir, "#{image.name.toLowerCase()}.texture.map.png")
      console.log "map texture for planet #{image.name} saved to #{texture_file}"
      write_promises.push converted_image.write(texture_file)

    Promise.all(write_promises).then (result) ->
      process.stdout.write '\n'
      done([map_images])


combine_land = (land, target_dir) ->
  new Promise (done) ->
    LandManifest.load(land_dir)
      .then(aggregate_textures_by_planet)
      .then(determine_planet_textures_packing)
      .then(pack_planet_textures)
      .then(write_planet_texture_images(target_dir))
      .then(write_planet_texture_metadata(target_dir))
      .then(done)

combine_maps = (maps_dir, target_dir) -> (land_manifest) ->
  new Promise (done) ->
    MapImage.load(maps_dir)
      .then(write_map_images(target_dir))
      .then(done)


console.log "\n===============================================================================\n"
console.log " combine-textures.js - https://www.starpeace.io\n"
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

combine_land(land_dir, target_dir)
  .then(combine_maps(maps_dir, target_dir))
  .then(() ->
    console.log "\nfinished successfully, thank you for using combine-textures.js!"
  )
  .catch((error) ->
    console.log "there was an error during execution:"
    console.log error
  )


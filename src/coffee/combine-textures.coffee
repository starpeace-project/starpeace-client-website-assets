
path = require('path')
fs = require('fs-extra')

_ = require('lodash')
Jimp = require('jimp')
sharp = require('sharp')

LandMetadataManifest = require('./land/metadata/land-metadata-manifest')
LandTextureManifest = require('./land/texture/land-texture-manifest')
LandSpritesheet = require('./land/texture/land-spritesheet')

MapImage = require('./maps/map-image')

Utils = require('./utils/utils')

DEBUG_MODE = false

TEXTURE_WIDTH = 2048
TEXTURE_HEIGHT = 2048

# FIXME: TODO: add other planets
PLANETS = new Set(['earth'])
# FIXME: TODO: add other orientations
ORIENTATIONS = new Set(['0deg'])


aggregate_by_planet = ([metadata_manifest, texture_manifest]) ->
  new Promise (done, error) ->
    metadata_by_planet = {}
    textures_by_planet = {}

    for tile in metadata_manifest.all_tiles
      metadata_by_planet[tile.planet_type] ||= []
      metadata_by_planet[tile.planet_type].push tile

    for texture in texture_manifest.all_textures
      textures_by_planet[texture.planet_type] ||= []
      textures_by_planet[texture.planet_type].push texture

    metadata_planet_keys = Object.keys(metadata_by_planet)
    texture_planet_keys = Object.keys(textures_by_planet)
    error("metadata and textures planets different: #{metadata_planet_keys} vs #{texture_planet_keys}") unless _.intersection(metadata_planet_keys, texture_planet_keys).length == metadata_planet_keys.length

    console.log "found #{Object.keys(metadata_by_planet).length} planets: #{metadata_planet_keys}\n"
    done([metadata_by_planet, textures_by_planet])

pack_planet_textures = ([metadata_by_planet, textures_by_planet]) ->
  new Promise (done) ->
    compiled_metadata_by_planet = {}
    spritesheets_by_planet = {}
    for planet_type,textures of textures_by_planet
      compiled_metadata_by_planet[planet_type] = {}
      texture_key_seasons = {}
      for texture in textures
        texture_key = texture.key()
        texture_key_seasons[texture_key] ||= {}
        texture_key_seasons[texture_key][texture.season] = texture

      metadata_texture_keys = new Set()
      for tile in metadata_by_planet[planet_type]
        for orientation,type_texture_key of tile.textures_by_orientation_type
          continue unless ORIENTATIONS.has(orientation)
          compiled_metadata = compiled_metadata_by_planet[planet_type][tile.key()] = tile.to_compiled_json()

          for season in Object.keys(texture_key_seasons[type_texture_key.key] || {})
            if tile.seasons.has(season)
              spritesheet_key = texture_key_seasons[type_texture_key.key][season].key_for_spritesheet()
              compiled_metadata.textures ||= {}
              compiled_metadata.textures[orientation] ||= {}
              compiled_metadata.textures[orientation][season] ||= {}
              compiled_metadata.textures[orientation][season][type_texture_key.type] = spritesheet_key
              metadata_texture_keys.add spritesheet_key

      spritesheets_by_planet[planet_type] = LandSpritesheet.pack_textures(planet_type, textures, metadata_texture_keys)

    done([compiled_metadata_by_planet, spritesheets_by_planet])

write_planet_assets = (output_dir) -> ([compiled_metadata_by_planet, spritesheets_by_planet]) ->
  new Promise (done) ->
    write_promises = []

    planet_atlas_names = {}
    for planet_type,spritesheets of spritesheets_by_planet
      planet_atlas_names[planet_type] = []
      for spritesheet in spritesheets
        texture_name = spritesheet.texture_file_name()
        texture_file = path.join(output_dir, texture_name)
        fs.mkdirsSync(path.dirname(texture_file))
        console.log "land texture for planet #{planet_type} saved to #{texture_file}"
        write_promises.push spritesheet.render_to_texture().write(texture_file)

        json = {
          meta: {
            image: "./#{texture_name}"
          }
          frames: spritesheet.data_json()
        }

        atlas_name = spritesheet.atlas_file_name()
        planet_atlas_names[planet_type].push "./#{atlas_name}"
        spritesheet_atlas = path.join(output_dir, atlas_name)
        fs.mkdirsSync(path.dirname(spritesheet_atlas))
        fs.writeFileSync(spritesheet_atlas, if DEBUG_MODE then JSON.stringify(json, null, 2) else JSON.stringify(json))
        console.log "land spritesheet atlas for planet #{planet_type} saved to #{spritesheet_atlas}"

    for planet_type,compiled_metadata of compiled_metadata_by_planet
      json = {
        planet_type: planet_type
        atlas: planet_atlas_names[planet_type]
        metadata: compiled_metadata
      }

      metadata_file = path.join(output_dir, "land.#{planet_type}.metadata.json")
      fs.mkdirsSync(path.dirname(metadata_file))
      fs.writeFileSync(metadata_file, if DEBUG_MODE then JSON.stringify(json, null, 2) else JSON.stringify(json))
      console.log "land metadata for planet #{planet_type} saved to #{metadata_file}"

    Promise.all(write_promises).then (result) ->
      process.stdout.write '\n'
      done([compiled_metadata_by_planet, planet_atlas_names])


write_map_images = (output_dir) -> (map_images) ->
  new Promise (done) ->
    write_promises = []
    for image in map_images
      write_promises.push new Promise (write_done, write_error) ->
        do (image) ->
          sharp(Buffer.from(image.image.bitmap.data), {
            raw: {
              width: image.image.bitmap.width
              height: image.image.bitmap.height
              channels: 4
            }
          })
          .resize(1024, 1024)
          .toBuffer()
          .then (buffer) ->
            for index in [0...(buffer.length / 4)]
              b = buffer[index * 4 + 0]
              buffer[index * 4 + 0] = buffer[index * 4 + 2]
              buffer[index * 4 + 2] = b
              true
    
            output_file_path = path.join(output_dir, "map.#{image.name.toLowerCase()}.texture.png")
            sharp(buffer, {
              raw: {
                width: 1024
                height: 1024
                channels: 4
              }
            })
            .toFile(output_file_path, (err, info) ->
              console.log "map saved to #{output_file_path}"
              write_done(info)
            )

    Promise.all(write_promises).then (result) ->
      done([result])


load_land_manifest = (land_dir) ->
  new Promise (done, error) ->
    Promise.all([LandMetadataManifest.load(land_dir), LandTextureManifest.load(land_dir)])
      .then done
      .catch error

combine_land = (target_dir) -> ([metadata_manifest, texture_manifest]) ->
  new Promise (done, error) ->
    aggregate_by_planet([metadata_manifest, texture_manifest])
      .then(pack_planet_textures)
      .then(write_planet_assets(target_dir))
      .then(done)
      .catch error

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

load_land_manifest(land_dir)
  .then(combine_land(target_dir))
  .then(combine_maps(maps_dir, target_dir))
  .then(() ->
    console.log "\nfinished successfully, thank you for using combine-textures.js!"
  )
  .catch((error) ->
    console.log "there was an error during execution:"
    console.log error
  )


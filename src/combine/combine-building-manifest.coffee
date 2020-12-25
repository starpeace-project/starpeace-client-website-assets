_ = require('lodash')
path = require('path')
fs = require('fs-extra')

STARPEACE = require('@starpeace/starpeace-assets-types')

BuildingTexture = require('../building/building-texture')
Spritesheet = require('../common/spritesheet')

ConsoleProgressUpdater = require('../utils/console-progress-updater')
FileUtils = require('../utils/file-utils')
Utils = require('../utils/utils')

DEBUG_MODE = false

TILE_WIDTH = 64
TILE_HEIGHT = 32

OUTPUT_TEXTURE_WIDTH = 2048
OUTPUT_TEXTURE_HEIGHT = 2048

load_buildings = (buildings_dir, seals_dir) ->
  new Promise (done, error) ->
    try
      console.log " [OK] loading building configurations from #{buildings_dir}"
      image_definitions = _.map(FileUtils.parse_to_json(buildings_dir, ['-image.json'], []), STARPEACE.building.BuildingImageDefinition.fromJson)
      console.log " [OK] found #{image_definitions.length} image definitions"

      done({ image_definitions })
    catch err
      error(err)

load_building_textures = (root_assets_dir) -> (combine_results) ->
  new Promise (done, error) ->
    try
      image_paths = _.map(combine_results.image_definitions, 'imagePath')
      console.log " [OK] loading #{image_paths.length} building textures from #{root_assets_dir}\n"
      Utils.load_and_group_animation(root_assets_dir, image_paths, true)
        .then (frame_groups) ->
          progress = new ConsoleProgressUpdater(frame_groups.length)
          _.map(_.zip(image_paths, frame_groups), (pair) ->
            image = new BuildingTexture(pair[0], pair[1])
            progress.next()
            image
          )
        .then (textures) ->
          combine_results.textures_by_path = {}
          combine_results.textures_by_path[texture.file_path] = texture for texture in textures

          if textures.length != image_paths.length
            console.log " [ERROR] loaded #{textures.length} building textures but expected #{image_paths.length}\n"
            throw "loaded fewer building textures than expected"

          console.log " [OK] loaded #{textures.length} building textures\n"
          done(combine_results)
        .catch error
    catch err
      error(err)


aggregate = (combine_results) ->
  new Promise (done, error) ->

    frame_texture_groups = []
    for building_image in combine_results.image_definitions
      image = combine_results.textures_by_path[building_image.imagePath]
      unless image?
        console.log " [ERROR] unable to find building image #{building_image.imagePath}"
        continue

      frame_textures = image.get_frame_textures(building_image.id, building_image.tileWidth * TILE_WIDTH, building_image.tileHeight * TILE_HEIGHT)
      building_image.frame_ids = _.map(frame_textures, (frame) -> frame.id)

      frame_texture_groups.push frame_textures
      console.log " [OK] #{building_image.id} has #{frame_textures.length} frames"

    console.log()
    console.log " [OK] packing textures into spritesheets"
    combine_results.spritesheets = Spritesheet.pack_textures(frame_texture_groups, new Set(), OUTPUT_TEXTURE_WIDTH, OUTPUT_TEXTURE_HEIGHT)
    console.log " [OK] #{combine_results.spritesheets.length} spritesheets packed"

    done(combine_results)


write_assets = (output_dir) -> (combine_results) ->
  new Promise (done) ->
    write_promises = []

    frame_atlas = {}
    atlas_names = []
    for spritesheet in combine_results.spritesheets
      texture_name = "building.texture.#{spritesheet.index}.png"
      write_promises.push spritesheet.save_texture(output_dir, texture_name)

      atlas_name = "building.atlas.#{spritesheet.index}.json"
      atlas_names.push "./#{atlas_name}"

      spritesheet.save_atlas(output_dir, texture_name, atlas_name, DEBUG_MODE)

      frame_atlas[data.key] = atlas_name for data in spritesheet.packed_texture_data
    console.log()

    json = {
      atlas: atlas_names
      images: _.map(combine_results.image_definitions, (image) ->
        {
          id: image.id
          w: image.tileWidth
          h: image.tileHeight
          hit_area: _.map(image.hitArea, (coordinate_list) -> _.map(coordinate_list.coordinates, (coordinate) -> { x: coordinate.x, y: coordinate.y }))
          atlas: frame_atlas[image.frame_ids[0]]
          frames: image.frame_ids
          effects: _.map(image.effects, (effect) -> { type: effect.type, x: effect.x, y: effect.y }) if image.effects?.length
        }
      )
    }

    metadata_file = path.join(output_dir, "building.metadata.json")
    fs.mkdirsSync(path.dirname(metadata_file))
    fs.writeFileSync(metadata_file, if DEBUG_MODE then JSON.stringify(json, null, 2) else JSON.stringify(json))
    console.log " [OK] building metadata saved to #{metadata_file}"

    Promise.all(write_promises).then (result) ->
      process.stdout.write '\n'
      done()


class CombineBuildingManifest
  @combine: (assets_dir, target_dir) ->
    buildings_dir = path.join(assets_dir, 'buildings')
    seals_dir = path.join(assets_dir, 'seals')
    new Promise (done, error) ->
      load_buildings(buildings_dir, seals_dir)
        .then load_building_textures(path.resolve(assets_dir, '..'))
        .then aggregate
        .then write_assets(target_dir)
        .then done
        .catch error

module.exports = CombineBuildingManifest

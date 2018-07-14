
path = require('path')
fs = require('fs-extra')
_ = require('lodash')

BuildingDefinitionManifest = require('../building/building-definition-manifest')
BuildingTextureManifest = require('../building/building-texture-manifest')
Spritesheet = require('../texture/spritesheet')
Utils = require('../utils/utils')

DEBUG_MODE = false

TILE_WIDTH = 64
TILE_HEIGHT = 32

OUTPUT_TEXTURE_WIDTH = 2048
OUTPUT_TEXTURE_HEIGHT = 2048

aggregate = ([building_definition_manifest, building_texture_manifest]) ->
  new Promise (done, error) ->

    frame_texture_groups = []
    for definition in building_definition_manifest.all_definitions
      texture = building_texture_manifest.by_file_path[definition.image]
      unless texture?
        console.log "unable to find building image #{definition.image}"
        continue

      frame_textures = texture.get_frame_textures(definition.id, definition.tile_width * TILE_WIDTH, definition.tile_height * TILE_HEIGHT)
      definition.frame_ids = _.map(frame_textures, (frame) -> frame.id)

      frame_texture_groups.push frame_textures
      console.log "#{definition.id} has #{frame_textures.length} frames"

    done([building_definition_manifest, Spritesheet.pack_textures(frame_texture_groups, new Set(), false, OUTPUT_TEXTURE_WIDTH, OUTPUT_TEXTURE_HEIGHT)])


write_assets = (output_dir) -> ([building_definition_manifest, building_spritesheets]) ->
  new Promise (done) ->
    unique_hash = Utils.random_md5()
    write_promises = []

    frame_atlas = {}
    atlas_names = []
    for spritesheet in building_spritesheets
      texture_name = "building.texture.#{spritesheet.index}.#{unique_hash}.png"
      write_promises.push spritesheet.save_texture(output_dir, texture_name)

      atlas_name = "building.atlas.#{spritesheet.index}.#{unique_hash}.json"
      atlas_names.push "./#{atlas_name}"

      spritesheet.save_atlas(output_dir, texture_name, atlas_name, DEBUG_MODE)

      frame_atlas[data.key] = atlas_name for data in spritesheet.packed_texture_data

    definitions = {}
    for definition in building_definition_manifest.all_definitions
      definitions[definition.id] = {
        w: definition.tile_width
        h: definition.tile_height
        zone: definition.zone
        atlas: frame_atlas[definition.frame_ids[0]]
        frames: definition.frame_ids
      }
      definitions[definition.id].effects = definition.effects if definition.effects?.length

    json = {
      atlas: atlas_names
      buildings: definitions
    }

    metadata_file = path.join(output_dir, "building.metadata.json")
    fs.mkdirsSync(path.dirname(metadata_file))
    fs.writeFileSync(metadata_file, if DEBUG_MODE then JSON.stringify(json, null, 2) else JSON.stringify(json))
    console.log "building metadata saved to #{metadata_file}"

    Promise.all(write_promises).then (result) ->
      process.stdout.write '\n'
      done()


class CombineBuildingManifest
  @combine: (building_dir, target_dir) ->
    new Promise (done, error) ->
      Promise.all [
          BuildingDefinitionManifest.load(building_dir), BuildingTextureManifest.load(building_dir)
        ]
        .then aggregate
        .then write_assets(target_dir)
        .then done
        .catch error

module.exports = CombineBuildingManifest

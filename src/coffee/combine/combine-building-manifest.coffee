
path = require('path')
fs = require('fs-extra')
_ = require('lodash')

BuildingDefinitionManifest = require('../building/building-definition-manifest')
SealManifest = require('../seal/seal-manifest')
Spritesheet = require('../texture/spritesheet')

DEBUG_MODE = false

TILE_WIDTH = 64
TILE_HEIGHT = 32

OUTPUT_TEXTURE_WIDTH = 2048
OUTPUT_TEXTURE_HEIGHT = 2048

aggregate = (translations_manifest) -> ([building_definition_manifest, seals_manifest]) ->
  new Promise (done, error) ->

    for definition in building_definition_manifest.all_definitions
      for seal in _.values(seals_manifest)
        definition.seal_ids.push seal.id if seal.buildings_by_id[definition.id]

      translations_manifest.accumulate_i18n_text(definition.name_key(), definition.name) if definition.name?

    frame_texture_groups = []
    for building_image in building_definition_manifest.all_images
      unless building_image.image?
        console.log "unable to find building image #{building_image.image_path}"
        continue

      frame_textures = building_image.image.get_frame_textures(building_image.id, building_image.tile_width * TILE_WIDTH, building_image.tile_height * TILE_HEIGHT)
      building_image.frame_ids = _.map(frame_textures, (frame) -> frame.id)

      frame_texture_groups.push frame_textures
      console.log "#{building_image.id} has #{frame_textures.length} frames"

    done([building_definition_manifest, Spritesheet.pack_textures(frame_texture_groups, new Set(), OUTPUT_TEXTURE_WIDTH, OUTPUT_TEXTURE_HEIGHT)])


write_assets = (output_dir) -> ([building_definition_manifest, building_spritesheets]) ->
  new Promise (done) ->
    write_promises = []

    frame_atlas = {}
    atlas_names = []
    for spritesheet in building_spritesheets
      texture_name = "building.texture.#{spritesheet.index}.png"
      write_promises.push spritesheet.save_texture(output_dir, texture_name)

      atlas_name = "building.atlas.#{spritesheet.index}.json"
      atlas_names.push "./#{atlas_name}"

      spritesheet.save_atlas(output_dir, texture_name, atlas_name, DEBUG_MODE)

      frame_atlas[data.key] = atlas_name for data in spritesheet.packed_texture_data

    images = []
    images.push building_image.to_compiled_json(frame_atlas[building_image.frame_ids[0]]) for building_image in building_definition_manifest.all_images

    definitions = []
    definitions.push definition.to_compiled_json() for definition in building_definition_manifest.all_definitions

    json = {
      atlas: atlas_names
      images: images
      definitions: definitions
    }

    metadata_file = path.join(output_dir, "building.metadata.json")
    fs.mkdirsSync(path.dirname(metadata_file))
    fs.writeFileSync(metadata_file, if DEBUG_MODE then JSON.stringify(json, null, 2) else JSON.stringify(json))
    console.log "building metadata saved to #{metadata_file}"

    Promise.all(write_promises).then (result) ->
      process.stdout.write '\n'
      done()


class CombineBuildingManifest
  @combine: (translations_manifest, building_dir, seals_dir, target_dir) ->
    new Promise (done, error) ->
      Promise.all [
          BuildingDefinitionManifest.load(building_dir), SealManifest.load(seals_dir)
        ]
        .then aggregate(translations_manifest)
        .then write_assets(target_dir)
        .then done
        .catch error

module.exports = CombineBuildingManifest

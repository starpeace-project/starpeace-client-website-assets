
path = require('path')
fs = require('fs-extra')
_ = require('lodash')

OverlayDefinitionManifest = require('../overlay/overlay-definition-manifest')
OverlayTextureManifest = require('../overlay/overlay-texture-manifest')
Spritesheet = require('../texture/spritesheet')
Utils = require('../utils/utils')

DEBUG_MODE = false

TILE_WIDTH = 64
TILE_HEIGHT = 32

OUTPUT_TEXTURE_WIDTH = 1024
OUTPUT_TEXTURE_HEIGHT = 1024

aggregate = ([overlay_definition_manifest, overlay_texture_manifest]) ->
  new Promise (done, error) ->

    frame_texture_groups = []
    for definition in overlay_definition_manifest.all_definitions
      texture = overlay_texture_manifest.by_file_path[definition.image]
      unless texture?
        console.log "unable to find overlay image #{key}"
        continue

      frame_textures = texture.get_frame_textures(definition.id, definition.tile_width * TILE_WIDTH, definition.tile_height * TILE_WIDTH)
      definition.frame_ids = _.map(frame_textures, (frame) -> frame.id)

      frame_texture_groups.push frame_textures
      console.log "#{definition.id} has #{frame_textures.length} frames"

    done([overlay_definition_manifest, Spritesheet.pack_textures(frame_texture_groups, new Set(), OUTPUT_TEXTURE_WIDTH, OUTPUT_TEXTURE_HEIGHT)])


write_assets = (output_dir) -> ([overlay_definition_manifest, overlay_spritesheets]) ->
  new Promise (done) ->
    write_promises = []

    frame_atlas = {}
    atlas_names = []
    for spritesheet in overlay_spritesheets
      texture_name = "overlay.texture.#{spritesheet.index}.png"
      write_promises.push spritesheet.save_texture(output_dir, texture_name)

      atlas_name = "overlay.atlas.#{spritesheet.index}.json"
      atlas_names.push "./#{atlas_name}"

      spritesheet.save_atlas(output_dir, texture_name, atlas_name, DEBUG_MODE)

      frame_atlas[data.key] = atlas_name for data in spritesheet.packed_texture_data

    definitions = {}
    definitions[definition.id] = {
      w: definition.tile_width
      h: definition.tile_height
      atlas: frame_atlas[definition.frame_ids[0]]
      frames: definition.frame_ids
    } for definition in overlay_definition_manifest.all_definitions

    json = {
      atlas: atlas_names
      overlays: definitions
    }

    metadata_file = path.join(output_dir, "overlay.metadata.json")
    fs.mkdirsSync(path.dirname(metadata_file))
    fs.writeFileSync(metadata_file, if DEBUG_MODE then JSON.stringify(json, null, 2) else JSON.stringify(json))
    console.log "overlay metadata saved to #{metadata_file}"

    Promise.all(write_promises).then (result) ->
      process.stdout.write '\n'
      done()


module.exports = class CombineOverlayManifest
  @combine: (overlay_dir, target_dir) ->
    new Promise (done, error) ->
      Promise.all [
          OverlayDefinitionManifest.load(overlay_dir), OverlayTextureManifest.load(overlay_dir)
        ]
        .then aggregate
        .then write_assets(target_dir)
        .then done
        .catch error

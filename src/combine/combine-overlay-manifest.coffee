_ = require('lodash')
path = require('path')
fs = require('fs-extra')

STARPEACE = require('@starpeace/starpeace-assets-types')

Manifest = require('../common/manifest')
Spritesheet = require('../common/spritesheet')
Texture = require('../common/texture')
TextureManifest = require('../common/texture-manifest')
Utils = require('../utils/utils')

DEBUG_MODE = false

TILE_WIDTH = 64
TILE_HEIGHT = 32

OUTPUT_TEXTURE_WIDTH = 1024
OUTPUT_TEXTURE_HEIGHT = 1024


load_overlay_manifest = (overlay_dir) ->
  new Promise (done) ->
    console.log "loading concrete definition manifest from #{overlay_dir}\n"
    definitions = _.map(JSON.parse(fs.readFileSync(path.join(overlay_dir, 'overlay-manifest.json'))), STARPEACE.overlay.OverlayDefinition.fromJson)
    console.log "found and loaded #{definitions.length} concrete definitions\n"
    done(new Manifest(definitions))

load_overlay_textures = (overlay_dir) ->
  textures = await Texture.load(overlay_dir)
  console.log "found and loaded #{textures.length} effect textures into manifest\n"
  new TextureManifest(textures)

aggregate = ([overlay_definition_manifest, overlay_texture_manifest]) ->
  new Promise (done, error) ->
    frame_texture_groups = []
    for definition in overlay_definition_manifest.definitions
      texture = overlay_texture_manifest.by_file_path[definition.image]
      unless texture?
        console.log "unable to find overlay image #{definition.image}"
        continue

      frame_textures = texture.get_frame_textures(definition.id, definition.tileWidth * TILE_WIDTH, definition.tileHeight * TILE_WIDTH)
      definition.frame_ids = _.map(frame_textures, (frame) -> frame.id)

      frame_texture_groups.push frame_textures
      console.log " [OK] #{definition.id} has #{frame_textures.length} frames"

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
      w: definition.tileWidth
      h: definition.tileHeight
      atlas: frame_atlas[definition.frame_ids[0]]
      frames: definition.frame_ids
    } for definition in overlay_definition_manifest.definitions

    json = {
      atlas: atlas_names
      overlays: definitions
    }

    metadata_file = path.join(output_dir, "overlay.metadata.json")
    fs.mkdirsSync(path.dirname(metadata_file))
    fs.writeFileSync(metadata_file, if DEBUG_MODE then JSON.stringify(json, null, 2) else JSON.stringify(json))
    console.log " [OK] overlay metadata saved to #{metadata_file}"

    Promise.all(write_promises).then (result) ->
      process.stdout.write '\n'
      done()


module.exports = class CombineOverlayManifest
  @combine: (overlay_dir, target_dir) ->
    new Promise (done, error) ->
      Promise.all [
          load_overlay_manifest(overlay_dir), load_overlay_textures(overlay_dir)
        ]
        .then aggregate
        .then write_assets(target_dir)
        .then done
        .catch error

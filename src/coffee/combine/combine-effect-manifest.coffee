
path = require('path')
fs = require('fs-extra')
_ = require('lodash')

EffectDefinitionManifest = require('../effect/effect-definition-manifest')
EffectTextureManifest = require('../effect/effect-texture-manifest')
Spritesheet = require('../texture/spritesheet')
Utils = require('../utils/utils')

DEBUG_MODE = false

OUTPUT_TEXTURE_WIDTH = 256
OUTPUT_TEXTURE_HEIGHT = 256

aggregate = ([effect_definition_manifest, effect_texture_manifest]) ->
  new Promise (done, error) ->

    frame_texture_groups = []
    for definition in effect_definition_manifest.all_definitions
      texture = effect_texture_manifest.by_file_path[definition.image]
      unless texture?
        console.log "unable to find effect image #{key}"
        continue

      frame_textures = texture.get_frame_textures(definition.id, definition.width, definition.height)
      definition.frame_ids = _.map(frame_textures, (frame) -> frame.id)

      frame_texture_groups.push frame_textures
      console.log "#{definition.id} has #{frame_textures.length} frames"

    done([effect_definition_manifest, Spritesheet.pack_textures(frame_texture_groups, new Set(), false, OUTPUT_TEXTURE_WIDTH, OUTPUT_TEXTURE_HEIGHT)])


write_assets = (output_dir) -> ([effect_definition_manifest, effect_spritesheets]) ->
  new Promise (done) ->
    unique_hash = Utils.random_md5()
    write_promises = []

    frame_atlas = {}
    atlas_names = []
    for spritesheet in effect_spritesheets
      texture_name = "effect.texture.#{spritesheet.index}.#{unique_hash}.png"
      write_promises.push spritesheet.save_texture(output_dir, texture_name)

      atlas_name = "effect.atlas.#{spritesheet.index}.#{unique_hash}.json"
      atlas_names.push "./#{atlas_name}"

      spritesheet.save_atlas(output_dir, texture_name, atlas_name, DEBUG_MODE)

      frame_atlas[data.key] = atlas_name for data in spritesheet.packed_texture_data

    definitions = {}
    definitions[definition.id] = {
      w: definition.width
      h: definition.height
      s_x: definition.source_x
      s_y: definition.source_y
      atlas: frame_atlas[definition.frame_ids[0]]
      frames: definition.frame_ids
    } for definition in effect_definition_manifest.all_definitions

    json = {
      atlas: atlas_names
      effects: definitions
    }

    metadata_file = path.join(output_dir, "effect.metadata.json")
    fs.mkdirsSync(path.dirname(metadata_file))
    fs.writeFileSync(metadata_file, if DEBUG_MODE then JSON.stringify(json, null, 2) else JSON.stringify(json))
    console.log "effect metadata saved to #{metadata_file}"

    Promise.all(write_promises).then (result) ->
      process.stdout.write '\n'
      done()


module.exports = class CombineEffectManifest
  @combine: (effect_dir, target_dir) ->
    new Promise (done, error) ->
      Promise.all [
          EffectDefinitionManifest.load(effect_dir), EffectTextureManifest.load(effect_dir)
        ]
        .then aggregate
        .then write_assets(target_dir)
        .then done
        .catch error

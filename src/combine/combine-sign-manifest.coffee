_ = require('lodash')
path = require('path')
fs = require('fs-extra')

STARPEACE = require('@starpeace/starpeace-assets-types')

AnimatedTexture = require('../common/animated-texture')
Manifest = require('../common/manifest')
TextureManifest = require('../common/texture-manifest')
Spritesheet = require('../common/spritesheet')
Utils = require('../utils/utils')

DEBUG_MODE = false

OUTPUT_TEXTURE_WIDTH = 128
OUTPUT_TEXTURE_HEIGHT = 128


load_sign_manifest = (sign_dir) ->
  new Promise (done) ->
    console.log "loading sign definition manifest from #{sign_dir}\n"
    definitions = _.map(JSON.parse(fs.readFileSync(path.join(sign_dir, 'sign-manifest.json'))), STARPEACE.sign.SignDefinition.fromJson)
    console.log "found and loaded #{definitions.length} sign definitions\n"
    done(new Manifest(definitions))

load_sign_textures = (sign_dir) ->
  textures = await AnimatedTexture.load(sign_dir)
  console.log "found and loaded #{textures.length} sign textures into manifest\n"
  new TextureManifest(textures)

aggregate = ([sign_definition_manifest, sign_texture_manifest]) ->
  new Promise (done) ->
    frame_texture_groups = []
    for definition in sign_definition_manifest.definitions
      texture = sign_texture_manifest.by_file_path[definition.image]
      unless texture?
        console.log "unable to find sign image #{definition.image}"
        continue

      frame_textures = texture.get_frame_textures(definition.id, definition.width, definition.height)
      definition.frame_ids = _.map(frame_textures, (frame) -> frame.id)

      frame_texture_groups.push frame_textures
      console.log " [OK] #{definition.id} has #{frame_textures.length} frames"

    done([sign_definition_manifest, Spritesheet.pack_textures(frame_texture_groups, new Set(), OUTPUT_TEXTURE_WIDTH, OUTPUT_TEXTURE_HEIGHT)])


write_assets = (output_dir) -> ([sign_definition_manifest, sign_spritesheets]) ->
  new Promise (done) ->
    write_promises = []

    frame_atlas = {}
    atlas_names = []
    for spritesheet in sign_spritesheets
      texture_name = "sign.texture.#{spritesheet.index}.png"
      write_promises.push spritesheet.save_texture(output_dir, texture_name)

      atlas_name = "sign.atlas.#{spritesheet.index}.json"
      atlas_names.push "./#{atlas_name}"

      spritesheet.save_atlas(output_dir, texture_name, atlas_name, DEBUG_MODE)

      frame_atlas[data.key] = atlas_name for data in spritesheet.packed_texture_data

    definitions = {}
    for definition in sign_definition_manifest.definitions
      definitions[definition.id] = {
        w: definition.width
        h: definition.height
        s_x: definition.sourceX
        s_y: definition.sourceY
        atlas: frame_atlas[definition.frame_ids[0]]
        frames: definition.frame_ids
      } if definition.frame_ids?.length

    json = {
      atlas: atlas_names
      signs: definitions
    }

    metadata_file = path.join(output_dir, "sign.metadata.json")
    fs.mkdirsSync(path.dirname(metadata_file))
    fs.writeFileSync(metadata_file, if DEBUG_MODE then JSON.stringify(json, null, 2) else JSON.stringify(json))
    console.log " [OK] sign metadata saved to #{metadata_file}"

    Promise.all(write_promises).then (result) ->
      process.stdout.write '\n'
      done()


module.exports = class CombineSignManifest
  @combine: (sign_dir, target_dir) ->
    new Promise (done, error) ->
      Promise.all [
          load_sign_manifest(sign_dir), load_sign_textures(sign_dir)
        ]
        .then aggregate
        .then write_assets(target_dir)
        .then done
        .catch error

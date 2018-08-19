
path = require('path')
fs = require('fs-extra')
_ = require('lodash')

PlaneDefinitionManifest = require('../plane/plane-definition-manifest')
PlaneTextureManifest = require('../plane/plane-texture-manifest')
Spritesheet = require('../texture/spritesheet')
Utils = require('../utils/utils')

DEBUG_MODE = false

OUTPUT_TEXTURE_WIDTH = 512
OUTPUT_TEXTURE_HEIGHT = 512

aggregate = ([plane_definition_manifest, plane_texture_manifest]) ->
  new Promise (done, error) ->

    frame_texture_groups = []
    for definition in plane_definition_manifest.all_definitions
      texture = plane_texture_manifest.by_file_path[definition.image]
      unless texture?
        console.log "unable to find plane image #{key}"
        continue

      frame_textures = texture.get_frame_textures(definition.id, definition.width, definition.height)
      definition.frame_ids = _.map(frame_textures, (frame) -> frame.id)

      frame_texture_groups.push frame_textures
      console.log "#{definition.id} has #{frame_textures.length} frames"

    done([plane_definition_manifest, Spritesheet.pack_textures(frame_texture_groups, new Set(), OUTPUT_TEXTURE_WIDTH, OUTPUT_TEXTURE_HEIGHT)])


write_assets = (output_dir) -> ([plane_definition_manifest, plane_spritesheets]) ->
  new Promise (done) ->
    unique_hash = Utils.random_md5()
    write_promises = []

    frame_atlas = {}
    atlas_names = []
    for spritesheet in plane_spritesheets
      texture_name = "plane.texture.#{spritesheet.index}.#{unique_hash}.png"
      write_promises.push spritesheet.save_texture(output_dir, texture_name)

      atlas_name = "plane.atlas.#{spritesheet.index}.#{unique_hash}.json"
      atlas_names.push "./#{atlas_name}"

      spritesheet.save_atlas(output_dir, texture_name, atlas_name, DEBUG_MODE)

      frame_atlas[data.key] = atlas_name for data in spritesheet.packed_texture_data

    definitions = {}
    definitions[definition.id] = {
      w: definition.width
      h: definition.height
      atlas: frame_atlas[definition.frame_ids[0]]
      frames: definition.frame_ids
    } for definition in plane_definition_manifest.all_definitions

    json = {
      atlas: atlas_names
      planes: definitions
    }

    metadata_file = path.join(output_dir, "plane.metadata.json")
    fs.mkdirsSync(path.dirname(metadata_file))
    fs.writeFileSync(metadata_file, if DEBUG_MODE then JSON.stringify(json, null, 2) else JSON.stringify(json))
    console.log "plane metadata saved to #{metadata_file}"

    Promise.all(write_promises).then (result) ->
      process.stdout.write '\n'
      done()


module.exports = class CombinePlaneManifest
  @combine: (plane_dir, target_dir) ->
    new Promise (done, error) ->
      Promise.all [
          PlaneDefinitionManifest.load(plane_dir), PlaneTextureManifest.load(plane_dir)
        ]
        .then aggregate
        .then write_assets(target_dir)
        .then done
        .catch error

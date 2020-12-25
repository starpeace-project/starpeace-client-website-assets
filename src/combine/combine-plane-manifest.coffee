_ = require('lodash')
path = require('path')
fs = require('fs-extra')

STARPEACE = require('@starpeace/starpeace-assets-types')

AnimatedTexture = require('../common/animated-texture')
Manifest = require('../common/manifest')
Spritesheet = require('../common/spritesheet')
TextureManifest = require('../common/texture-manifest')
Utils = require('../utils/utils')

DEBUG_MODE = false

OUTPUT_TEXTURE_WIDTH = 512
OUTPUT_TEXTURE_HEIGHT = 512


load_plane_manifest = (plane_dir) ->
  new Promise (done) ->
    console.log " [OK] loading plane definition manifest from #{plane_dir}"
    definitions = _.map(JSON.parse(fs.readFileSync(path.join(plane_dir, 'plane-manifest.json'))), STARPEACE.plane.PlaneDefinition.fromJson)
    console.log " [OK] found and loaded #{definitions.length} plane definitions\n"
    done(new Manifest(definitions))

load_plane_textures = (plane_dir) ->
  textures = await AnimatedTexture.load(plane_dir)
  console.log " [OK] found and loaded #{textures.length} plane textures into manifest\n"
  new TextureManifest(textures)

aggregate = ([plane_definition_manifest, plane_texture_manifest]) ->
  new Promise (done, error) ->

    frame_texture_groups = []
    for definition in plane_definition_manifest.definitions
      texture = plane_texture_manifest.by_file_path[definition.image]
      unless texture?
        console.log "unable to find plane image #{key}"
        continue

      frame_textures = texture.get_frame_textures(definition.id, definition.width, definition.height)
      definition.frame_ids = _.map(frame_textures, (frame) -> frame.id)

      frame_texture_groups.push frame_textures
      console.log " [OK] #{definition.id} has #{frame_textures.length} frames"

    done([plane_definition_manifest, Spritesheet.pack_textures(frame_texture_groups, new Set(), OUTPUT_TEXTURE_WIDTH, OUTPUT_TEXTURE_HEIGHT)])


write_assets = (output_dir) -> ([plane_definition_manifest, plane_spritesheets]) ->
  new Promise (done) ->
    write_promises = []

    frame_atlas = {}
    atlas_names = []
    for spritesheet in plane_spritesheets
      texture_name = "plane.texture.#{spritesheet.index}.png"
      write_promises.push spritesheet.save_texture(output_dir, texture_name)

      atlas_name = "plane.atlas.#{spritesheet.index}.json"
      atlas_names.push "./#{atlas_name}"

      spritesheet.save_atlas(output_dir, texture_name, atlas_name, DEBUG_MODE)

      frame_atlas[data.key] = atlas_name for data in spritesheet.packed_texture_data

    definitions = {}
    definitions[definition.id] = {
      w: definition.width
      h: definition.height
      atlas: frame_atlas[definition.frame_ids[0]]
      frames: definition.frame_ids
    } for definition in plane_definition_manifest.definitions

    json = {
      atlas: atlas_names
      planes: definitions
    }

    metadata_file = path.join(output_dir, "plane.metadata.json")
    fs.mkdirsSync(path.dirname(metadata_file))
    fs.writeFileSync(metadata_file, if DEBUG_MODE then JSON.stringify(json, null, 2) else JSON.stringify(json))
    console.log()
    console.log " [OK] plane metadata saved to #{metadata_file}"

    Promise.all(write_promises).then (result) ->
      process.stdout.write '\n'
      done()


module.exports = class CombinePlaneManifest
  @combine: (plane_dir, target_dir) ->
    new Promise (done, error) ->
      Promise.all [
          load_plane_manifest(plane_dir), load_plane_textures(plane_dir)
        ]
        .then aggregate
        .then write_assets(target_dir)
        .then done
        .catch error

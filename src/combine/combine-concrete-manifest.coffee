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

OUTPUT_TEXTURE_WIDTH = 512
OUTPUT_TEXTURE_HEIGHT = 512


load_concrete_manifest = (concrete_dir) ->
  new Promise (done) ->
    console.log "loading concrete definition manifest from #{concrete_dir}\n"
    definitions = _.map(JSON.parse(fs.readFileSync(path.join(concrete_dir, 'concrete-manifest.json'))), STARPEACE.concrete.ConcreteDefinition.fromJson)
    console.log "found and loaded #{definitions.length} concrete definitions\n"
    done(new Manifest(definitions))

load_concrete_textures = (concrete_dir) ->
  textures = await Texture.load(concrete_dir)
  console.log "found and loaded #{textures.length} effect textures into manifest\n"
  new TextureManifest(textures)


aggregate = ([concrete_definition_manifest, concrete_texture_manifest]) ->
  new Promise (done, error) ->

    frame_texture_groups = []
    for definition in concrete_definition_manifest.definitions
      texture = concrete_texture_manifest.by_file_path[definition.image]
      unless texture?
        console.log "unable to find concrete image #{definition.image}"
        continue

      texture.id = definition.id
      definition.frame_ids = [texture.id]
      frame_texture_groups.push [texture]

    done([concrete_definition_manifest, Spritesheet.pack_textures(frame_texture_groups, new Set(), OUTPUT_TEXTURE_WIDTH, OUTPUT_TEXTURE_HEIGHT)])


write_assets = (output_dir) -> ([concrete_definition_manifest, concrete_spritesheets]) ->
  new Promise (done) ->
    write_promises = []

    frame_atlas = {}
    atlas_names = []
    for spritesheet in concrete_spritesheets
      texture_name = "concrete.texture.#{spritesheet.index}.png"
      write_promises.push spritesheet.save_texture(output_dir, texture_name)

      atlas_name = "concrete.atlas.#{spritesheet.index}.json"
      atlas_names.push "./#{atlas_name}"

      spritesheet.save_atlas(output_dir, texture_name, atlas_name, DEBUG_MODE)

      frame_atlas[data.key] = atlas_name for data in spritesheet.packed_texture_data

    definitions = {}
    definitions[definition.id] = {
      atlas: frame_atlas[definition.frame_ids[0]]
      frames: definition.frame_ids
    } for definition in concrete_definition_manifest.definitions

    json = {
      atlas: atlas_names
      concrete: definitions
    }

    metadata_file = path.join(output_dir, "concrete.metadata.json")
    fs.mkdirsSync(path.dirname(metadata_file))
    fs.writeFileSync(metadata_file, if DEBUG_MODE then JSON.stringify(json, null, 2) else JSON.stringify(json))
    console.log " [OK] concrete metadata saved to #{metadata_file}"

    Promise.all(write_promises).then (result) ->
      process.stdout.write '\n'
      done()


module.exports = class CombineConcreteManifest
  @combine: (concrete_dir, target_dir) ->
    new Promise (done, error) ->
      Promise.all [
          load_concrete_manifest(concrete_dir), load_concrete_textures(concrete_dir)
        ]
        .then aggregate
        .then write_assets(target_dir)
        .then done
        .catch error

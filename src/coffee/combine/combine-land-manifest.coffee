
path = require('path')
fs = require('fs-extra')
_ = require('lodash')

GroundDefinitionManifest = require('../land/ground/ground-definition-manifest')
GroundTextureManifest = require('../land/ground/ground-texture-manifest')
TreeDefinitionManifest = require('../land/tree/tree-definition-manifest')
TreeTextureManifest = require('../land/tree/tree-texture-manifest')

LandManifest = require('../land/land-manifest')

PLANET_TYPES = ['earth']

DEBUG_MODE = true


# FIXME: TODO: add other planets
PLANETS = new Set(['earth'])
# FIXME: TODO: add other orientations
ORIENTATIONS = new Set(['0deg'])


aggregate_by_planet = ([ground_definition_manifest, ground_texture_manifest, tree_definition_manifest, tree_texture_manifest]) ->
  new Promise (done, error) ->
    land_manifests = []

    for planet_type in PLANET_TYPES
      land_manifests.push(LandManifest.merge(planet_type,
          ground_definition_manifest.all_tiles, ground_texture_manifest.for_planet_type(planet_type),
          tree_definition_manifest.all_definitions, tree_texture_manifest.for_planet_type(planet_type)))

    done(land_manifests)


write_assets = (output_dir) -> (land_manifests) ->
  new Promise (done) ->
    write_promises = []

    for manifest in land_manifests
      atlas_names = []

      for spritesheet,variant in manifest.ground_spritesheets
        texture_name = "ground.#{manifest.planet_type}.texture.#{variant}.png"
        write_promises.push spritesheet.save_texture(output_dir, texture_name, true, false, true)

        atlas_name = "ground.#{manifest.planet_type}.atlas.#{variant}.json"
        atlas_names.push "./#{atlas_name}"

        spritesheet.save_atlas(output_dir, texture_name, atlas_name)

      for spritesheet,variant in manifest.tree_spritesheets
        texture_name = "tree.#{manifest.planet_type}.texture.#{variant}.png"
        write_promises.push spritesheet.save_texture(output_dir, texture_name, true, true, true)

        atlas_name = "tree.#{manifest.planet_type}.atlas.#{variant}.json"
        atlas_names.push "./#{atlas_name}"

        spritesheet.save_atlas(output_dir, texture_name, atlas_name)

      json = {
        planet_type: manifest.planet_type
        atlas: atlas_names
        ground_definitions: manifest.ground_metadata
        tree_definitions: manifest.tree_metadata
      }

      metadata_file = path.join(output_dir, "land.#{manifest.planet_type}.metadata.json")
      fs.mkdirsSync(path.dirname(metadata_file))
      fs.writeFileSync(metadata_file, if DEBUG_MODE then JSON.stringify(json, null, 2) else JSON.stringify(json))
      console.log "land metadata for planet #{manifest.planet_type} saved to #{metadata_file}"


    Promise.all(write_promises).then (result) ->
      process.stdout.write '\n'
      done()


class CombineLandManifest
  @combine: (land_dir, target_dir) ->
    new Promise (done, error) ->
      Promise.all [
          GroundDefinitionManifest.load(land_dir), GroundTextureManifest.load(land_dir),
          TreeDefinitionManifest.load(land_dir), TreeTextureManifest.load(land_dir)
        ]
        .then aggregate_by_planet
        .then write_assets(target_dir)
        .then done
        .catch error

module.exports = CombineLandManifest



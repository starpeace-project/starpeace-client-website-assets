
path = require('path')
fs = require('fs')

_ = require('lodash')

LandMetadataManifest = require('./land/metadata/land-metadata-manifest')
LandTextureManifest = require('./land/texture/land-texture-manifest')
LandManifestValidation = require('./land/land-manifest-validation')

MapImage = require('./maps/map-image')
MapAudit = require('./maps/map-audit')

Utils = require('./utils/utils')


load_land_manifest = (land_dir) ->
  new Promise (done, error) ->
    Promise.all([LandMetadataManifest.load(land_dir), LandTextureManifest.load(land_dir)])
      .then done
      .catch error

audit_land_manifest = ([metadata_manifest, texture_manifest]) ->
  new Promise (done) ->
    console.log "\n-------------------------------------------------------------------------------\n"

    validation = new LandManifestValidation(metadata_manifest, texture_manifest)

    console.log "#{if validation.warnings.metadata.valid_attributes.warning_count then '' else 'all '}#{validation.warnings.metadata.valid_attributes.safe_count} land metadata have valid attributes"
    if validation.warnings.metadata.valid_attributes.warning_count
      console.log "#{validation.warnings.metadata.valid_attributes.warning_count} land metadata have incomplete attributes"
      console.log "[WARN] will need to manually adjust 'path' values to correct"

    console.log "\n#{if validation.warnings.metadata.missing_texture_keys.warning_count then '' else 'all '}#{validation.warnings.metadata.missing_texture_keys.safe_count} land metadata have well-formatted texture keys for all orientations"
    if validation.warnings.metadata.missing_texture_keys.warning_count
      console.log "#{validation.warnings.metadata.missing_texture_keys.warning_count} land metadata are missing texture orientations keys"
      console.log "[WARN] execute 'grunt cleanup' to attempt to correct"

    console.log "\n#{if validation.warnings.texture.valid_attributes.warning_count then '' else 'all '}#{validation.warnings.texture.valid_attributes.safe_count} land textures have all attributes"
    if validation.warnings.texture.valid_attributes.warning_count
      console.log "#{validation.warnings.texture.valid_attributes.warning_count} land textures have incomplete attributes"
      console.log "[WARN] will need to manually adjust texture file names to correct:"
      for key,safe_key of _.omit(validation.warnings.texture.valid_attributes, ['safe_count', 'warning_count'])
        console.log "  #{key} => #{safe_key}"

    console.log "\n#{if validation.warnings.texture.rename_key.warning_count then '' else 'all '}#{validation.warnings.texture.rename_key.safe_count} land textures have well-formatted keys"
    if validation.warnings.texture.rename_key.warning_count
      console.log "#{validation.warnings.texture.rename_key.warning_count} land textures have poorly formatted keys"
      console.log "[WARN] execute 'grunt cleanup' to attempt to correct"

    if validation.warnings.texture.unbound_land_textures.length
      console.log "\n#{validation.warnings.texture.unbound_land_textures.length} land textures don't have tile metadata, should backfill or remove"
      for texture_key in validation.warnings.texture.unbound_land_textures.sort()
        console.log "   #{texture_key}"
    else
      console.log "\nall land textures have tile metadata"
    console.log "#{validation.warnings.texture.matching_land_textures.length} land textures are used by tile metadata"

    console.log "\n#{validation.warnings.texture.missing_land_textures.length} tile metadata are missing textures, should backfill or remove keys"
    for texture_key in validation.warnings.texture.missing_land_textures.sort()
      console.log "   #{texture_key}"

    console.log "\n#{if validation.warnings.texture.duplicate_hash.warning_count then '' else 'all '}#{validation.warnings.texture.duplicate_hash.safe_count} land textures have unique hashes"
    if validation.warnings.texture.duplicate_hash.warning_count
      console.log "#{validation.warnings.texture.duplicate_hash.warning_count} land textures duplicate hashes, should remove duplicate content"
      for hash,keys of _.without(validation.warnings.texture.duplicate_hash, ['safe_count', 'warning_count'])
        console.log "   #{hash} => #{keys}"

    console.log "\n-------------------------------------------------------------------------------\n"
    done([metadata_manifest, texture_manifest])

load_maps = (maps_dir) -> ([metadata_manifest, texture_manifest]) ->
  new Promise (done) ->
    MapImage.load(maps_dir).then (maps) ->
      done([metadata_manifest, texture_manifest, maps])

audit_map = ([metadata_manifest, texture_manifest, maps]) ->
  new Promise (done) ->
    MapAudit.audit(metadata_manifest, maps).then((audit) ->
      missing_colors = audit.sorted_missing_colors()
      if missing_colors.length
        console.log "\nmaps include #{missing_colors.length} colors without metadata:"
        for [color,count] in missing_colors
          console.log "  #{Utils.format_color(color)}) => #{count} tiles"
      else
        console.log "\nall maps colors have tile metadata"

      unused_tile_colors = audit.unused_tile_colors()
      if unused_tile_colors.length
        console.log "\n#{unused_tile_colors.length} metadata are not used in any maps, may be superfluous:"
        sorted_tuples = _.map(unused_tile_colors, (color) ->
          tile = tiles_from_metadata.tiles_from_metadata.by_color[color]
          [color, tile.path, tile.safe_image_key()]
        ).sort((lhs, rhs) -> lhs[2].localeCompare(rhs[2]))

        for [color, tile_path, key, land_images] in sorted_tuples
          console.log "  #{Utils.format_color(color)}) => #{key} #{tile_path}"

      else
        console.log "\nall tile metadata currently in-use (nothing unused)"

      console.log "\n-------------------------------------------------------------------------------\n"
      done([metadata_manifest, texture_manifest, maps])
    )



console.log "\n===============================================================================\n"
console.log " audit-textures.js - https://www.starpeace.io\n"
console.log " analyze and audit raw game metadata and related assets, helping identify"
console.log " missing or superfluous resources, to then cleanup manually.\n"
console.log " see README.md for more details"
console.log "\n===============================================================================\n"

root = process.cwd()
source_dir = path.join(root, process.argv[2])

console.log "input directory: #{source_dir}"
console.log "\n-------------------------------------------------------------------------------\n"

land_dir = path.join(source_dir, 'land')
map_dir = path.join(source_dir, 'maps')

load_land_manifest(land_dir)
  .then(audit_land_manifest)
  .then(load_maps(map_dir))
  .then(audit_map)
  .then(([land_manifest, maps]) ->
    console.log "\nfinished successfully, thank you for using audit-textures.js!"
  )
  .catch((error) ->
    console.log "there was an error during execution:"
    console.log error
  )


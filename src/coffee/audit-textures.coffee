
path = require('path')
fs = require('fs')

_ = require('lodash')

LandManifest = require('./land/land-manifest')
MapImage = require('./maps/map-image')
MapAudit = require('./maps/map-audit')

Utils = require('./utils/utils')

audit_land = ([land_manifest, maps]) ->
  new Promise (done) ->
    console.log "\n-------------------------------------------------------------------------------\n"

    console.log "#{if land_manifest.warnings.metadata.valid_key.warning_count then '' else 'all '}#{land_manifest.warnings.metadata.valid_key.safe_count} tile metadata entries have valid information"
    if land_manifest.warnings.metadata.valid_key.warning_count
      console.log "#{land_manifest.warnings.metadata.valid_key.warning_count} tile metadata entries are incomplete"
      console.log "[WARN] will need to manually adjust 'path' values to correct"

    console.log "\n#{if land_manifest.warnings.metadata.rename_key.warning_count then '' else 'all '}#{land_manifest.warnings.metadata.rename_key.safe_count} tile metadata entries have well-formatted keys"
    if land_manifest.warnings.metadata.rename_key.warning_count
      console.log "#{land_manifest.warnings.metadata.rename_key.warning_count} tile metadata entries have poor formatted keys"
      console.log "[WARN] execute 'grunt cleanup' to attempt to correct"

    console.log "\n#{if land_manifest.warnings.metadata.missing_image_keys.warning_count then '' else 'all '}#{land_manifest.warnings.metadata.missing_image_keys.safe_count} tile metadata entries have well-formatted image keys for all orientations"
    if land_manifest.warnings.metadata.missing_image_keys.warning_count
      console.log "#{land_manifest.warnings.metadata.missing_image_keys.warning_count} tile metadata entries are missing image orientations keys"
      console.log "[WARN] execute 'grunt cleanup' to attempt to correct"

    console.log "\n#{if land_manifest.warnings.image.valid_key.warning_count then '' else 'all '}#{land_manifest.warnings.image.valid_key.safe_count} land images have all information"
    if land_manifest.warnings.image.valid_key.warning_count
      console.log "#{land_manifest.warnings.image.valid_key.warning_count} land images are incomplete"
      console.log "[WARN] will need to manually adjust image file names to correct:"
      for key,safe_key of _.omit(land_manifest.warnings.image.valid_key, ['safe_count', 'warning_count'])
        console.log "  #{key} => #{safe_key}"

    console.log "\n#{if land_manifest.warnings.image.rename_key.warning_count then '' else 'all '}#{land_manifest.warnings.image.rename_key.safe_count} land images have well-formatted keys"
    if land_manifest.warnings.image.rename_key.warning_count
      console.log "#{land_manifest.warnings.image.rename_key.warning_count} land images have poorly formatted keys"
      console.log "[WARN] execute 'grunt cleanup' to attempt to correct"

    console.log "\n#{land_manifest.warnings.image.matching_land_images.length} land images have well-formatted tile metadata"
    if land_manifest.warnings.image.unbound_land_images.length
      console.log "#{land_manifest.warnings.image.unbound_land_images.length} land images don't have tile metadata, should backfill or remove"
      for image_key in land_manifest.warnings.image.unbound_land_images.sort()
        console.log "   #{image_key}"
    else
      console.log "all land images have tile metadata"
    console.log "#{land_manifest.warnings.image.missing_land_images.length} tile metadata are missing images, should backfill or remove keys"
    for image_key in land_manifest.warnings.image.missing_land_images.sort()
      console.log "   #{image_key}"

    console.log "\n#{if land_manifest.warnings.image.duplicate_hash.warning_count then '' else 'all '}#{land_manifest.warnings.image.duplicate_hash.safe_count} land images have unique hashes"
    if land_manifest.warnings.image.duplicate_hash.warning_count
      console.log "#{land_manifest.warnings.image.duplicate_hash.warning_count} land images duplicate hashes, should remove duplicate content"
      for hash,keys of _.without(land_manifest.warnings.image.duplicate_hash, ['safe_count', 'warning_count'])
        console.log "   #{hash} => #{keys}"

    console.log "\n-------------------------------------------------------------------------------\n"
    done([land_manifest, maps])


audit_map = ([land_manifest, maps]) ->
  new Promise (done) ->
    MapAudit.audit(land_manifest, maps).then((audit) ->
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
          tile = land_manifest.tiles_from_metadata.by_color[color]
          [color, tile.path, tile.safe_image_key()]
        ).sort((lhs, rhs) -> lhs[2].localeCompare(rhs[2]))

        for [color, tile_path, key, land_images] in sorted_tuples
          console.log "  #{Utils.format_color(color)}) => #{key} #{tile_path}"

      else
        console.log "\nall tile metadata currently in-use (nothing unused)"

      console.log "\n-------------------------------------------------------------------------------\n"
      done([land_manifest, maps])
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

Promise.all([LandManifest.load(land_dir), MapImage.load(map_dir)])
  .then(audit_land)
  .then(audit_map)

  .then(([land_manifest, maps]) ->
    console.log "\nfinished successfully, thank you for using audit-textures.js!"
  )
  .catch((error) ->
    console.log "there was an error during execution:"
    console.log error
  )


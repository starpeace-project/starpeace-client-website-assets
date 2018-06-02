
path = require('path')
fs = require('fs-extra')

_ = require('lodash')
readlineSync = require('readline-sync')

LandMetadataManifest = require('./land/metadata/land-metadata-manifest')
LandTextureManifest = require('./land/texture/land-texture-manifest')
LandManifestValidation = require('./land/land-manifest-validation')

MapImage = require('./maps/map-image')
MapAudit = require('./maps/map-audit')

Utils = require('./utils/utils')


load_land_manifest = (land_dir) ->
  new Promise (done, error) ->
    Promise.all([LandMetadataManifest.load(land_dir), LandTextureManifest.load(land_dir)])
      .then ([metadata_manifest, texture_manifest]) ->
        done([metadata_manifest, texture_manifest, new LandManifestValidation(metadata_manifest, texture_manifest)])
      .catch error

fix_land_manifest_missing_texture_keys = ([metadata_manifest, texture_manifest, validation]) ->
  new Promise (done) ->
    console.log "\n#{if validation.warnings.metadata.missing_texture_keys.warning_count then '' else 'all '}#{validation.warnings.metadata.missing_texture_keys.safe_count} tile metadata entries have well-formatted texture keys for all orientations"
    if validation.warnings.metadata.missing_texture_keys.warning_count
      console.log "#{validation.warnings.metadata.missing_texture_keys.warning_count} tile metadata entries are missing texture orientations keys\n"
      if readlineSync.keyInYN('would you like to try populating texture orientation keys?')
        process.stdout.write '\n'

        for tile in metadata_manifest.all_tiles
          tile.populate_texture_keys() if tile.missing_texture_keys().length

        data = JSON.stringify(_.map(metadata_manifest.all_tiles, (tile) -> tile.to_json()), null, 2)
        fs.writeFile(path.join(land_dir, 'manifest.json'), data, 'utf8', (err, write_done) ->
          throw err if err
          console.log "\nfinished writing updated metadata file"
          done([metadata_manifest, texture_manifest, validation])
        )
      else
        process.stdout.write '\n'
        done([metadata_manifest, texture_manifest, validation])
    else
      done([metadata_manifest, texture_manifest, validation])

rename_texture_filenames = ([metadata_manifest, texture_manifest, validation]) ->
  new Promise (done) ->
    console.log "\n#{if validation.warnings.texture.rename_key.warning_count then '' else 'all '}#{validation.warnings.texture.rename_key.safe_count} texture entries have well-formatted keys"
    if validation.warnings.texture.rename_key.warning_count
      console.log "#{validation.warnings.texture.rename_key.warning_count} texture entries have poor formatted keys (filenames)"
      if readlineSync.keyInYN('would you like to try renaming texture file names?')
        process.stdout.write '\n'

        for texture in land_manifest.land_images
          safe_key = texture.key.safe_image_key()
          if texture.key.valid() && safe_key != path.basename(texture.file_path)
            source_file = path.join(texture.directory, texture.file_path)
            target_file = path.join(texture.directory, path.dirname(texture.file_path), safe_key)
            fs.renameSync(source_file, target_file)
            console.log "renamed #{source_file} to #{target_file}"

        done([metadata_manifest, texture_manifest, validation])
      else
        process.stdout.write '\n'
        done([metadata_manifest, texture_manifest, validation])
    else
      done([metadata_manifest, texture_manifest, validation])

move_unbound_textures = (legacy_dir) ->
  ([metadata_manifest, texture_manifest, validation]) ->
    new Promise (done) ->
      if validation.warnings.texture.unbound_land_textures.length
        console.log "#{validation.warnings.texture.unbound_land_textures.length} land textures are missing tile metadata\n"
        if readlineSync.keyInYN('would you like to try moving textures to legacy directory?')
          process.stdout.write '\n\n'

          for texture_key in validation.warnings.texture.unbound_land_textures.sort()
            for texture in land_manifest.texture_key_textures[texture_key]
              source_file = path.join(texture.directory, texture.file_path)
              target_file = path.join(legacy_dir, path.dirname(texture.file_path), texture_key)
              if fs.existsSync(target_file)
                console.log "cannot move texture, file already at target #{target_file}"
              else
                fs.mkdirsSync(path.dirname(target_file))
                fs.renameSync(source_file, target_file)
                console.log "moved #{source_file} to #{target_file}"

          done([metadata_manifest, texture_manifest, validation])
        else
          process.stdout.write '\n'
          done([metadata_manifest, texture_manifest, validation])
      else
        console.log "all land textures have tile metadata"
        done([metadata_manifest, texture_manifest, validation])


console.log "\n===============================================================================\n"
console.log " cleanup-textures.js - https://www.starpeace.io\n"
console.log " after analyzing resources for problems, execute simple cleanup"
console.log " with interactive command-line options.\n"
console.log " see README.md for more details"
console.log "\n===============================================================================\n"


root = process.cwd()
source_dir = path.join(root, process.argv[2])
legacy_dir = path.join(root, process.argv[3])

console.log "input directory: #{source_dir}"
console.log "legacy directory: #{legacy_dir}"

console.log "\n-------------------------------------------------------------------------------\n"

land_dir = path.join(source_dir, 'land')

load_land_manifest(land_dir)
  .then(fix_land_manifest_missing_texture_keys)
  .then(rename_texture_filenames)
  .then(move_unbound_textures(legacy_dir))
  .then(([metadata_manifest, texture_manifest, validation]) ->
    console.log "\nfinished successfully, thank you for using cleanup-textures.js!"
  )
  .catch((error) ->
    console.log "there was an error during execution:"
    console.log error
  )


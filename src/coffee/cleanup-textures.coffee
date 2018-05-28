
path = require('path')
fs = require('fs-extra')

_ = require('lodash')
readlineSync = require('readline-sync')

LandManifest = require('./land/land-manifest')
MapImage = require('./maps/map-image')
MapAudit = require('./maps/map-audit')

Utils = require('./utils/utils')


reformat_metadata_manifest = (land_manifest) ->
  new Promise (done) ->
    console.log "\n-------------------------------------------------------------------------------\n"

    console.log "\n#{if land_manifest.warnings.metadata.rename_key.warning_count then '' else 'all '}#{land_manifest.warnings.metadata.rename_key.safe_count} tile metadata entries have well-formatted keys"
    if land_manifest.warnings.metadata.rename_key.warning_count
      console.log "#{land_manifest.warnings.metadata.rename_key.warning_count} tile metadata entries have poor formatted keys\n"
      if readlineSync.keyInYN('would you like to try reformatting metadata keys?')
        process.stdout.write '\n'

        old_key_new_keys = _.omit(land_manifest.warnings.metadata.rename_key, ['safe_count', 'warning_count'])
        for tile in land_manifest.metadata_tiles
          tile.path = old_key_new_keys[tile.path] if old_key_new_keys[tile.path]

        data = JSON.stringify(_.map(land_manifest.metadata_tiles, (tile) -> tile.to_json()), null, 2)
        fs.writeFile(path.join(land_dir, 'manifest.json'), data, 'utf8', (err, write_done) ->
          throw err if err
          console.log "\nfinished writing updated metadata file"
          done(land_manifest)
        )
      else
        process.stdout.write '\n'
        done(land_manifest)
    else
      done(land_manifest)

fix_land_manifest_missing_image_keys = (land_manifest) ->
  new Promise (done) ->
    console.log "\n#{if land_manifest.warnings.metadata.missing_image_keys.warning_count then '' else 'all '}#{land_manifest.warnings.metadata.missing_image_keys.safe_count} tile metadata entries have well-formatted image keys for all orientations"
    if land_manifest.warnings.metadata.missing_image_keys.warning_count
      console.log "#{land_manifest.warnings.metadata.missing_image_keys.warning_count} tile metadata entries are missing image orientations keys\n"
      if readlineSync.keyInYN('would you like to try populating image orientation keys?')
        process.stdout.write '\n'

        for tile in land_manifest.metadata_tiles
          tile.populate_image_keys() if tile.missing_image_keys().length

        data = JSON.stringify(_.map(land_manifest.metadata_tiles, (tile) -> tile.to_json()), null, 2)
        fs.writeFile(path.join(land_dir, 'manifest.json'), data, 'utf8', (err, write_done) ->
          throw err if err
          console.log "\nfinished writing updated metadata file"
          done(land_manifest)
        )
      else
        process.stdout.write '\n'
        done(land_manifest)
    else
      done(land_manifest)

rename_image_filenames = (land_manifest) ->
  new Promise (done) ->
    console.log "\n#{if land_manifest.warnings.image.rename_key.warning_count then '' else 'all '}#{land_manifest.warnings.image.rename_key.safe_count} image entries have well-formatted keys"
    if land_manifest.warnings.image.rename_key.warning_count
      console.log "#{land_manifest.warnings.image.rename_key.warning_count} image entries have poor formatted keys (filenames)"
      if readlineSync.keyInYN('would you like to try renaming image file names?')
        process.stdout.write '\n'

        for image in land_manifest.land_images
          safe_key = image.key.safe_image_key()
          if image.key.valid() && safe_key != path.basename(image.file_path)
            source_file = path.join(image.directory, image.file_path)
            target_file = path.join(image.directory, path.dirname(image.file_path), safe_key)
            fs.renameSync(source_file, target_file)
            console.log "renamed #{source_file} to #{target_file}"

        done(land_manifest)
      else
        process.stdout.write '\n'
        done(land_manifest)
    else
      done(land_manifest)

move_unbound_images = (legacy_dir) ->
  (land_manifest) ->
    new Promise (done) ->
      
      if land_manifest.warnings.image.unbound_land_images.length
        console.log "#{land_manifest.warnings.image.unbound_land_images.length} land images are missing tile metadata\n"
        if readlineSync.keyInYN('would you like to try moving images to legacy directory?')
          process.stdout.write '\n\n'

          for image_key in land_manifest.warnings.image.unbound_land_images.sort()
            for image in land_manifest.image_key_images[image_key]
              source_file = path.join(image.directory, image.file_path)
              target_file = path.join(legacy_dir, path.dirname(image.file_path), image_key)
              if fs.existsSync(target_file)
                console.log "cannot move image, file already at target #{target_file}"
              else
                fs.mkdirsSync(path.dirname(target_file))
                fs.renameSync(source_file, target_file)
                console.log "moved #{source_file} to #{target_file}"

          done(land_manifest)
        else
          process.stdout.write '\n'
          done(land_manifest)
      else
        console.log "all land images have tile metadata"
        done(land_manifest)


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

LandManifest.load(land_dir)
  .then(reformat_metadata_manifest)
  .then(fix_land_manifest_missing_image_keys)
  .then(rename_image_filenames)
  .then(move_unbound_images(legacy_dir))
  .then((land_manifest) ->
    console.log "\nfinished successfully, thank you for using cleanup-textures.js!"
  )
  .catch((error) ->
    console.log "there was an error during execution:"
    console.log error
  )


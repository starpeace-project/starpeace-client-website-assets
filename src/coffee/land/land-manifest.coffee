
path = require('path')
fs = require('fs')

_ = require('lodash')
Jimp = require('jimp')

LandImage = require('./land-image')
LandTile = require('./land-tile')

ConsoleProgressUpdater = require('../utils/console-progress-updater')
FileUtils = require('../utils/file-utils')

class LandManifest

  tiles_from_metadata: {
    by_id: {}
    by_color: {}
    by_key: {}
  }

  warnings: {
    metadata: {
      valid_key: {
        safe_count: 0
        warning_count: 0
        tiles: []
      },
      rename_key: {
        safe_count: 0
        warning_count: 0
        tiles: []
      },
      missing_image_keys: {
        safe_count: 0
        warning_count: 0
        tiles: []
      }
    },
    image: {
      valid_key: {
        safe_count: 0
        warning_count: 0
        tiles: []
      }
      rename_key: {
        safe_count: 0
        warning_count: 0
        tiles: []
      }
      no_metadata: {
        safe_count: 0
        warning_count: 0
        tiles: []
      }
      duplicate_hash: {
        safe_count: 0
        warning_count: 0
      }
    }
  }

  constructor: (@metadata_tiles, @land_images) ->
    metadata_image_keys = new Set()
    for tile in @metadata_tiles
      key = tile.key.safe_image_key()
      @tiles_from_metadata.by_color[tile.map_color] = tile

      for orientation,key of tile.image_keys
        metadata_image_keys.add key.safe_image_key()

      if tile.valid()
        @warnings.metadata.valid_key.safe_count += 1
        if tile.valid_image_keys()
          @warnings.metadata.rename_key.safe_count += 1
        else
          @warnings.metadata.rename_key.warning_count += 1
          @warnings.metadata.rename_key.tiles.push tile
      else
        @warnings.metadata.valid_key.warning_count += 1
        @warnings.metadata.valid_key.tiles.push tile

      if tile.missing_image_keys().length
        @warnings.metadata.missing_image_keys.warning_count += 1
      else
        @warnings.metadata.missing_image_keys.safe_count += 1

    @image_key_images = {}
    found_image_keys = new Set()
    hash_tile = {}
    for image in @land_images
      key = image.key.safe_image_key()
      found_image_keys.add key

      @image_key_images[key] ||= []
      @image_key_images[key].push image

      if image.key.valid()
        @warnings.image.valid_key.safe_count += 1
        if key == path.basename(image.file_path)
          @warnings.image.rename_key.safe_count += 1
        else
          @warnings.image.rename_key.warning_count += 1
          @warnings.image.rename_key.tiles.push image
      else
        @warnings.image.valid_key.warning_count += 1
        @warnings.image.valid_key.tiles.push image

      existing_tile = hash_tile[image.hash]
      if existing_tile && existing_tile.key.safe_image_key() != image.key.safe_image_key()
        diff = Jimp.distance(existing_tile.image, image.image)
        if diff == 0
          @warnings.image.duplicate_hash.warning_count += 1
          @warnings.image.duplicate_hash[image.hash] ||= {}
          @warnings.image.duplicate_hash[image.hash][existing_tile.key.safe_image_key()] = existing_tile
          @warnings.image.duplicate_hash[image.hash][image.key.safe_image_key()] = image
        else
          @warnings.image.duplicate_hash.safe_count += 1
      else
        @warnings.image.duplicate_hash.safe_count += 1
      hash_tile[image.hash] = image

    @warnings.image.matching_land_images = _.intersection(Array.from(metadata_image_keys), Array.from(found_image_keys))
    @warnings.image.missing_land_images = _.difference(Array.from(metadata_image_keys), Array.from(found_image_keys))
    @warnings.image.unbound_land_images = _.difference(Array.from(found_image_keys), Array.from(metadata_image_keys))

#     LandManifest.find_warnings_rename_key(@warnings.image, @land_images)


  @load: (land_dir) ->
    new Promise((fulfill, reject) ->
      console.log "loading land information from #{land_dir}\n"

      Promise.all([
        new Promise((fulfill_inner) ->
          fulfill_inner(_.map(JSON.parse(fs.readFileSync(path.join(land_dir, 'manifest.json'))), LandTile.from_json))
        ),

        new Promise((fulfill_inner) ->
          image_file_paths = _.filter(FileUtils.read_all_files_sync(land_dir), (path) -> path.endsWith('.bmp'))
          Promise.all(_.map(image_file_paths, (p) -> Jimp.read(p))).then((images) ->
            progress = new ConsoleProgressUpdater(images.length)
            fulfill_inner(_.map(_.zip(image_file_paths, images), (pair) ->
              image = LandImage.from(land_dir, pair[0].substring(land_dir.length + 1), pair[1])
              progress.next()
              image
            ))
          )
        )
      ]).then(([metadata_tiles, land_images]) ->
        manifest = new LandManifest(metadata_tiles, land_images)
        console.log "found and loaded #{manifest.metadata_tiles.length} metadata and #{manifest.land_images.length} land images\n"
        fulfill(manifest)
      ).catch(reject)
    )

module.exports = LandManifest

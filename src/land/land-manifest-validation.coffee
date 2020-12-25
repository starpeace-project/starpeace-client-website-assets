_ = require('lodash')
path = require('path')
fs = require('fs')
Jimp = require('jimp')


class LandManifestValidation

  warnings: {
    metadata: {
      valid_attributes: {
        safe_count: 0
        warning_count: 0
        tiles: []
      },
      missing_texture_keys: {
        safe_count: 0
        warning_count: 0
        tiles: []
      }
    },
    texture: {
      valid_attributes: {
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

  constructor: (metadata_manifest, texture_manifest) ->
    metadata_texture_keys = new Set()
    for tile in metadata_manifest.all_tiles
      metadata_texture_keys.add key for key in tile.texture_keys()

      if tile.valid()
        @warnings.metadata.valid_attributes.safe_count += 1
      else
        @warnings.metadata.valid_attributes.warning_count += 1
        @warnings.metadata.valid_attributes.tiles.push tile

      if tile.missing_texture_keys().length
        @warnings.metadata.missing_texture_keys.warning_count += 1
      else
        @warnings.metadata.missing_texture_keys.safe_count += 1


    found_texture_keys = new Set()
    hash_tile = {}
    for texture in texture_manifest.all_textures
      key = texture.ideal_file_name()
      found_texture_keys.add key

      if texture.has_valid_attributes()
        @warnings.texture.valid_attributes.safe_count += 1
        if texture.has_valid_file_name()
          @warnings.texture.rename_key.safe_count += 1
        else
          @warnings.texture.rename_key.warning_count += 1
          @warnings.texture.rename_key.tiles.push texture
      else
        @warnings.texture.valid_attributes.warning_count += 1
        @warnings.texture.valid_attributes.tiles.push texture

      existing_texture = hash_tile[texture.hash]
      existing_texture_key = existing_texture?.ideal_file_name()
      if existing_texture && existing_texture_key != key
        diff = Jimp.distance(existing_texture.image, texture.image)
        if diff == 0
          @warnings.texture.duplicate_hash.warning_count += 1
          @warnings.texture.duplicate_hash[texture.hash] ||= {}
          @warnings.texture.duplicate_hash[texture.hash][existing_texture_key] = existing_texture
          @warnings.texture.duplicate_hash[texture.hash][key] = texture
        else
          @warnings.texture.duplicate_hash.safe_count += 1
      else
        @warnings.texture.duplicate_hash.safe_count += 1
      hash_tile[texture.hash] = texture

    @warnings.texture.matching_land_textures = _.intersection(Array.from(metadata_texture_keys), Array.from(found_texture_keys))
    @warnings.texture.missing_land_textures = _.difference(Array.from(metadata_texture_keys), Array.from(found_texture_keys))
    @warnings.texture.unbound_land_textures = _.difference(Array.from(found_texture_keys), Array.from(metadata_texture_keys))


module.exports = LandManifestValidation

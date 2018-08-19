
path = require('path')
fs = require('fs')

_ = require('lodash')
Jimp = require('jimp')

Spritesheet = require('../texture/spritesheet')


# FIXME: TODO: add other orientations
ORIENTATIONS = new Set(['0deg'])

class LandManifest
  constructor: (@planet_type, @ground_metadata, @ground_spritesheets, @tree_metadata, @tree_spritesheets) ->

  @merge: (planet_type, ground_definitions, ground_textures, tree_definitions, tree_textures) ->
    ground_texture_key_seasons = {}
    for texture in ground_textures
      texture_key = texture.ideal_file_name()
      ground_texture_key_seasons[texture_key] ||= {}
      ground_texture_key_seasons[texture_key][texture.season] = texture

    tree_texture_key_seasons = {}
    for texture in tree_textures
      texture_key = texture.ideal_file_name()
      tree_texture_key_seasons[texture_key] ||= {}
      tree_texture_key_seasons[texture_key][texture.season] = texture


    ground_metadata_by_key = {}
    ground_texture_keys = new Set()
    for tile in ground_definitions
      for orientation,type_texture_key of tile.textures_by_orientation_type
        continue unless ORIENTATIONS.has(orientation)
        ground_metadata = ground_metadata_by_key[tile.key()] = tile.to_compiled_json()

        for season in Object.keys(ground_texture_key_seasons[type_texture_key.key] || {})
          if tile.seasons.has(season)
            spritesheet_key = ground_texture_key_seasons[type_texture_key.key][season].key_for_spritesheet()
            ground_metadata.textures ||= {}
            ground_metadata.textures[orientation] ||= {}
            ground_metadata.textures[orientation][season] ||= {}
            ground_metadata.textures[orientation][season][type_texture_key.type] = spritesheet_key
            ground_texture_keys.add spritesheet_key

    ground_spritesheets = Spritesheet.pack_textures(ground_textures, ground_texture_keys, 2048, 2048)


    tree_metadata_by_key = {}
    tree_texture_keys = new Set()
    for definition in tree_definitions
      tree_metadata = tree_metadata_by_key[definition.key] = definition.to_compiled_json()

      for season in Object.keys(tree_texture_key_seasons[definition.key] || {})
        if definition.seasons.has(season)
          spritesheet_key = tree_texture_key_seasons[definition.key][season].key_for_spritesheet()
          tree_metadata.textures ||= {}
          tree_metadata.textures[season] = spritesheet_key
          tree_texture_keys.add spritesheet_key

    tree_spritesheets = Spritesheet.pack_textures(tree_textures, tree_texture_keys, 768, 768)

    new LandManifest(planet_type, ground_metadata_by_key, ground_spritesheets, tree_metadata_by_key, tree_spritesheets)


module.exports = LandManifest

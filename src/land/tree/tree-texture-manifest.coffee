_ = require('lodash')
path = require('path')
crypto = require('crypto')

TreeTexture = require('./tree-texture')
LandAttributes = require('../land-attributes')


module.exports = class TreeTextureManifest
  constructor: (@all_textures) ->
    @planet_type_id_season_textures = {}

    for texture in @all_textures
      @planet_type_id_season_textures[texture.planet_type] ||= {}
      @planet_type_id_season_textures[texture.planet_type][texture.id] ||= {}
      @planet_type_id_season_textures[texture.planet_type][texture.id][texture.season] = texture

  valid_textures_by_planet_type: () ->
    planet_type_textures = {}
    for planet_type,id_season_texture of @planet_type_id_season_textures
      for id,season_textures of id_season_texture
        if _.intersection(LandAttributes.VALID_SEASONS, Object.keys(season_textures)).length == 4
          planet_type_textures[planet_type] ||= []
          planet_type_textures[planet_type].push id_season_texture
    planet_type_textures

  planet_types: () ->
    Object.keys(@valid_textures_by_planet_type())

  for_planet_type: (planet_type) ->
    textures = []
    for texture in @all_textures
      textures.push texture if texture.planet_type == planet_type
    Array.from(textures)


  @load: (land_dir) ->
    new Promise (fulfill, reject) ->
      TreeTexture.load(land_dir)
        .then (textures) ->
          console.log "found and loaded #{textures.length} tree textures into manifest\n"
          fulfill(new TreeTextureManifest(textures))
        .catch reject

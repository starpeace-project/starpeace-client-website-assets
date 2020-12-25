_ = require('lodash')
path = require('path')
crypto = require('crypto')
Jimp = require('jimp')

LandAttributes = require('../land-attributes')


module.exports = class TreeDefinition

  constructor: () ->
    @id = Number.NaN
    @zone = LandAttributes.ZONES.other
    @key = null
    @variant = Number.NaN
    @seasons = new Set()

  key: () ->
    "tree.#{@zone}.#{@variant.toString().padStart(2, '0')}"

  to_json: () ->
    {
      @id
      @zone
      @key
      @variant
      seasons: Array.from(@seasons)
    }

  to_compiled_json: () ->
    {
      @id
      @zone
    }

  @fromJson: (json) ->
    tile = new TreeDefinition()
    tile.id = json.id
    tile.zone = json.zone
    tile.key = json.key
    tile.variant = json.variant
    tile.seasons = new Set(json.seasons || [LandAttributes.SEASONS.winter, LandAttributes.SEASONS.spring, LandAttributes.SEASONS.summer, LandAttributes.SEASONS.fall])
    tile

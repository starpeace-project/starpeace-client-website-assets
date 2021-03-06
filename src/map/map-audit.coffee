_ = require('lodash')
path = require('path')
fs = require('fs')
Jimp = require('jimp')

ConsoleProgressUpdater = require('../utils/console-progress-updater')
FileUtils = require('../utils/file-utils')

class MapAudit
  constructor: (@metadata_manifest, @maps) ->

    @tile_counts_by_color = {}
    @tile_counts_by_color[tile.map_color] = 0 for tile in @metadata_manifest.all_tiles
    @missing_colors = {}

    progress = new ConsoleProgressUpdater(@maps.length)
    for map in @maps
      for color,count of map.colors()
        if @tile_counts_by_color[color]?
          @tile_counts_by_color[color] += count
        else
          @missing_colors[color] ||= 0
          @missing_colors[color] += count
      progress.next()

  sorted_missing_colors: () ->
    _.map(@missing_colors, (count,color) -> [color, count]).sort((lhs, rhs) -> rhs[1] - lhs[1])

  unused_tile_colors: () ->
    _.map(_.filter(_.map(@tile_counts_by_color, (count,color) -> [color, count]), (pair) -> pair[1] == 0), '0')

  @audit: (metadata_manifest, maps) ->
    new Promise((done) ->
      console.log "starting analysis and audit of maps\n"
      done(new MapAudit(metadata_manifest, maps))
    )

module.exports = MapAudit

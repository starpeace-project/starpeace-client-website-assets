
path = require('path')
fs = require('fs')

_ = require('lodash')
Jimp = require('jimp')

ConsoleProgressUpdater = require('../utils/console-progress-updater')
FileUtils = require('../utils/file-utils')

class MapImage

  constructor: (@path, @image) ->


  colors: () ->
    colors = {}
    for y in [0...@image.bitmap.height]
      for x in [0...@image.bitmap.width]
        color = @image.getPixelColor(x, y) >> 8
        colors[color] ||= 0
        colors[color] += 1
    colors


  @load: (map_dir) ->
    new Promise((done) ->
      console.log "loading map information from #{map_dir}\n"
      image_file_paths = _.filter(FileUtils.read_all_files_sync(map_dir), (path) -> path.endsWith('.bmp'))
      Promise.all(_.map(image_file_paths, (p) -> Jimp.read(p))).then((images) ->
        progress = new ConsoleProgressUpdater(images.length)
        maps = _.map(_.zip(image_file_paths, images), (pair) ->
          progress.next()
          new MapImage(pair[0].substring(map_dir.length + 1), pair[1])
        )
        console.log "found and loaded #{maps.length} maps\n"
        done(maps)
      )
    )

module.exports = MapImage


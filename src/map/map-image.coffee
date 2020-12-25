_ = require('lodash')
path = require('path')
fs = require('fs')
Jimp = require('jimp')

ConsoleProgressUpdater = require('../utils/console-progress-updater')
FileUtils = require('../utils/file-utils')

module.exports = class MapImage

  constructor: (@full_path, @path, @image) ->
    @name = path.basename(@path).replace('.bmp', '')

  colors: () ->
    colors = {}
    for y in [0...@image.bitmap.height]
      for x in [0...@image.bitmap.width]
        color = @image.getPixelColor(x, y) >> 8
        colors[color] ||= 0
        colors[color] += 1
    colors


  @load: (map_dir) ->
    console.log "loading map information from #{map_dir}\n"
    image_file_paths = _.filter(FileUtils.read_all_files_sync(map_dir), (path) -> path.endsWith('.bmp'))

    progress = new ConsoleProgressUpdater(image_file_paths.length)
    images = await Promise.all(_.map(image_file_paths, (p) ->
      img = await Jimp.read(p)
      progress.next()
      img
    ))

    _.map(_.zip(image_file_paths, images), (pair) -> new MapImage(pair[0], pair[0].substring(map_dir.length + 1), pair[1]))

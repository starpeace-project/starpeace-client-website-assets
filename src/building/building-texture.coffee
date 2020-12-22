
path = require('path')
crypto = require('crypto')

_ = require('lodash')

BuildingFrameTexture = require('./building-frame-texture')
ConsoleProgressUpdater = require('../utils/console-progress-updater')
FileUtils = require('../utils/file-utils')
Utils = require('../utils/utils')

module.exports = class BuildingTexture
  constructor: (@file_path, @frames) ->
    throw "building texture must have at least one frame" unless @frames.length > 0

    @id = path.basename(@file_path)
    @id = @id.substring(0, @id.lastIndexOf('\.'))

  get_frame_textures: (root_id, width) ->
    _.map(@frames, (frame_pair) -> new BuildingFrameTexture("#{root_id}.#{frame_pair[0]}", frame_pair[1], width))

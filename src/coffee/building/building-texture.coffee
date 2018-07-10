
path = require('path')
crypto = require('crypto')

_ = require('lodash')

BuildingFrameTexture = require('./building-frame-texture')
ConsoleProgressUpdater = require('../utils/console-progress-updater')
FileUtils = require('../utils/file-utils')
Utils = require('../utils/utils')

module.exports = class BuildingTexture
  constructor: (@directory, @file_path, @frames) ->
    throw "building texture must have at least one frame" unless @frames.length > 0

    @corporation = 'unknown'
    @building_type = 'unknown'

    key_match = /(\S+?)\.(\S+)\.gif/.exec(path.basename(@file_path))
    if key_match
      @corporation = key_match[1]
      @building_type = key_match[2]

    @id = "#{@corporation}.#{@building_type}"

  get_frame_textures: (root_id, width) ->
    _.map(@frames, (frame_pair) -> new BuildingFrameTexture("#{root_id}.#{frame_pair[0]}", frame_pair[1], width))

  @load: (building_dir) ->
    new Promise (fulfill, reject) ->
      console.log "loading building textures from #{building_dir}\n"

      image_file_paths = _.filter(FileUtils.read_all_files_sync(building_dir), (file_path) -> file_path.indexOf('legacy') < 0 && file_path.endsWith('.gif'))
      Utils.load_and_group_animation(image_file_paths)
        .then (frame_groups) ->
          progress = new ConsoleProgressUpdater(frame_groups.length)
          _.map(_.zip(image_file_paths, frame_groups), (pair) ->
            image = new BuildingTexture(building_dir, pair[0].substring(building_dir.length + 1), pair[1])
            progress.next()
            image
          )
        .then fulfill
        .catch reject

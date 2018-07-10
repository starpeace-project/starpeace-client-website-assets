
path = require('path')
crypto = require('crypto')

_ = require('lodash')

PlaneFrameTexture = require('./plane-frame-texture')
ConsoleProgressUpdater = require('../utils/console-progress-updater')
FileUtils = require('../utils/file-utils')
Utils = require('../utils/utils')

module.exports = class PlaneTexture
  constructor: (@file_path, @frames) ->
    throw "plane texture must have at least one frame" unless @frames.length > 0
    @id = @file_path.replace('.gif', '')

  get_frame_textures: (root_id, width, height) ->
    _.map(@frames, (frame_pair) -> new PlaneFrameTexture("#{root_id}.#{frame_pair[0]}", frame_pair[1], width, height))

  @load: (plane_dir) ->
    new Promise (fulfill, reject) ->
      console.log "loading plane textures from #{plane_dir}\n"

      image_file_paths = _.filter(FileUtils.read_all_files_sync(plane_dir), (file_path) -> file_path.indexOf('legacy') < 0 && file_path.endsWith('.gif'))
      Utils.load_and_group_animation(image_file_paths)
        .then (frame_groups) ->
          progress = new ConsoleProgressUpdater(frame_groups.length)
          _.map(_.zip(image_file_paths, frame_groups), (pair) ->
            image = new PlaneTexture(pair[0].substring(plane_dir.length + 1), pair[1])
            progress.next()
            image
          )
        .then fulfill
        .catch reject

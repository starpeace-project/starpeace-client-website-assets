
path = require('path')
crypto = require('crypto')

_ = require('lodash')
streamToArray = require('stream-to-array')
Jimp = require('jimp')
gifFrames = require('gif-frames')

BuildingFrameTexture = require('./building-frame-texture')
Texture = require('../texture/texture')
ConsoleProgressUpdater = require('../utils/console-progress-updater')
FileUtils = require('../utils/file-utils')


class BuildingTexture
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

  @load_frame_images: (image_file_paths) ->
    Promise.all(_.map(image_file_paths, (file_path) -> gifFrames({ url: file_path, frames: 'all', outputType: 'png' })))

  @group_frame_images: (frame_groups) ->
    new Promise (done) ->
      Promise.all(_.map(frame_groups, (group) -> BuildingTexture.group_to_buffer(group))).then(done)

  @group_to_buffer: (frame_group) ->
    new Promise (done) ->
      Promise.all(_.map(frame_group, (frame) -> BuildingTexture.frame_to_image(frame))).then(done)

  @frame_to_image: (frame) ->
    new Promise (done) ->
      streamToArray(frame.getImage()).then (parts) ->
        Jimp.read(Buffer.concat(_.map(parts, (part) -> Buffer.from(part)))).then (image) ->
          done([frame.frameIndex, image])

  @load: (building_dir) ->
    new Promise (fulfill, reject) ->
      console.log "loading building textures from #{building_dir}\n"

      image_file_paths = _.filter(FileUtils.read_all_files_sync(building_dir), (file_path) -> file_path.indexOf('tbd') < 0 && file_path.endsWith('.gif'))
      BuildingTexture.load_frame_images(image_file_paths)
        .then BuildingTexture.group_frame_images
        .then (frame_groups) ->
          progress = new ConsoleProgressUpdater(frame_groups.length)
          _.map(_.zip(image_file_paths, frame_groups), (pair) ->
            image = new BuildingTexture(building_dir, pair[0].substring(building_dir.length + 1), pair[1])
            progress.next()
            image
          )
        .then fulfill
        .catch reject

module.exports = BuildingTexture

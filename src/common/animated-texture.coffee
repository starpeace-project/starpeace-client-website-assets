_ = require('lodash')

Texture = require('../common/texture')
ConsoleProgressUpdater = require('../utils/console-progress-updater')
FileUtils = require('../utils/file-utils')
Utils = require('../utils/utils')

module.exports = class AnimatedTexture
  constructor: (@file_path, @frames) ->
    throw 'animated texture must have at least one frame' unless @frames.length > 0
    @id = @file_path.replace('.gif', '')

  get_frame_textures: (root_id, width, height) -> _.map(@frames, (frame_pair) -> new Texture("#{root_id}.#{frame_pair[0]}", frame_pair[1], width, height))

  @load: (directory) ->
    console.log "loading animated textures from #{directory}\n"

    image_file_paths = _.filter(FileUtils.read_all_files_sync(directory), (file_path) -> file_path.indexOf('legacy') < 0 && file_path.endsWith('.gif'))
    frame_groups = await Utils.load_and_group_animation(null, image_file_paths)
    progress = new ConsoleProgressUpdater(frame_groups.length)

    _.map(_.zip(image_file_paths, frame_groups), (pair) ->
      image = new AnimatedTexture(pair[0].substring(directory.length + 1), pair[1])
      progress.next()
      image
    )

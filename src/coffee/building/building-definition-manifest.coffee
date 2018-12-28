
path = require('path')
fs = require('fs')

_ = require('lodash')

BuildingDefinition = require('./building-definition')
BuildingImage = require('./building-image')
BuildingTexture = require('../building/building-texture')

ConsoleProgressUpdater = require('../utils/console-progress-updater')
FileUtils = require('../utils/file-utils')
Utils = require('../utils/utils')

module.exports = class BuildingDefinitionManifest
  constructor: (@all_definitions, @all_images) ->
    @images_by_id = {}
    @images_by_id[image.id] = image for image in @all_images

  @load: (building_dir) ->
    new Promise (fulfill, reject) ->
      console.log "loading building definition manifest from #{building_dir}\n"

      building_file_paths = _.filter(FileUtils.read_all_files_sync(building_dir), (file_path) -> file_path.endsWith('.json')) || []
      definitions = []
      images = []
      for path in building_file_paths
        json_items = JSON.parse(fs.readFileSync(path))
        for json in json_items
          if json.image_id? || json.construction_image_id?
            definitions.push BuildingDefinition.from_json(json)
          else
            images.push BuildingImage.from_json(json)

      image_paths = []
      image_paths.push building_image.image_path for building_image in images

      Utils.load_and_group_animation(image_paths)
        .then (frame_groups) ->
          progress = new ConsoleProgressUpdater(frame_groups.length)
          _.map(_.zip(image_paths, frame_groups), (pair) ->
            image = new BuildingTexture(pair[0], pair[1])
            progress.next()
            image
          )
        .then (textures) ->
          textures_by_path = {}
          textures_by_path[texture.file_path] = texture for texture in textures

          building_image.image = textures_by_path[building_image.image_path] for building_image in images
          definition_manifest = new BuildingDefinitionManifest(definitions, images)
          console.log "found and loaded #{definition_manifest.all_definitions.length} building definitions and #{definition_manifest.all_images.length} building images\n"
          fulfill(definition_manifest)

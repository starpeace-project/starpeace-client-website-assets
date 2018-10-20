
path = require('path')
fs = require('fs')

_ = require('lodash')

BuildingDefinition = require('./building-definition')
BuildingTexture = require('../building/building-texture')

ConsoleProgressUpdater = require('../utils/console-progress-updater')
FileUtils = require('../utils/file-utils')
Utils = require('../utils/utils')

class BuildingDefinitionManifest
  constructor: (@all_definitions) ->

  @load: (building_dir) ->
    new Promise (fulfill, reject) ->
      console.log "loading building definition manifest from #{building_dir}\n"

      building_file_paths = _.filter(FileUtils.read_all_files_sync(building_dir), (file_path) -> file_path.endsWith('.json')) || []
      definitions = []
      for path in building_file_paths
        console.log "attempting to parase #{path}"
        definitions = definitions.concat(_.map(JSON.parse(fs.readFileSync(path)), BuildingDefinition.from_json))

      image_paths = []
      image_paths.push definition.image_path for definition in definitions

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

          definition.image = textures_by_path[definition.image_path] for definition in definitions
          definition_manifest = new BuildingDefinitionManifest(definitions)
          console.log "found and loaded #{definition_manifest.all_definitions.length} building definitions\n"
          fulfill(definition_manifest)

module.exports = BuildingDefinitionManifest

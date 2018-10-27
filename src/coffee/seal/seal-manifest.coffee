
path = require('path')
fs = require('fs')

_ = require('lodash')

FileUtils = require('../utils/file-utils')

class SealManaifest
  constructor: (@all_definitions) ->

  @load: (seal_dir) ->
    new Promise (fulfill, reject) ->
      console.log "loading seal definitions from #{seal_dir}\n"

      seal_file_paths = _.filter(FileUtils.read_all_files_sync(seal_dir), (file_path) -> file_path.endsWith('.json')) || []
      definitions_by_id = {}
      for path in seal_file_paths
        console.log "attempting to parase #{path}"
        definition = JSON.parse(fs.readFileSync(path))
        definition.buildings_by_id = {}
        definition.buildings_by_id[building_id] = true for building_id in definition.buildings
        definitions_by_id[definition.id] = definition

      console.log "found and loaded #{Object.keys(definitions_by_id)} seal definitions\n"
      fulfill(definitions_by_id)

module.exports = SealManaifest

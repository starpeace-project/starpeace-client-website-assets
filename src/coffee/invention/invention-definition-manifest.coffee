
path = require('path')
fs = require('fs')

_ = require('lodash')

InventionDefinition = require('./invention-definition')

FileUtils = require('../utils/file-utils')

class InventionDefinitionManifest
  constructor: (@all_definitions) ->

  @load: (inventions_dir) ->
    new Promise (fulfill, reject) ->
      console.log " [OK] loading invention manifests from #{inventions_dir}\n"

      definitions = {}
      json_file_paths = FileUtils.read_all_files_sync(inventions_dir, (file_path) -> file_path.endsWith('.json'))
      for json_path in (json_file_paths || [])
        inventions = JSON.parse(fs.readFileSync(json_path))
        definitions[key] = InventionDefinition.from_json(invention) for key,invention of inventions

      console.log " [OK] found and loaded #{Object.keys(definitions).length} invention definitions\n"
      fulfill(new InventionDefinitionManifest(definitions))

module.exports = InventionDefinitionManifest

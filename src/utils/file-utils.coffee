_ = require('lodash')
fs = require('fs')
path = require('path')

class FileUtils
  @read_all_files_sync: (dir, file_matcher) ->
    fs.readdirSync(dir).reduce((files, file) ->
      if fs.statSync(path.join(dir, file)).isDirectory()
        files.concat(FileUtils.read_all_files_sync(path.join(dir, file), file_matcher))
      else
        files.concat(if !file_matcher? || file_matcher(file) then [path.join(dir, file)] else [])
    , [])

  @parse_to_json: (root_dir, whitelist_patterns, blacklist_patterns) ->
    file_matcher = (file_path) ->
      for pattern in blacklist_patterns
        return false if file_path.endsWith(pattern)
      for pattern in whitelist_patterns
        return false unless file_path.endsWith(pattern)
      true
    _.flatten(_.map(FileUtils.read_all_files_sync(root_dir, file_matcher), (path) -> JSON.parse(fs.readFileSync(path))))

module.exports = FileUtils

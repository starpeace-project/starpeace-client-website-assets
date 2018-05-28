
path = require('path')
fs = require('fs')


class FileUtils
  @read_all_files_sync: (dir) ->
    fs.readdirSync(dir).reduce((files, file) ->
      if fs.statSync(path.join(dir, file)).isDirectory()
        files.concat(FileUtils.read_all_files_sync(path.join(dir, file)))
      else
        files.concat(path.join(dir, file))
    , [])

module.exports = FileUtils

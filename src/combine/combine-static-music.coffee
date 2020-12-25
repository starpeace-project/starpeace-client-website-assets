_ = require('lodash')
path = require('path')
fs = require('fs-extra')

module.exports = class CombineStaticMusic
  @combine: (music_dir, target_dir) ->
    new Promise (done, error) ->
      fs.mkdirsSync(target_dir)

      files = ['inmap1.mp3', 'inmap2.mp3', 'inmap3.mp3', 'inmap4.mp3', 'intro.mp3']

      for file in files
        source_file = path.join(music_dir, file)
        target_file = path.join(target_dir, "music.#{file}")
        fs.copySync(source_file, target_file)
        console.log " [OK] static music #{source_file} copied to #{target_file}"

      done([])

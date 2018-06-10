
path = require('path')
fs = require('fs-extra')
_ = require('lodash')


class CombineStaticNews
  @combine: (maps_dir, target_dir) ->
    new Promise (done, error) ->
      fs.mkdirsSync(target_dir)

      source_news_file = path.join(maps_dir, "news.static.en.json")
      target_news_file = path.join(target_dir, "news.static.en.json")
      fs.copySync(source_news_file, target_news_file)
      console.log "static news #{source_news_file} copied to #{target_news_file}"
  
      done([])

module.exports = CombineStaticNews

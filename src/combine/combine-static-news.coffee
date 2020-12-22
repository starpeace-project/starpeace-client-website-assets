
path = require('path')
fs = require('fs-extra')
_ = require('lodash')

NEWS_LANGUAGES = ['de', 'en', 'es', 'fr', 'it', 'pt']

class CombineStaticNews
  @combine: (news_dir, target_dir) ->
    new Promise (done, error) ->
      fs.mkdirsSync(target_dir)

      for language in NEWS_LANGUAGES
        source_news_file = path.join(news_dir, "news.static.#{language}.json")
        target_news_file = path.join(target_dir, "news.static.#{language}.json")
        fs.copySync(source_news_file, target_news_file)
        console.log " [OK] static news #{source_news_file} copied to #{target_news_file}"

      done([])

module.exports = CombineStaticNews

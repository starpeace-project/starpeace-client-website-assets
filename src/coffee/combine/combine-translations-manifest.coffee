
path = require('path')
fs = require('fs-extra')
_ = require('lodash')

DEBUG_MODE = false


write_assets = (translations_manifest, output_dir) ->
  new Promise (done) ->
    console.log " [OK] organizing #{Object.keys(translations_manifest.translation_id_translations).length} translations by language and writing to translations json files"

    for language_code,translations of translations_manifest.to_json()
      translations_file = path.join(output_dir, "translations.#{language_code.toLowerCase()}.json")
      fs.mkdirsSync(path.dirname(translations_file))
      fs.writeFileSync(translations_file, if DEBUG_MODE then JSON.stringify(translations, null, 2) else JSON.stringify(translations))
      console.log " [OK] translations saved to #{translations_file}"

    done()


class CombineTranslationsManifest
  @combine: (translations_manifest, target_dir) -> ([]) ->
    new Promise (done, error) ->
      Promise.all [ write_assets(translations_manifest, target_dir) ]
        .then done
        .catch error

module.exports = CombineTranslationsManifest

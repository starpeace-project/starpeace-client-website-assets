
path = require('path')
fs = require('fs')

_ = require('lodash')

Translation = require('../translation/translation')

class TranslationsManifest
  constructor: () ->
    @translation_id_translations = {}

  accumulate_i18n_text: (id, text_by_language) ->
    other = Translation.for_languages(id, text_by_language)
    if @translation_id_translations[id]
      return if _.isEqual(@translation_id_translations[id], other)
      console.log "[WARN] duplicate translation for #{id}"
    @translation_id_translations[id] = other

  to_json: () ->
    json = {}

    for id,translation of @translation_id_translations
      for language_code,text of translation.language_code_text
        json[language_code] = { language_code: language_code, translations: [] } unless json[language_code]?
        json[language_code].translations.push { id: id, value: text }

    json

module.exports = TranslationsManifest

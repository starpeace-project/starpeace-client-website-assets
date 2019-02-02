
_ = require('lodash')

LANGUAGE_CODES = {
  'EN': true
  'ES': true
  'DE': true
  'FR': true
  'IT': true
  'PT': true
}


class Translation
  constructor: (@id, text_by_language) ->
    if typeof text_by_language == "string"
      @language_code_text = {
        'EN': text_by_language
      }
    else
      @language_code_text = {}
      for language,text of text_by_language
        @language_code_text[language.toUpperCase()] = text if LANGUAGE_CODES[language.toUpperCase()]

  to_json: () ->
    {
      id: @id
      text: _.map(@language_code_text, (value, key) -> { code: key, value: value })
    }

  @for_languages: (id, language_codes_to_text) ->
    new Translation(id, language_codes_to_text)

  @for_english: (id, text) ->
    new Translation(id, { 'EN': text })

module.exports = Translation

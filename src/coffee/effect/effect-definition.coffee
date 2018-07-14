
path = require('path')

_ = require('lodash')

module.exports = class EffectDefinition
  constructor: (@id, @image, @width, @height) ->

  @from_json: (json) ->
    new EffectDefinition(json.id, json.image, json.width, json.height)

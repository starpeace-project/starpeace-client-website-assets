
path = require('path')

_ = require('lodash')

module.exports = class EffectDefinition
  constructor: (@id, @image, @width, @height, @source_x, @source_y) ->

  @fromJson: (json) ->
    new EffectDefinition(json.id, json.image, json.width, json.height, json.source_x, json.source_y)


path = require('path')

_ = require('lodash')

module.exports = class PlaneDefinition
  constructor: (@id, @image, @width, @height) ->

  @fromJson: (json) ->
    new PlaneDefinition(json.id, json.image, json.width, json.height)


module.exports = class ConcreteDefinition
  constructor: (@id, @image) ->

  @fromJson: (json) ->
    new ConcreteDefinition(json.id, json.image)

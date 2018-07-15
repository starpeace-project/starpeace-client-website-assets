
module.exports = class ConcreteDefinition
  constructor: (@id, @image) ->

  @from_json: (json) ->
    new ConcreteDefinition(json.id, json.image)

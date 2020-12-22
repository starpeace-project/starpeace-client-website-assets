
path = require('path')

_ = require('lodash')

class InventionDefinition
  constructor: (@id, @category, @industry_type, @depends_on, @name, @description, @properties) ->

  name_key: () -> "invention.#{@id}.name"
  description_key: () -> "invention.#{@id}.description"

  to_compiled_json: () ->
    {
      id: @id
      category: @category
      industry_type: @industry_type
      depends_on: @depends_on
      name_key: @name_key()
      description_key: @description_key()
      properties: @properties
    }

  @fromJson: (json) ->
    new InventionDefinition(json.id, json.category, json.industry_type, json.depends_on, json.name, json.description, json.properties)

module.exports = InventionDefinition

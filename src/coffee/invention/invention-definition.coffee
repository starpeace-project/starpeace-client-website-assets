
path = require('path')

_ = require('lodash')

class InventionDefinition
  constructor: (@id, @category, @industry_type, @name, @description, @properties) ->

  to_compiled_json: () ->
    {
      id: @id
      category: @category
      industry_type: @industry_type
      name_key: "invention.#{@id}.name"
      description_key: "invention.#{@id}.description"
      properties: @properties
    }

  @from_json: (json) ->
    new InventionDefinition(json.id, json.category, json.industry_type, json.name, json.description, json.properties)

module.exports = InventionDefinition

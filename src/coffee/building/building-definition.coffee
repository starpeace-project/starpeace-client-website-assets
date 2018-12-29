
path = require('path')

_ = require('lodash')

module.exports = class BuildingDefinition
  constructor: (@id) ->
    @seal_ids = []

  name_key: () -> "building.#{@id}.name"

  to_compiled_json: () ->
    json = {
      id: @id
      name_key: @name_key()
      image_id: @image_id
      construction_image_id: @construction_image_id
      seal_ids: _.uniq(@seal_ids)
    }
    json.category = @category if @category?.length
    json.industry_type = @industry_type if @industry_type?.length
    json.zone = @zone if @zone?.length
    json.restricted = true if @restricted
    json.required_invention_ids = @required_invention_ids if @required_invention_ids?.length

    json.industry = @industry if @industry?
    json.warehouse = @warehouse if @warehouse?

    json

  @from_json: (json) ->
    definition = new BuildingDefinition(json.id)
    definition.image_id = json.image_id
    definition.construction_image_id = json.construction_image_id
    definition.name = json.name
    definition.zone = json.zone
    definition.category = json.category
    definition.industry_type = json.industry_type
    definition.restricted = json.restricted || false
    definition.required_inventions = json.required_inventions

    definition.industry = json.industry if json.industry?
    definition.warehouse = json.warehouse if json.warehouse?

    definition

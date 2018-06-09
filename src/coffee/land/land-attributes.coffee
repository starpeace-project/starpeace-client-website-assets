
class LandAttributes
  @PLANET_TYPES: { other:'other', earth:'earth' } # FIXME: TODO: add alien swamp
  @SEASONS: { other:'other', winter:'winter', spring:'spring', summer:'summer', fall:'fall' }
  @ZONES: { other:'other', border:'border', midgrass:'midgrass', grass:'grass', dryground:'dryground', water:'water' }
  @TYPES: {
    other:'other', special:'special', center:'center',
    neo:'neo', seo:'seo', swo:'swo', nwo:'nwo', nei:'nei', sei:'sei', swi:'swi', nwi:'nwi',
    n:'n', e:'e', s:'s', w:'w'
  }

  @VALID_SEASONS: [ LandAttributes.SEASONS.winter, LandAttributes.SEASONS.spring, LandAttributes.SEASONS.summer, LandAttributes.SEASONS.fall ]

  @ORIENTATION_ROTATIONS = { '0deg':0, '90deg':1, '180deg':2, '270deg':3 }
  @TYPE_SINGLE_ROTATION = {
    other:'other', special:'special', center:'center',
    n:'w', e:'n', s:'e', w:'s',
    neo:'nwo', seo:'neo', swo:'seo', nwo:'swo', nei:'nwi', sei:'nei', swi:'sei', nwi:'swi'
  }


  @rotate_type: (type, orientation) ->
    for count in [0...(LandAttributes.ORIENTATION_ROTATIONS[orientation] || 0)]
      type = @TYPE_SINGLE_ROTATION[type] || 'other'
    type


  @planet_type_from_value: (value) ->
    return LandAttributes.PLANET_TYPES[value] if LandAttributes.PLANET_TYPES[value]?
    for key of LandAttributes.PLANET_TYPES
      return LandAttributes.PLANET_TYPES[key] if value.indexOf(key) >= 0
    LandAttributes.PLANET_TYPES.other

  @season_from_value: (value) ->
    safe_value = value.toLowerCase()
    return LandAttributes.SEASONS[safe_value] if LandAttributes.SEASONS[safe_value]?
    for key of LandAttributes.SEASONS
      return LandAttributes.SEASONS[key] if safe_value.indexOf(key) >= 0
    LandAttributes.SEASONS.other

  @zone_from_value: (value) ->
    return LandAttributes.ZONES[value] if LandAttributes.ZONES[value]?
    for key of LandAttributes.ZONES
      return LandAttributes.ZONES[key] if value.indexOf(key) >= 0
    LandAttributes.ZONES.other

  @type_from_value: (value) ->
    return LandAttributes.TYPES[value] if LandAttributes.TYPES[value]?
    for key of LandAttributes.TYPES
      return LandAttributes.TYPES[key] if value.indexOf(key) >= 0
    LandAttributes.TYPES.other

  @variant_from_value: (value) ->
    match = /[a-zA-Z]*(\d+)/g.exec(value)
    if match then new Number(match[1]) else Number.NaN


  @parse: (value) ->
    safe_key_match = /ground\.(\S+)\.(\S+)\.(\S+)\.(\S+)\.bmp/.exec(value)

    attributes = {}
    if safe_key_match
      attributes.id = safe_key_match[1]
      attributes.zone = safe_key_match[2]
      attributes.type = safe_key_match[3]
      attributes.variant = safe_key_match[4]
    else
      parts = value.toLowerCase().split('.')

      attributes.id = new Number(parts[1]) if parts.length > 2
      main_content = if parts.length > 2 then parts[2] else parts[0]

      attributes.zone = LandAttributes.zone_from_value(main_content)
      main_content = main_content.replace(new RegExp(attributes.zone, 'gi'), '')
      attributes.type = LandAttributes.type_from_value(main_content)
      main_content = main_content.replace(new RegExp(attributes.type, 'gi'), '')
      attributes.variant = LandAttributes.variant_from_value(main_content)

    attributes


module.exports = LandAttributes



class LandTileKey
  @ZONES: { other:'other', border:'border', midgrass:'midgrass', grass:'grass', dryground:'dryground', water:'water' }
  @TYPES: {
    other:'other', special:'special', center:'center',
    neo:'neo', seo:'seo', swo:'swo', nwo:'nwo', nei:'nei', sei:'sei', swi:'swi', nwi:'nwi',
    n:'n', e:'e', s:'s', w:'w'
  }

  @ORIENTATION_ROTATIONS = { '0deg':0, '90deg':1, '180deg':2, '270deg':3 }
  @TYPE_SINGLE_ROTATION = {
    other:'other', special:'special', center:'center',
    n:'w', e:'n', s:'e', w:'s',
    neo:'nwo', seo:'neo', swo:'seo', nwo:'swo', nei:'nwi', sei:'nei', swi:'sei', nwi:'swi'
  }

  id: Number.NaN
  zone: LandTileKey.ZONES.other
  type: LandTileKey.TYPES.other
  variant: Number.NaN

  valid: (has_id) ->
    (has_id || !isNaN(@id)) &&
      @zone != LandTileKey.ZONES.other &&
      (@zone == LandTileKey.ZONES.border || @type != LandTileKey.TYPES.other) &&
      !isNaN(@variant)

  to_string: () ->
    "#{@id.toString().padStart(3, '0')}.#{@zone}.#{@type}.#{@variant}"

  safe_image_key: () ->
    "land.#{@to_string()}.bmp"

  @rotate_type: (type, orientation) ->
    for count in [0...(LandTileKey.ORIENTATION_ROTATIONS[orientation] || 0)]
      type = @TYPE_SINGLE_ROTATION[type] || 'other'
    type


  @zone_from_value: (value) ->
    return LandTileKey.ZONES[value] if LandTileKey.ZONES[value]?
    for key of LandTileKey.ZONES
      return LandTileKey.ZONES[key] if value.indexOf(key) >= 0
    LandTileKey.ZONES.other

  @type_from_value: (value) ->
    return LandTileKey.TYPES[value] if LandTileKey.TYPES[value]?
    for key of LandTileKey.TYPES
      return LandTileKey.TYPES[key] if value.indexOf(key) >= 0
    LandTileKey.TYPES.other

  @variant_from_value: (value) ->
    match = /[a-zA-Z]*(\d+)/g.exec(value)
    if match then new Number(match[1]) else Number.NaN

  @with_new_type: (existing, type) ->
    key = new LandTileKey()
    key.id = existing.id
    key.zone = existing.zone
    key.type = type
    key.variant = existing.variant
    key

  @parse: (value) ->
    safe_key_match = /land\.(\S+)\.(\S+)\.(\S+)\.(\S+)\.bmp/.exec(value)

    key = new LandTileKey()
    if safe_key_match
      key.id = safe_key_match[1]
      key.zone = safe_key_match[2]
      key.type = safe_key_match[3]
      key.variant = safe_key_match[4]
    else
      parts = value.toLowerCase().split('.')

      key.id = new Number(parts[1]) if parts.length > 2
      main_content = if parts.length > 2 then parts[2] else parts[0]

      key.zone = LandTileKey.zone_from_value(main_content)
      main_content = main_content.replace(new RegExp(key.zone, 'gi'), '')
      key.type = LandTileKey.type_from_value(main_content)
      main_content = main_content.replace(new RegExp(key.type, 'gi'), '')
      key.variant = LandTileKey.variant_from_value(main_content)

    key


module.exports = LandTileKey


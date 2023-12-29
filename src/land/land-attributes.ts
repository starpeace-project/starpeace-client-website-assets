
export default class LandAttributes {
  // FIXME: TODO: add alien swamp
  static PLANET_TYPES: Record<string, string> = {
    other: 'other',
    earth: 'earth'
  }
  static SEASONS: Record<string, string> = {
    other:'other',
    winter:'winter',
    spring:'spring',
    summer:'summer',
    fall:'fall'
  }
  static ZONES: Record<string, string> = {
    other:'other',
    border:'border',
    midgrass:'midgrass',
    grass:'grass',
    dryground:'dryground',
    water:'water'
  }
  static TYPES: Record<string, string> = {
    other:'other', special:'special', center:'center',
    neo:'neo', seo:'seo', swo:'swo', nwo:'nwo', nei:'nei', sei:'sei', swi:'swi', nwi:'nwi',
    n:'n', e:'e', s:'s', w:'w'
  }

  static VALID_SEASONS: Array<string> = [ LandAttributes.SEASONS.winter, LandAttributes.SEASONS.spring, LandAttributes.SEASONS.summer, LandAttributes.SEASONS.fall ]

  static ORIENTATION_ROTATIONS: Record<string, number> = { '0deg': 0, '90deg': 1, '180deg': 2, '270deg': 3 }
  static TYPE_SINGLE_ROTATION: Record<string, string> = {
    other:'other', special:'special', center:'center',
    n:'w', e:'n', s:'e', w:'s',
    neo:'nwo', seo:'neo', swo:'seo', nwo:'swo', nei:'nwi', sei:'nei', swi:'sei', nwi:'swi'
  }

  static rotateType (type: string, orientation: string): string {
    for (let count = 0; count < (LandAttributes.ORIENTATION_ROTATIONS[orientation] ?? 0); count++) {
      type = LandAttributes.TYPE_SINGLE_ROTATION[type] ?? 'other';
    }
    return type;
  }

  static planetTypeFromValue (value: string | Array<string>): string {
    if (typeof value === 'string' && !!LandAttributes.PLANET_TYPES[value]) {
      return LandAttributes.PLANET_TYPES[value];
    }
    for (const key of Object.keys(LandAttributes.PLANET_TYPES)) {
      if (value.indexOf(key) >= 0) {
        return LandAttributes.PLANET_TYPES[key];
      }
    }
    return LandAttributes.PLANET_TYPES.other;
  }

  static seasonFromValue (value: string): string {
    const safeValue = value.toLowerCase();
    if (!!LandAttributes.SEASONS[safeValue]) {
      return LandAttributes.SEASONS[safeValue];
    }
    for (const key of Object.keys(LandAttributes.SEASONS)) {
      if (safeValue.indexOf(key) >= 0) {
        return LandAttributes.SEASONS[key];
      }
    }
    return LandAttributes.SEASONS.other;
  }

  static zoneFromValue (value: string): string {
    if (LandAttributes.ZONES[value]) {
      return LandAttributes.ZONES[value];
    }
    for (const key of Object.keys(LandAttributes.ZONES)) {
      if (value.indexOf(key) >= 0) {
        return LandAttributes.ZONES[key];
      }
    }
    return LandAttributes.ZONES.other;
  }

  static typeFromValue (value: string): string {
    if (!!LandAttributes.TYPES[value]) {
      return LandAttributes.TYPES[value];
    }
    for (const key of Object.keys(LandAttributes.TYPES)) {
      if (value.indexOf(key) >= 0) {
        return LandAttributes.TYPES[key];
      }
    }
    return LandAttributes.TYPES.other;
  }

  static variantFromValue (value: string): number {
    const match = /[a-zA-Z]*(\d+)/g.exec(value);
    return match ? parseInt(match[1]) : Number.NaN;
  }

  static parse (value: string): Record<string, any> {
    const safeKeyMatch = /ground\.(\S+)\.(\S+)\.(\S+)\.(\S+)\.bmp/.exec(value);

    const attributes: Record<string, any> = {};
    if (safeKeyMatch) {
      attributes.id = safeKeyMatch[1]
      attributes.zone = safeKeyMatch[2]
      attributes.type = safeKeyMatch[3]
      attributes.variant = safeKeyMatch[4]
    }
    else {
      const parts = value.toLowerCase().split('.');

      if (parts.length > 2) {
        attributes.id = parseInt(parts[1]);
      }

      let mainContent = parts.length > 2 ? parts[2] : parts[0];
      attributes.zone = LandAttributes.zoneFromValue(mainContent);
      mainContent = mainContent.replace(new RegExp(attributes.zone, 'gi'), '');
      attributes.type = LandAttributes.typeFromValue(mainContent);
      mainContent = mainContent.replace(new RegExp(attributes.type, 'gi'), '');
      attributes.variant = LandAttributes.variantFromValue(mainContent);
    }

    return attributes;
  }
}


export default class LandAttributes {
  static PLANET_TYPES: Record<string, string> = {
    earth: 'earth',
    alien1: 'alien1',
    alien2: 'alien2'
  }
  static SEASONS: Record<string, string> = {
    winter: 'winter',
    spring: 'spring',
    summer: 'summer',
    fall: 'fall',
    other: 'other'
  }
  static ZONES: Record<string, string> = {
    border: 'border',
    midgrass: 'midgrass',
    grass: 'grass',
    dryground: 'dryground',
    water: 'water',
    other: 'other'
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

  static planetTypeFromFilePath (filePath: string): string {
    for (const key of Object.keys(LandAttributes.PLANET_TYPES)) {
      if (filePath.indexOf(key) >= 0) {
        return LandAttributes.PLANET_TYPES[key];
      }
    }
    return LandAttributes.PLANET_TYPES.earth;
  }

  static seasonFromFilePath (filePath: string): string {
    const safePath = filePath.toLowerCase();
    for (const key of Object.keys(LandAttributes.SEASONS)) {
      if (safePath.indexOf(key) >= 0) {
        return LandAttributes.SEASONS[key];
      }
    }
    return LandAttributes.SEASONS.other;
  }

  static zoneFromFileKey (fileKey: string): string {
    for (const key of Object.keys(LandAttributes.ZONES)) {
      if (fileKey.indexOf(key) >= 0) {
        return LandAttributes.ZONES[key];
      }
    }
    return LandAttributes.ZONES.other;
  }

  static typeFromFileKey (fileKey: string): string {
    for (const key of Object.keys(LandAttributes.TYPES)) {
      if (fileKey.indexOf(key) >= 0) {
        return LandAttributes.TYPES[key];
      }
    }
    return LandAttributes.TYPES.other;
  }

  static variantFromFileKey (fileKey: string): number {
    const match = /[a-zA-Z]*(\d+)/g.exec(fileKey);
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
      attributes.zone = LandAttributes.zoneFromFileKey(mainContent);
      mainContent = mainContent.replace(new RegExp(attributes.zone, 'gi'), '');
      attributes.type = LandAttributes.typeFromFileKey(mainContent);
      mainContent = mainContent.replace(new RegExp(attributes.type, 'gi'), '');
      attributes.variant = LandAttributes.variantFromFileKey(mainContent);
    }

    return attributes;
  }
}

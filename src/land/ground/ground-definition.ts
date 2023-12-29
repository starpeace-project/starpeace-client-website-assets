import _ from 'lodash';

import LandAttributes from '../land-attributes.js'

export default class GroundDefinition {
  id: number = Number.NaN;
  mapColor: number = Number.NaN;
  seasons: Set<string> = new Set();
  planetType: string = LandAttributes.PLANET_TYPES.other;
  zone: string = LandAttributes.ZONES.other;
  type: string = LandAttributes.TYPES.other;

  texturesByOrientationType: Record<string, Record<string, any>> = {};

  get key (): string {
    return `ground.${this.id.toString().padStart(3, '0')}.${this.zone}`;
  }

  get textureKeys (): Array<string> {
    return Object.values(this.texturesByOrientationType).map((texture) => texture.key);
  }
  get missingTextureKeys (): Array<string> {
    return _.difference(['0deg', '90deg', '180deg', '270deg'], Object.keys(this.texturesByOrientationType))
  }

  get valid (): boolean {
    return !isNaN(this.id) && !isNaN(this.mapColor) && !this.missingTextureKeys.length
  }

  get isCenter (): boolean {
    return Object.values(this.texturesByOrientationType).some((texture) => texture.type === 'center');
  }

  populateTextureKeys (): void {
    const root = this.texturesByOrientationType['0deg']
    for (const orientation of ['90deg', '180deg', '270deg']) {
      if (!this.texturesByOrientationType[orientation]) {
        continue;
      }
      this.texturesByOrientationType[orientation] = {
        type: LandAttributes.rotateType(root.type, orientation),
        key: root.key
      }
    }
  }

  toJson (): any {
    return {
      id: this.id,
      map_color: this.mapColor,
      zone: this.zone,
      seasons: Array.from(this.seasons),
      textures: this.texturesByOrientationType
    };
  }

  toCompiledJson (): any {
    return {
      id: this.id,
      map_color: this.mapColor,
      zone: this.zone,
      is_coast: this.zone === LandAttributes.ZONES.water && !this.isCenter
    };
  }

  static fromJson (json: any): GroundDefinition {
    const tile = new GroundDefinition();
    tile.id = json.id;
    tile.mapColor = json.map_color;
    tile.seasons = new Set(json.seasons ?? [LandAttributes.SEASONS.winter, LandAttributes.SEASONS.spring, LandAttributes.SEASONS.summer, LandAttributes.SEASONS.fall]);
    tile.planetType = json.planet_type ?? LandAttributes.PLANET_TYPES.earth; // FIXME: TODO: stop this default
    tile.zone = json.zone ?? LandAttributes.ZONES.other;
    tile.type = json.type ?? LandAttributes.TYPES.other;
    tile.texturesByOrientationType = json.textures ?? {};
    return tile;
  }
}

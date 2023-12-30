import _ from 'lodash';

import LandAttributes from '../land-attributes.js'

interface TextureInfo {
  type: string;
  key: string;
}

export default class GroundDefinition {
  id: number = Number.NaN;
  mapColor: number = Number.NaN;
  zone: string = LandAttributes.ZONES.other;
  textureByOrientation: Record<string, TextureInfo> = {};

  get key (): string {
    return `ground.${this.id.toString().padStart(3, '0')}.${this.zone}`;
  }

  get textureKeys (): Array<string> {
    return Object.values(this.textureByOrientation).map((texture) => texture.key);
  }
  get missingTextureKeys (): Array<string> {
    return _.difference(['0deg', '90deg', '180deg', '270deg'], Object.keys(this.textureByOrientation))
  }

  get valid (): boolean {
    return !isNaN(this.id) && !isNaN(this.mapColor) && !this.missingTextureKeys.length
  }

  get isCenter (): boolean {
    return Object.values(this.textureByOrientation).some((texture) => texture.type === 'center');
  }

  populateTextureKeys (): void {
    const rootInfo = this.textureByOrientation['0deg']
    for (const orientation of ['90deg', '180deg', '270deg']) {
      if (!this.textureByOrientation[orientation]) {
        continue;
      }

      this.textureByOrientation[orientation] = {
        type: LandAttributes.rotateType(rootInfo.type, orientation),
        key: rootInfo.key
      }
    }
  }

  toJson (): any {
    return {
      id: this.id,
      map_color: this.mapColor,
      zone: this.zone,
      textures: this.textureByOrientation
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
    tile.zone = json.zone ?? LandAttributes.ZONES.other;
    tile.textureByOrientation = json.textures ?? {};
    return tile;
  }
}

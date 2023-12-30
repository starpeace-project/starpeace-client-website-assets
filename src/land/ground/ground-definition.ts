import _ from 'lodash';

import LandAttributes from '../land-attributes.js'

interface TextureInfo {
  type: string;
  key: string;
}

export interface GroundDefitionJson {
  id: number;
  map_color: number;
  zone: string;
  is_coast: boolean;

  // orientation -> season -> type/direction -> key
  textures: Record<string, Record<string, Record<string, string>>>;
}

export default class GroundDefinition {
  id: number; // TODO: remove?
  mapColor: number;
  zone: string;
  textureByOrientation: Record<string, TextureInfo> = {};

  constructor (id: number, mapColor: number, zone: string, textureByOrientation: Record<string, TextureInfo>) {
    this.id = id;
    this.mapColor = mapColor;
    this.zone = zone;
    this.textureByOrientation = textureByOrientation;
  }

  get textureKey (): string {
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

  toCompiledJson (): GroundDefitionJson {
    return {
      id: this.id,
      map_color: this.mapColor,
      zone: this.zone,
      is_coast: this.zone === LandAttributes.ZONES.water && !this.isCenter,
      textures: {}
    };
  }

  static fromJson (json: any): GroundDefinition {
    return new GroundDefinition(
      json.id ?? Number.NaN,
      json.map_color ?? Number.NaN,
      json.zone ?? LandAttributes.ZONES.other,
      json.textures ?? {}
    );
  }
}

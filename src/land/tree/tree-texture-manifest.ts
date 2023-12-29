import _ from 'lodash';

import LandAttributes from '../land-attributes.js';
import TreeTexture from './tree-texture.js';


export default class TreeTextureManifest {
  allTextures: Array<TreeTexture>;
  textureByPlanetTypeIdSeason: Record<string, Record<string, Record<string, TreeTexture>>>;

  constructor (allTextures: Array<TreeTexture>) {
    this.textureByPlanetTypeIdSeason = {}

    this.allTextures = allTextures;
    for (const texture of this.allTextures) {
      this.textureByPlanetTypeIdSeason[texture.planetType] ||= {};
      this.textureByPlanetTypeIdSeason[texture.planetType][texture.id] ||= {};
      this.textureByPlanetTypeIdSeason[texture.planetType][texture.id][texture.season] = texture;
    }
  }

  validTexturesByPlanetType (): Record<string, Array<Record<string, Record<string, TreeTexture>>>> {
    const textureByPlanetType: Record<string, Array<Record<string, Record<string, TreeTexture>>>> = {}
    for (const [planetType, textureByIdSeason] of Object.entries(this.textureByPlanetTypeIdSeason)) {
      for (const [_id, textureBySeason] of Object.entries(textureByIdSeason)) {
        if (_.intersection(LandAttributes.VALID_SEASONS, Object.keys(textureBySeason)).length == 4) {
          textureByPlanetType[planetType] ||= [];
          textureByPlanetType[planetType].push(textureByIdSeason);
        }
      }
    }
    return textureByPlanetType;
  }

  planetTypes (): Array<string> {
    return Object.keys(this.validTexturesByPlanetType());
  }

  forPlanetType (planetType: string): Array<TreeTexture> {
    const textures = [];
    for (const texture of this.allTextures) {
      if (texture.planetType === planetType) {
        textures.push(texture);
      }
    }
    return textures;
  }

  static async load (landDir: string): Promise<TreeTextureManifest> {
    const textures = await TreeTexture.load(landDir);
    console.log(`found and loaded ${textures.length} tree textures into manifest\n`);
    return new TreeTextureManifest(textures);
  }
}

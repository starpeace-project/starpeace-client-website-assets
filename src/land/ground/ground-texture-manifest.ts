import GroundTexture from './ground-texture.js';

export default class GroundTextureManifest {
  allTextures: Array<GroundTexture>;

  constructor (allTextures: Array<GroundTexture>) {
    this.allTextures = allTextures;
  }

  forPlanetType (planetType: string): Array<GroundTexture> {
    const textures = [];
    for (const texture of this.allTextures) {
      if (texture.planetType === planetType) {
        textures.push(texture);
      }
    }
    return textures;
  }

  static async load (landDir: string): Promise<GroundTextureManifest> {
    const textures = await GroundTexture.load(landDir);
    console.log(`found and loaded ${textures.length} ground textures into manifest\n`);
    return new GroundTextureManifest(textures);
  }
}

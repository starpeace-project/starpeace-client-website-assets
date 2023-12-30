import GroundTexture from './ground-texture.js';

export default class GroundTextureManifest {
  texturesByPlanetType: Record<string, Array<GroundTexture>> = {};

  constructor (textures: Array<GroundTexture>) {
    for (const texture of textures) {
      this.texturesByPlanetType[texture.planetType] ||= [];
      this.texturesByPlanetType[texture.planetType].push(texture);
    }
  }

  static async load (landDir: string): Promise<GroundTextureManifest> {
    const textures = await GroundTexture.load(landDir);
    console.log(`found and loaded ${textures.length} ground textures into manifest\n`);
    return new GroundTextureManifest(textures);
  }
}

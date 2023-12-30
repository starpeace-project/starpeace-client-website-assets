import TreeTexture from './tree-texture.js';

export default class TreeTextureManifest {
  texturesByPlanetType: Record<string, Array<TreeTexture>> = {};

  constructor (textures: Array<TreeTexture>) {
    for (const texture of textures) {
      this.texturesByPlanetType[texture.planetType] ||= [];
      this.texturesByPlanetType[texture.planetType].push(texture);
    }
  }

  static async load (landDir: string): Promise<TreeTextureManifest> {
    const textures = await TreeTexture.load(landDir);
    console.log(`found and loaded ${textures.length} tree textures into manifest\n`);
    return new TreeTextureManifest(textures);
  }
}

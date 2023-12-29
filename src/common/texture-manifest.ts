import AnimatedTexture from "./animated-texture.js";
import Texture from "./texture.js";

export default class TextureManifest {
  textures: Array<Texture | AnimatedTexture>;
  byFilePath: Record<string, Texture | AnimatedTexture>;

  constructor (textures: Array<Texture | AnimatedTexture>) {
    this.textures = textures;
    this.byFilePath = {};

    for (const texture of this.textures) {
      if (texture.filePath) {
        this.byFilePath[texture.filePath] = texture;
      }
    }
  }
}

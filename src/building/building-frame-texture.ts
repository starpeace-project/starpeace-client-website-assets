import type Jimp from 'jimp';

import Texture from '../common/texture.js';

export default class BuildingFrameTexture extends Texture {
  constructor (id: string, image: Jimp, targetWidth: number) {
    super(id, image, targetWidth);
  }

  get filterMode (): any {
    return {
      blue: true,
      grey: true,
      green: true,
      grey160: true
    };
  }
}


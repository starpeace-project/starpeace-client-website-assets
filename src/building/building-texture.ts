import path from 'path';
import type Jimp from 'jimp';

import BuildingFrameTexture from './building-frame-texture.js';

export default class BuildingTexture {
  id: string;
  filePath: string;
  frames: Array<[number, Jimp]>;

  constructor (filePath: string, frames: Array<[number, Jimp]>) {
    if (frames.length <= 0) {
      throw "building texture must have at least one frame";
    }

    this.filePath = filePath;
    this.frames = frames;
    this.id = path.basename(this.filePath);
    this.id = this.id.substring(0, this.id.lastIndexOf('\.'))
  }

  getFrameTextures (rootId: string, width: number): Array<BuildingFrameTexture> {
    return this.frames.map((pair) => new BuildingFrameTexture(`${rootId}.${pair[0]}`, pair[1], width));
  }
}

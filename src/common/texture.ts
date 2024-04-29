import _ from 'lodash';
import Jimp from 'jimp';

import ConsoleProgressUpdater from '../utils/console-progress-updater.js';
import FileUtils from '../utils/file-utils.js';


export default class Texture {
  id: string;
  image: Jimp;

  filePath: string | undefined;

  targetWidth: number | undefined;
  targetHeight: number | undefined;

  constructor (id: string, image: Jimp, targetWidth?: number | undefined, targetHeight?: number | undefined) {
    this.id = id;
    this.image = image;

    this.targetWidth = targetWidth;
    this.targetHeight = targetHeight;

    if (targetWidth !== undefined && targetHeight === undefined) {
      this.targetHeight = (this.image?.bitmap?.height ?? 0) * (targetWidth / (this.image?.bitmap?.width ?? 0));
    }
  }

  toString (): string {
    return `${this.id} => ${this.width}x${this.height}`;
  }

  get width (): number {
    return this.image?.bitmap?.width ?? 0;
  }
  get height (): number {
    return this.image?.bitmap?.height ?? 0;
  }

  get keyForSpritesheet () {
    return this.id;
  }

  get filterMode (): any {
    return {};
  }

  getFrameTextures (rootId: string, width?: number | undefined, height?: number | undefined): Array<Texture> {
    return [new Texture(rootId, this.image, width, height)];
  }

  static async load (directory: string, baseDirectory: string | undefined = undefined): Promise<Array<Texture>> {
    console.log(`loading animated textures from ${directory}\n`);

    const imageFilePaths = FileUtils.readAllFiles(directory).filter((filePath) => filePath.indexOf('legacy') < 0 && (filePath.endsWith('.bmp') || filePath.endsWith('.png')));
    const progress = new ConsoleProgressUpdater(imageFilePaths.length);
    const images = await Promise.all(imageFilePaths.map((filePath) => {
      const img = Jimp.read(filePath);
      progress.next();
      return img;
    }));

    return _.zip(imageFilePaths, images).filter((pair) => pair[0] && pair[1]).map((pair) => {
      const filePath = (pair[0] as string).substring((baseDirectory ?? directory).length + 1).replace(/\\/g, '/');
      const image = new Texture(filePath.replace('.bmp', '').replace('.png', ''), (pair[1] as Jimp));
      image.filePath = filePath;
      return image;
    });
  }

}

import _ from 'lodash';
import path from 'path';
import Jimp from 'jimp';

import ConsoleProgressUpdater from '../utils/console-progress-updater.js';
import FileUtils from '../utils/file-utils.js';

export default class MapImage {
  fullPath: string;
  imagePath: string;
  name: string;

  image: Jimp;

  constructor (fullPath: string, imagePath: string, image: Jimp) {
    this.fullPath = fullPath;
    this.imagePath = imagePath;
    this.name = path.basename(this.imagePath).replace('.png', '')
    this.image = image;
  }

  colors (): Record<string, number> {
    const colors: Record<string, number> = {};
    for (let y = 0; y < this.image.bitmap.height; y++) {
      for (let x = 0; x < this.image.bitmap.width; x++) {
        const color = ((this.image.getPixelColor(x, y) as unknown as number) >> 8).toString();
        colors[color] ||= 0
        colors[color] += 1
      }
    }
    return colors;
  }

  static async load (mapDir: string): Promise<Array<MapImage>> {
    console.log(`loading map information from ${mapDir}\n`);
    const imagePaths = FileUtils.readAllFiles(mapDir).filter((path) => path.endsWith('.png'));

    const progress = new ConsoleProgressUpdater(imagePaths.length);
    const images = await Promise.all(imagePaths.map(async (p) => {
      const img = await Jimp.read(p);
      progress.next();
      return img;
    }));

    return _.zip(imagePaths, images).filter((pair) => pair[0] && pair[1]).map((pair) => new MapImage(pair[0] as string, (pair[0] as string).substring(mapDir.length + 1), pair[1] as Jimp));
  }

}

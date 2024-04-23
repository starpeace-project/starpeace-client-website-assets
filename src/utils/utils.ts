import _ from 'lodash';
import crypto from 'crypto';
import decodeGif from 'decode-gif';
import fs from 'fs-extra';
import Jimp from 'jimp';
import path from 'path';

import ConsoleProgressUpdater from './console-progress-updater.js';

export default class Utils {
  static randomMd5 (): string {
    const data = (Math.random() * new Date().getTime()) + "asdf" + (Math.random() * 1000000) + "fdsa" +(Math.random() * 1000000);
    return crypto.createHash('md5').update(data).digest('hex');
  }

  static formatColor (color: any): string {
    return `${color.toString().padStart(10)} (#${parseInt(color).toString(16).padStart(6, '0')}`;
  }

  static cloneImage (sourceBitmap: any, filterMode: any): Jimp {
    const image = new Jimp(sourceBitmap.width, sourceBitmap.height);
    image.background(0x00000000);

    for (let y = 0; y < sourceBitmap.height; y++) {
      for (let x = 0; x < sourceBitmap.width; x++) {
        const index: number = image.getPixelIndex(x, y) as unknown as number;
        const red = sourceBitmap.data[index + 0];
        const green = sourceBitmap.data[index + 1];
        const blue  = sourceBitmap.data[index + 2];
        const alpha = sourceBitmap.data[index + 3];
        if (filterMode.red && red == 255 && green == 0 && blue == 0) {
          continue;
        }
        if (filterMode.blue && red == 0 && green == 0 && blue == 255) {
          continue;
        }
        if (filterMode.blue204 && red == 0 && green == 0 && blue == 204) {
          continue;
        }
        if (filterMode.white && red == 255 && green == 255 && blue == 255) {
          continue;
        }
        if (filterMode.grey && red == 247 && green == 247 && blue == 247) {
          continue;
        }
        if (filterMode.lime && red == 51 && green == 255 && blue == 102) {
          continue;
        }
        if (filterMode.lime169 && red == 0 && green == 255 && blue == 169) {
          continue;
        }
        if (filterMode.lightBlue && red == 0 && green == 204 && blue == 255) {
          continue;
        }
        if (filterMode.purple && red == 237 && green == 50 && blue == 255) {
          continue;
        }
        if (filterMode.orange && red == 255 && green == 169 && blue == 0) {
          continue;
        }
        if (filterMode.orange203 && red == 203 && green == 135 && blue == 0) {
          continue;
        }
        if (filterMode.orange255 && red == 255 && green == 0 && blue == 34) {
          continue;
        }
        if (filterMode.grey160 && red == 160 && green == 160 && blue == 160) {
          continue;
        }
        if (filterMode.road_colors && (red == 39 && green == 84 && blue == 99 || red == 255 && green == 255 && blue == 255)) {
          continue;
        }

        image.setPixelColor(Jimp.rgbaToInt(red, green, blue, alpha, () => {}), x, y);
      }
    }

    return image;
  }

  static async loadAndGroupAnimation (rootDir: string | undefined, imageFilePaths: Array<string>, showProgress: boolean = false): Promise<Array<Array<[number, Jimp]>>> {
    let progressUpdater = showProgress ? new ConsoleProgressUpdater(2 * imageFilePaths.length) : undefined;
    return Promise.all(imageFilePaths.map(async (filePath) => {
      const gifPath = rootDir ? path.resolve(rootDir, filePath) : filePath;

      const framePairs: Array<[number, Jimp]> = [];
      if (gifPath.endsWith('.gif')) {
        const data = decodeGif(fs.readFileSync(gifPath));
        progressUpdater?.next();

        data.frames.sort((lhs, rhs) => lhs.timeCode - rhs.timeCode);
        for (let frameIndex = 0; frameIndex < data.frames.length; frameIndex++) {
          const image = new Jimp({ data: Buffer.from(data.frames[frameIndex].data), width: data.width, height: data.height });
          framePairs.push([frameIndex, image]);
        }
        progressUpdater?.next();
      }
      else {
        framePairs.push([0, await Jimp.read(gifPath)]);
        progressUpdater?.next();
      }
      return framePairs;
    }));
  }

}

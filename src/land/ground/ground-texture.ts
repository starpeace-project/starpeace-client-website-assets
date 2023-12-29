import _ from 'lodash';
import crypto from 'crypto';
import Jimp from 'jimp';
import path from 'path';

import LandAttributes from '../land-attributes.js';
import Texture from '../../common/texture.js'
import ConsoleProgressUpdater from '../../utils/console-progress-updater.js';
import FileUtils from '../../utils/file-utils.js';


export default class GroundTexture extends Texture {
  // directory: string;
  filePath: string;

  planetType: string;
  season: string;
  zone: string;
  type: string;
  variant: number;

  hash: string;
  mapColor: number;

  constructor (filePath: string, image: Jimp, planetType: string, id: number, season: string, zone: string, type: string, variant: number, hash: string, mapColor: number) {
    super(isNaN(id) ? `${planetType}.${season}.${zone}.${type}.${variant}` : id.toString(), image);
    this.filePath = filePath;
    this.planetType = planetType;
    this.season = season;
    this.zone = zone;
    this.type = type;
    this.variant = variant;
    this.hash = hash;
    this.mapColor = mapColor;
  };

  get idealFileName (): string {
    return `ground.${this.id?.toString()?.padStart(3, '0')}.${this.zone}.${this.type}.${this.variant}.bmp`;
  }
  get keyForSpritesheet (): string {
    return `${this.season}.${this.id?.toString()?.padStart(3, '0')}.${this.zone}.${this.type}.${this.variant}`;
  }

  get filterMode (): any {
    return {
      blue: true,
      grey: true
    };
  }

  get hasValidAttributes (): boolean {
    return this.planetType !== LandAttributes.PLANET_TYPES.other && this.season !== LandAttributes.SEASONS.other &&
        this.id !== undefined &&
        this.zone !== LandAttributes.ZONES.other &&
        this.type !== LandAttributes.TYPES.other &&
        !isNaN(this.variant);
  }

  get hasValidFileName (): boolean {
    return this.idealFileName === path.basename(this.filePath);
  }

  static imageHash (width: number, height: number, bitmapData: any): string {
    if (!width || !height || !bitmapData) {
      return '0';
    }
    let data = '';
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        const index = y * width + x;
        data += (bitmapData[index] + bitmapData[index + 1] + bitmapData[index + 2] + bitmapData[index + 3]);
      }
    }
    return crypto.createHash('md5').update(data).digest('hex');
  }

  static calculateMapColor (width: number, height: number, bitmapData: any): number {
    if (!width || !height || !bitmapData) {
      return 0;
    }
    let count = 0;
    let r = 0;
    let g = 0;
    let b = 0;
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        const index = y * width + x;
        if ((bitmapData[index + 3] == 255) ||
              (bitmapData[index] == 0 && bitmapData[index + 1] == 255 && bitmapData[index + 2] == 255) ||
              (bitmapData[index] == 255 && bitmapData[index + 1] == 255 && bitmapData[index + 2] == 255)) {
          continue;
        }
        r += bitmapData[index + 2];
        g += bitmapData[index + 1];
        b += bitmapData[index + 0];
        count += 1;
      }
    }
    return ((r / count) << 16) | ((g / count) << 8) | ((b / count) << 0);
  }

  static create (filePath: string, image: Jimp): GroundTexture {
    const attributes = LandAttributes.parse(path.basename(filePath));
    return new GroundTexture(
      filePath,
      image,
      LandAttributes.planetTypeFromValue(filePath),
      attributes.id,
      LandAttributes.seasonFromValue(filePath),
      attributes.zone,
      attributes.type,
      attributes.variant,
      GroundTexture.imageHash(image.bitmap.width, image.bitmap.height, image.bitmap.data),
      GroundTexture.calculateMapColor(image.bitmap.width, image.bitmap.height, image.bitmap.data)
    );
  }

  static async load (landDir: string): Promise<Array<GroundTexture>> {
    console.log(`loading land textures from ${landDir}\n`);
    const imageFilePaths = FileUtils.readAllFiles(landDir).filter((filePath) => path.basename(filePath).startsWith('ground') && filePath.endsWith('.bmp'));
    const images = await Promise.all(imageFilePaths.map((filePath) => Jimp.read(filePath)));
    const progress = new ConsoleProgressUpdater(images.length);

    return _.zip(imageFilePaths, images).filter((pair) => pair[0] && pair[1]).map((pair) => {
      const image = GroundTexture.create((pair[0] as string).substring(landDir.length + 1), pair[1] as Jimp);
      progress.next();
      return image;
    });
  }
}

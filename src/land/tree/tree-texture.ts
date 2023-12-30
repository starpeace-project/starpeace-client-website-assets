import _ from 'lodash';
import Jimp from 'jimp';
import path from 'path';

import Texture from '../../common/texture.js';
import FileUtils from '../../utils/file-utils.js';
import LandAttributes from '../land-attributes.js';
import ConsoleProgressUpdater from '../../utils/console-progress-updater.js';

export default class TreeTexture extends Texture {
  fileKey: string;

  planetType: string;
  season: string;
  variant: number;
  zone: string;

  constructor (fileKey: string, image: Jimp, id: string, planetType: string, season: string, variant: number, zone: string) {
    super(id, image);

    this.fileKey = fileKey;
    this.planetType = planetType;
    this.season = season;
    this.variant = variant;
    this.zone = zone;
  }

  get textureKey (): string {
    return `tree.${this.zone}.${this.variant.toString().padStart(2, '0')}`;
  }
  get keyForSpritesheet (): string {
    return `${this.season}.${this.zone}.${this.variant.toString().padStart(2, '0')}`;
  }

  get filterMode (): any {
    return {
      red: true,
      blue: true,
      blue204: true,
      white: true,
      grey: true,
      lime: true,
      lime169: true,
      lightBlue: true,
      orange: true,
      orange203: true,
      orange255: true,
      purple: true
    };
  }

  static create (filePath: string, image: Jimp): TreeTexture {
    const planetType = LandAttributes.planetTypeFromFilePath(filePath);
    const season = LandAttributes.seasonFromFilePath(filePath);

    const fileKey = path.basename(filePath);
    let variant = Number.NaN;
    let zone = LandAttributes.ZONES.other;
    const keyMatch = /tree\.(\S+)\.(\S+)\.bmp/.exec(fileKey);
    if (keyMatch) {
      variant = parseInt(keyMatch[2]);
      zone = LandAttributes.zoneFromFileKey(keyMatch[1]);
    }
    return new TreeTexture(fileKey, image, `${planetType}.${season}.${zone}.${variant}`, planetType, season, variant, zone);
  }

  static async load (landDir: string): Promise<Array<TreeTexture>> {
    console.log(`loading tree textures from ${landDir}\n`);

    const imageFilePaths = FileUtils.readAllFiles(landDir).filter((filePath) => path.basename(filePath).startsWith('tree') && filePath.endsWith('.bmp'));
    const progress = new ConsoleProgressUpdater(imageFilePaths.length);
    const images = await Promise.all(imageFilePaths.map((filePath) => {
      const img = Jimp.read(filePath);
      progress.next();
      return img;
    }));

    return _.zip(imageFilePaths, images).filter((pair) => pair[0] && pair[1]).map((pair) => TreeTexture.create((pair[0] as string).substring(landDir.length + 1), pair[1] as Jimp));
  }
}

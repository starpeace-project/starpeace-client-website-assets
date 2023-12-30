import _ from 'lodash';
import Jimp from 'jimp';
import path from 'path';

import Texture from '../../common/texture.js';
import FileUtils from '../../utils/file-utils.js';
import LandAttributes from '../land-attributes.js';
import ConsoleProgressUpdater from '../../utils/console-progress-updater.js';

export default class TreeTexture extends Texture {
  filePath: string;

  planetType: string;
  season: string;
  variant: number;
  zone: string;

  constructor (filePath: string, image: Jimp, id: string, planetType: string, season: string, variant: number, zone: string) {
    super(id, image);

    this.filePath = filePath;
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
      blue: true,
      white: true,
      grey: true
    };
  }

  static create (filePath: string, image: Jimp): TreeTexture {
    const planetType = LandAttributes.planetTypeFromValue(filePath);
    const season = LandAttributes.seasonFromValue(filePath);

    let variant = Number.NaN;
    let zone = LandAttributes.ZONES.other;
    const keyMatch = /tree\.(\S+)\.(\S+)\.bmp/.exec(path.basename(filePath));
    if (keyMatch) {
      variant = parseInt(keyMatch[2]);
      zone = LandAttributes.zoneFromValue(keyMatch[1]);
    }
    return new TreeTexture(filePath, image, `${planetType}.${season}.${zone}.${variant}`, planetType, season, variant, zone);
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

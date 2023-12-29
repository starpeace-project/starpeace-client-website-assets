import _ from 'lodash';

import Texture from './texture.js'
import FileUtils from '../utils/file-utils.js';
import Utils from '../utils/utils.js';
import ConsoleProgressUpdater from '../utils/console-progress-updater.js';


export default class AnimatedTexture {
  id: string;
  filePath: string;
  frames: Array<any>;

  constructor (filePath: string, frames: Array<any>) {
    this.filePath = filePath;
    this.frames = frames;
    if (this.frames.length <= 0) {
      throw 'animated texture must have at least one frame';
    }
    this.id = this.filePath.replace('.gif', '');
  }

  getFrameTextures (rootId: string, width?: number | undefined, height?: number | undefined): Array<Texture> {
    return this.frames.map((pair) => new Texture(`${rootId}.${pair[0]}`, pair[1], width, height));
  }

  static async load (directory: string): Promise<Array<AnimatedTexture>> {
    console.log(`loading animated textures from ${directory}\n`);

    const imageFilePaths = FileUtils.readAllFiles(directory).filter((filePath) => filePath.indexOf('legacy') < 0 && filePath.endsWith('.gif'))
    const frameGroups = await Utils.loadAndGroupAnimation(undefined, imageFilePaths);
    const progress = new ConsoleProgressUpdater(frameGroups.length);

    return _.zip(imageFilePaths, frameGroups).map((pair: any) => {
      const image = new AnimatedTexture(pair[0].substring(directory.length + 1), pair[1])
      progress.next()
      return image;
    });
  }
}

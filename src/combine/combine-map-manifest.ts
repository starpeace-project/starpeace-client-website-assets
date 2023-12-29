import fs from 'fs-extra';
import path from 'path';

import MapImage from '../map/map-image.js';


async function writeMapImages (outputDir: string, mapImages: Array<MapImage>) {
  fs.mkdirsSync(outputDir);

  console.log(`found and loaded ${mapImages.length} maps\n`);
  for (const image of mapImages) {
    const bmpMapFile = path.join(outputDir, `map.${image.name.toLowerCase()}.texture.bmp`);
    fs.copySync(image.fullPath, bmpMapFile);
    console.log(` [OK] map ${image.fullPath} copied to ${bmpMapFile}`);
  }

  return [];
}

export default class CombineMapManifest {
  static async combine (mapsDir: string, targetDir: string) {
    const mapImages = await MapImage.load(mapsDir);
    await writeMapImages(targetDir, mapImages);
  }
}

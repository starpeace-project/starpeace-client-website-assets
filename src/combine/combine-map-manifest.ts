import fs from 'fs-extra';
import path from 'path';

import MapImage from '../map/map-image.js';


async function writeMapImages (outputDir: string, mapImages: Array<MapImage>) {
  fs.mkdirsSync(outputDir);

  console.log(`found and loaded ${mapImages.length} maps\n`);
  for (const image of mapImages) {
    const pngMapFile = path.join(outputDir, `map.${image.name.toLowerCase()}.texture.png`);
    fs.copySync(image.fullPath, pngMapFile);
    console.log(` [OK] map ${image.fullPath} copied to ${pngMapFile}`);
  }

  return [];
}

export default class CombineMapManifest {
  static async combine (mapsDir: string, targetDir: string) {
    const mapImages = await MapImage.load(mapsDir);
    await writeMapImages(targetDir, mapImages);
  }
}

import _ from 'lodash';
import fs from 'fs-extra';
import Jimp from 'jimp';
import path from 'path';
import ShelfPack from '@mapbox/shelf-pack';

import Texture from './texture.js';
import Utils from '../utils/utils.js';


export interface SpritesheetMetadata {
  key: string;
  texture: Jimp;
  w: number;
  h: number;
}

export default class Spritesheet {
  index: number;
  width: number;
  height: number;

  packedTextureData: any;

  constructor (index: number, width: number, height: number, packedTextureData: any) {
    this.index = index;
    this.width = width;
    this.height = height;
    this.packedTextureData = packedTextureData;

    console.log(` [OK] ${this.packedTextureData.length} textures packed into spritesheet`);
  }

  renderToTexture (): Jimp {
    const image = new Jimp(this.width, this.height);
    for (const data of this.packedTextureData) {
      const bitmap = data.texture.bitmap;
      for (let y = 0; y < bitmap.height; y++) {
        for (let x = 0; x < bitmap.width; x++) {
          const index = data.texture.getPixelIndex(x, y);
          image.setPixelColor(Jimp.rgbaToInt(bitmap.data[index + 0], bitmap.data[index + 1], bitmap.data[index + 2], bitmap.data[index + 3], () => {}), x + data.x, y + data.y);
        }
      }
    }
    return image;
  }

  saveTexture (outputDir: string, textureName: string): void {
    const textureFile = path.join(outputDir, textureName);
    fs.mkdirsSync(path.dirname(textureFile));
    console.log(` [OK] spritesheet texture saved to ${textureFile}`);
    this.renderToTexture().write(textureFile);
  }

  framesJson (): Record<string, any> {
    const json: Record<string, any> = {};
    for (const data of this.packedTextureData) {
      json[data.key] = {
        frame: {
          x: data.x,
          y: data.y,
          w: data.w,
          h: data.h
        }
      };
    }
    return json;
  }

  saveAtlas (outputDir: string, textureName: string, atlasName: string, debugMode: boolean) {
    const json = {
      meta: {
        image: `./${textureName}`
      },
      frames: this.framesJson()
    };

    const spritesheetAtlas = path.join(outputDir, atlasName);
    fs.mkdirsSync(path.dirname(spritesheetAtlas));
    fs.writeFileSync(spritesheetAtlas, debugMode ? JSON.stringify(json, null, 2) : JSON.stringify(json));
    console.log(` [OK] spritesheet atlas saved to ${spritesheetAtlas}`);
  }

  static dataFromTexture (texture: Texture, textureKeysUsed: Set<string>): SpritesheetMetadata | undefined {
    const spritesheetKey = texture.keyForSpritesheet;
    if (!spritesheetKey?.length || (!textureKeysUsed.size && textureKeysUsed.has(spritesheetKey))) {
      return undefined;
    }

    const imageForSheet = Utils.cloneImage(texture.image.bitmap, texture.filterMode);
    if (texture.targetWidth !== undefined && texture.width !== texture.targetWidth) {
      // FIXME: TODO: remove?
      // imageForSheet.resize(texture.targetWidth, Jimp.AUTO);
      if (Math.abs(texture.targetWidth - texture.width) > 10) {
        console.log(` [WARN] Texture might be wrong size ${texture.id} @ (${texture.width}x${texture.height}) to (${texture.targetWidth}x${texture.targetHeight})`);
      }
    }

    return {
      key: spritesheetKey,
      texture: imageForSheet,
      w: imageForSheet.bitmap.width,
      h: imageForSheet.bitmap.height
    };
  }

  static addGroupToSpritesheet (sprite: any, group: any): boolean {
    const addedBins = [];
    for (const texture of group) {
      const bin = sprite.packOne(texture.w, texture.h, texture.key);
      if (!!bin) {
        addedBins.push(bin);
      }
    }

    if (addedBins.length === group.length) {
      for (let index = 0; index < group.length; index++) {
        group[index].x = addedBins[index].x;
        group[index].y = addedBins[index].y;
      }
    }
    else {
      for (const bin of addedBins) {
        sprite.unref(bin);
      }
    }

    return addedBins.length === group.length;
  }

  static addSoloToSpritesheet (sprite: any, solo: any): boolean {
    const bin = sprite.packOne(solo.w, solo.h, solo.key);
    if (!!bin) {
      solo.x = bin.x;
      solo.y = bin.y;
    }
    return !!bin;
  }

  static packTextures (textures: Array<Texture | Array<Texture>>, textureKeysUsed: Set<string>, width: number, height: number): Array<Spritesheet> {
    const groupsToPack: Array<Array<any>> = [];
    const soloToPack = [];
    for (const texture of textures) {
      const isArray = Array.isArray(texture);

      if (isArray && texture.length > 1) {
        groupsToPack.push(texture.map((t) => Spritesheet.dataFromTexture(t, textureKeysUsed)).filter((val) => !!val));
      }
      else {
        const data = Spritesheet.dataFromTexture(isArray ? texture[0] : texture, textureKeysUsed);
        if (!!data) {
          soloToPack.push(data);
        }
      }
    }

    groupsToPack.sort((lhs, rhs) => rhs[0].h - lhs[0].h);
    soloToPack.sort((lhs, rhs) => rhs.h - lhs.h);

    const spritesheets = [];
    let currentData: Array<any> = [];
    let currentSheet = new ShelfPack(width, height, { autoResize: false });
    while (groupsToPack.length) {
      if (Spritesheet.addGroupToSpritesheet(currentSheet, groupsToPack[0])) {
        for (const data of (groupsToPack.shift() ?? [])) {
          currentData.push(data)
        }
      }
      else {
        while (soloToPack.length && Spritesheet.addSoloToSpritesheet(currentSheet, soloToPack[0])) {
          currentData.push(soloToPack.shift());
        }
        spritesheets.push(new Spritesheet(spritesheets.length, width, height, currentData));
        currentData = [];
        currentSheet = new ShelfPack(width, height, { autoResize: false });
      }
    }

    while (soloToPack.length) {
      if (Spritesheet.addSoloToSpritesheet(currentSheet, soloToPack[0])) {
        currentData.push(soloToPack.shift());
      }
      else {
        spritesheets.push(new Spritesheet(spritesheets.length, width, height, currentData));
        currentData = [];
        currentSheet = new ShelfPack(width, height, { autoResize: false });
      }
    }

    if (currentData.length) {
      spritesheets.push(new Spritesheet(spritesheets.length, width, height, currentData));
    }

    return spritesheets;
  }

}

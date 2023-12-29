import _ from 'lodash';
import fs from 'fs-extra';
import type Jimp from 'jimp';
import path from 'path';

import { BuildingImageDefinition } from '@starpeace/starpeace-assets-types';

import ConsoleProgressUpdater from '../utils/console-progress-updater.js';
import FileUtils from '../utils/file-utils.js';
import Utils from '../utils/utils.js';
import BuildingTexture from '../building/building-texture.js';
import Spritesheet from '../common/spritesheet.js';


const DEBUG_MODE = false;

const TILE_WIDTH = 64;

const OUTPUT_TEXTURE_WIDTH = 2048;
const OUTPUT_TEXTURE_HEIGHT = 2048;

interface Aggregatation {
  spritesheets: Array<Spritesheet>;
  frameIdsById: Record<string, Array<string>>;
}

function loadBuildings (buildingsDir: string): Array<BuildingImageDefinition> {
  console.log(` [OK] loading building configurations from ${buildingsDir}`);
  const imageDefinitions = FileUtils.parseToJson(buildingsDir, ['-image.json'], []).map(BuildingImageDefinition.fromJson);
  console.log(` [OK] found ${imageDefinitions.length} image definitions`);
  return imageDefinitions;
}

async function loadBuildingTextures (rootAssetsDir: string, imageDefinitions: Array<BuildingImageDefinition>): Promise<Record<string, BuildingTexture>> {
  const imagePaths = imageDefinitions.map((d) => d.imagePath);
  console.log(` [OK] loading ${imagePaths.length} building textures from ${rootAssetsDir}\n`)

  const frameGroups = await Utils.loadAndGroupAnimation(rootAssetsDir, imagePaths, true);
  const progress = new ConsoleProgressUpdater(frameGroups.length);
  const textures = _.zip(imagePaths, frameGroups).filter((pair) => pair[0] && pair[1]).map((pair) => {
    const image = new BuildingTexture(pair[0] as string, pair[1] as Array<[number, Jimp]>);
    progress.next();
    return image;
  });

  if (textures.length !== imagePaths.length) {
    console.log(` [ERROR] loaded ${textures.length} building textures but expected ${imagePaths.length}\n`);
    throw "loaded fewer building textures than expected";
  }

  const texturesByPath: Record<string, BuildingTexture> = {};
  for (const texture of textures) {
    texturesByPath[texture.filePath] = texture;
  }

  console.log(` [OK] loaded ${textures.length} building textures\n`);
  return texturesByPath;
}


function aggregate (imageDefinitions: Array<BuildingImageDefinition>, texturesByPath: Record<string, BuildingTexture>): Aggregatation {
  const frameTextureGroups = [];
  const frameIdsById: Record<string, Array<string>> = {};
  for (const definition of imageDefinitions) {
    const image = texturesByPath[definition.imagePath];
    if (!image) {
      console.log(` [ERROR] unable to find building image ${definition.imagePath}`);
      continue;
    }

    const frameTextures = image.getFrameTextures(definition.id, definition.tileWidth * TILE_WIDTH);
    frameIdsById[definition.id] = frameTextures.map((frame) => frame.id);

    frameTextureGroups.push(frameTextures);
    console.log(` [OK] ${definition.id} has ${frameTextures.length} frames`);
  }

  console.log();
  console.log(' [OK] packing textures into spritesheets');
  const spritesheets = Spritesheet.packTextures(frameTextureGroups, new Set(), OUTPUT_TEXTURE_WIDTH, OUTPUT_TEXTURE_HEIGHT);
  console.log(` [OK] ${spritesheets.length} spritesheets packed`);
  return {
    spritesheets,
    frameIdsById
  };
}

async function writeAssets (outputDir: string, imageDefinitions: Array<BuildingImageDefinition>, spritesheets: Array<Spritesheet>, frameIdsById: Record<string, Array<string>>): Promise<void> {
  const writePromises = [];

  const frameAtlas: Record<string, string> = {};
  const atlasNames = [];
  for (const spritesheet of spritesheets) {
    const textureName = `building.texture.${spritesheet.index}.png`;
    writePromises.push(spritesheet.saveTexture(outputDir, textureName));

    const atlasName = `building.atlas.${spritesheet.index}.json`;
    atlasNames.push(`./${atlasName}`);

    spritesheet.saveAtlas(outputDir, textureName, atlasName, DEBUG_MODE);

    for (const data of spritesheet.packedTextureData) {
      frameAtlas[data.key] = atlasName;
    }
  }
  console.log();

  const json = {
    atlas: atlasNames,
    images: imageDefinitions.map((image) => {
      return {
        id: image.id,
        w: image.tileWidth,
        h: image.tileHeight,
        hit_area: image.hitArea.map((coordinateList) => coordinateList.coordinates.map((coordinate) => {
          return { x: coordinate.x, y: coordinate.y };
        })),
        atlas: frameAtlas[frameIdsById[image.id][0]],
        frames: frameIdsById[image.id],
        effects: image.effects?.length ? image.effects.map((effect) => {
          return {
            type: effect.type,
            x: effect.x,
            y: effect.y
          };
        }) : undefined,
        sign: image.signPosition ? { x: image.signPosition.x, y: image.signPosition.y } : undefined
      };
    })
  };

  const metadataFile = path.join(outputDir, "building.metadata.json");
  fs.mkdirsSync(path.dirname(metadataFile));
  fs.writeFileSync(metadataFile, DEBUG_MODE ? JSON.stringify(json, null, 2) : JSON.stringify(json));
  console.log(` [OK] building metadata saved to ${metadataFile}`);

  await Promise.all(writePromises);
  process.stdout.write('\n');
}

export default class CombineBuildingManifest {
  static async combine (assetsDir: string, targetDir: string): Promise<void> {
    const buildingsDir = path.join(assetsDir, 'buildings');
    // const sealsDir = path.join(assetsDir, 'seals');

    const buildings: Array<BuildingImageDefinition> = loadBuildings(buildingsDir);
    const texturesByPath: Record<string, BuildingTexture> = await loadBuildingTextures(path.resolve(assetsDir, '..'), buildings);
    const { spritesheets, frameIdsById } = aggregate(buildings, texturesByPath);
    await writeAssets(targetDir, buildings, spritesheets, frameIdsById);
  }
}

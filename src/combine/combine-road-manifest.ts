import path from 'path';
import fs from 'fs-extra';
import { RoadDefinition, RoadImageDefinition } from '@starpeace/starpeace-assets-types'

import Spritesheet from '../common/spritesheet.js';
import Texture from '../common/texture.js';
import TextureManifest from '../common/texture-manifest.js';


const DEBUG_MODE = false;

const OUTPUT_TEXTURE_WIDTH = 512;
const OUTPUT_TEXTURE_HEIGHT = 512;

interface Aggregatation {
  imageDefinitions: Array<RoadImageDefinition>;
  spritesheets: Array<Spritesheet>;
  frameIdsById: Record<string, Array<string>>;
}

function loadRoadDefinitions (roadDir: string): RoadDefinition[] {
  console.log(`loading road definitions from ${roadDir}\n`);
  const definitions = JSON.parse(fs.readFileSync(path.join(roadDir, 'road-definition.json')).toString()).map(RoadDefinition.fromJson);
  console.log(`found and loaded ${definitions.length} road definitions\n`);
  return definitions;
}

function loadRoadImageDefinitions (roadDir: string): RoadImageDefinition[] {
  console.log(`loading road image definitions from ${roadDir}\n`);
  const definitions = JSON.parse(fs.readFileSync(path.join(roadDir, 'road-image.json')).toString()).map(RoadImageDefinition.fromJson);
  console.log(`found and loaded ${definitions.length} road image definitions\n`);
  return definitions;
}

async function loadRoadTextures (baseDir: string, roadDir: string): Promise<TextureManifest> {
  const textures = await Texture.load(path.join(roadDir, 'images'), baseDir);
  console.log(`found and loaded ${textures.length} road textures into manifest\n`);
  return new TextureManifest(textures);
}

function aggregate (definitions: RoadDefinition[], imageDefinitions: RoadImageDefinition[], textureManifest: TextureManifest): Aggregatation {
  const imageDefinitionById = Object.fromEntries(imageDefinitions.map(d => [d.id, d]));
  const frameTextureGroups = [];
  const frameIdsById: Record<string, Array<string>> = {};
  const includedImageDefinitions = [];
  for (const definition of definitions) {
    for (const imageIdByOrientation of Object.values(definition.imageCatalog)) {
      for (const imageId of Object.values(imageIdByOrientation)) {
        const imageDefinition = imageDefinitionById[imageId as string];
        if (!imageDefinition) {
          console.log(`unable to find road image definition ${imageId}`);
          continue;
        }

        const texture = textureManifest.byFilePath[imageDefinition.imagePath];
        if (!texture) {
          console.log(`unable to find road image ${imageDefinition.imagePath}`);
          continue;
        }

        includedImageDefinitions.push(imageDefinition);
        texture.id = imageId as string;
        frameIdsById[texture.id] = [texture.id];
        frameTextureGroups.push(texture.getFrameTextures(texture.id));
      }
    }
  }

  return {
    imageDefinitions: includedImageDefinitions,
    spritesheets: Spritesheet.packTextures(frameTextureGroups, new Set(), OUTPUT_TEXTURE_WIDTH, OUTPUT_TEXTURE_HEIGHT),
    frameIdsById: frameIdsById
  };
}

async function writeAssets (outputDir: string, imageDefinitions: RoadImageDefinition[], spritesheets: Array<Spritesheet>, frameIdsById: Record<string, Array<string>>): Promise<void> {
  const writePromises = [];

  const frameAtlas: Record<string, string> = {};
  const atlasNames = [];
  for (const spritesheet of spritesheets) {
    const textureName = `road.texture.${spritesheet.index}.png`;
    writePromises.push(spritesheet.saveTexture(outputDir, textureName));

    const atlasName = `road.atlas.${spritesheet.index}.json`;
    atlasNames.push(`./${atlasName}`);

    spritesheet.saveAtlas(outputDir, textureName, atlasName, DEBUG_MODE);
    for (const data of spritesheet.packedTextureData) {
      frameAtlas[data.key] = atlasName;
    }
  }

  const definitions: Record<string, any> = {};
  for (const definition of imageDefinitions) {
    definitions[definition.id] = {
      atlas: frameAtlas[frameIdsById[definition.id][0]],
      frames: frameIdsById[definition.id]
    };
  }

  const json = {
    atlas: atlasNames,
    road: definitions
  };

  const metadataFile = path.join(outputDir, "road.metadata.json");
  fs.mkdirsSync(path.dirname(metadataFile));
  fs.writeFileSync(metadataFile, DEBUG_MODE ? JSON.stringify(json, null, 2) : JSON.stringify(json));
  console.log(` [OK] road metadata saved to ${metadataFile}`);

  await Promise.all(writePromises);
  process.stdout.write('\n');
}

export default class CombineRoadManifest {
  static async combine (baseDir: string, roadDir: string, targetDir: string): Promise<void> {
    const definitions = loadRoadDefinitions(roadDir);
    const allImageDefinitions = loadRoadImageDefinitions(roadDir);
    const textureManifest = await loadRoadTextures(baseDir, roadDir);
    const { imageDefinitions, spritesheets, frameIdsById } = aggregate(definitions, allImageDefinitions, textureManifest);
    await writeAssets(targetDir, imageDefinitions, spritesheets, frameIdsById);
  }
}

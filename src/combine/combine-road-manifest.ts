import path from 'path';
import fs from 'fs-extra';
import { RoadDefinition } from '@starpeace/starpeace-assets-types'

import Manifest from '../common/manifest.js'
import Spritesheet from '../common/spritesheet.js';
import Texture from '../common/texture.js';
import TextureManifest from '../common/texture-manifest.js';


const DEBUG_MODE = false;

const OUTPUT_TEXTURE_WIDTH = 512;
const OUTPUT_TEXTURE_HEIGHT = 512;

interface Aggregatation {
  spritesheets: Array<Spritesheet>;
  frameIdsById: Record<string, Array<string>>;
}

function loadRoadManifest (roadDir: string): Manifest {
  console.log(`loading road definition manifest from ${roadDir}\n`);
  const definitions = JSON.parse(fs.readFileSync(path.join(roadDir, 'road-manifest.json')).toString()).map(RoadDefinition.fromJson);
  console.log(`found and loaded ${definitions.length} road definitions\n`);
  return new Manifest(definitions);
}

async function loadRoadTextures (roadDir: string): Promise<TextureManifest> {
  const textures = await Texture.load(roadDir);
  console.log(`found and loaded ${textures.length} road textures into manifest\n`);
  return new TextureManifest(textures);
}

function aggregate (definitionManifest: Manifest, textureManifest: TextureManifest): Aggregatation {
  const frameTextureGroups = [];
  const frameIdsById: Record<string, Array<string>> = {};
  for (const definition of definitionManifest.definitions) {
    const texture = textureManifest.byFilePath[definition.image];
    if (!texture) {
      console.log(`unable to find road image ${definition.image}`);
      continue;
    }

    texture.id = definition.id;
    frameIdsById[definition.id] = [texture.id];
    frameTextureGroups.push(texture.getFrameTextures(texture.id));
  }

  return {
    spritesheets: Spritesheet.packTextures(frameTextureGroups, new Set(), OUTPUT_TEXTURE_WIDTH, OUTPUT_TEXTURE_HEIGHT),
    frameIdsById: frameIdsById
  };
}

async function writeAssets (outputDir: string, definitionManifest: Manifest, spritesheets: Array<Spritesheet>, frameIdsById: Record<string, Array<string>>): Promise<void> {
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
  for (const definition of definitionManifest.definitions) {
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
  static async combine (roadDir: string, targetDir: string): Promise<void> {
    const definitionManifest = loadRoadManifest(roadDir);
    const textureManifest = await loadRoadTextures(roadDir);
    const { spritesheets, frameIdsById } = aggregate(definitionManifest, textureManifest);
    await writeAssets(targetDir, definitionManifest, spritesheets, frameIdsById);
  }
}

import path from 'path';
import fs from 'fs-extra';

import { SignDefinition } from '@starpeace/starpeace-assets-types';

import Manifest from '../common/manifest.js';
import TextureManifest from '../common/texture-manifest.js';
import AnimatedTexture from '../common/animated-texture.js';
import Spritesheet from '../common/spritesheet.js';


const DEBUG_MODE = false;

const OUTPUT_TEXTURE_WIDTH = 128;
const OUTPUT_TEXTURE_HEIGHT = 128;

export interface SignDefinitionMetadata {
  w: number;
  h: number;
  s_x: number;
  s_y: number;
  atlas: string;
  frames: Array<string>;
}

interface Aggregatation {
  spritesheets: Array<Spritesheet>;
  frameIdsById: Record<string, Array<string>>;
}

function loadSignManifest (signDir: string): Manifest {
  console.log(`loading sign definition manifest from ${signDir}\n`);
  const definitions = JSON.parse(fs.readFileSync(path.join(signDir, 'sign-manifest.json')).toString()).map(SignDefinition.fromJson);
  console.log(`found and loaded ${definitions.length} sign definitions\n`);
  return new Manifest(definitions);
}

async function loadSignTextures (signDir: string): Promise<TextureManifest> {
  const textures = await AnimatedTexture.load(signDir);
  console.log(`found and loaded ${textures.length} sign textures into manifest\n`);
  return new TextureManifest(textures);
}

function aggregate (signDefinitionManifest: Manifest, signTextureManifest: TextureManifest): Aggregatation {
  const frameTextureGroups = [];
  const frameIdsById: Record<string, Array<string>> = {};
  for (const definition of signDefinitionManifest.definitions) {
    const texture = signTextureManifest.byFilePath[definition.image];
    if (!texture) {
      console.log(`unable to find sign image ${definition.image}`);
      continue;
    }

    const frameTextures = texture.getFrameTextures(definition.id, definition.width, definition.height);
    frameIdsById[definition.id] = frameTextures.map((frame: any) => frame.id);

    frameTextureGroups.push(frameTextures);
    console.log(` [OK] ${definition.id} has ${frameTextures.length} frames`);
  }

  return {
    spritesheets: Spritesheet.packTextures(frameTextureGroups, new Set(), OUTPUT_TEXTURE_WIDTH, OUTPUT_TEXTURE_HEIGHT),
    frameIdsById: frameIdsById
  };
}

async function writeAssets (outputDir: string, signDefinitionManifest: Manifest, spritesheets: Array<Spritesheet>, frameIdsById: Record<string, Array<string>>): Promise<void> {
  const writePromises = [];

  const frameAtlas: Record<string, string> = {};
  const atlasNames: Array<string> = [];
  for (const spritesheet of spritesheets) {
    const textureName = `sign.texture.${spritesheet.index}.png`;
    writePromises.push(spritesheet.saveTexture(outputDir, textureName));

    const atlasName = `sign.atlas.${spritesheet.index}.json`;
    atlasNames.push(`./${atlasName}`);

    spritesheet.saveAtlas(outputDir, textureName, atlasName, DEBUG_MODE);

    for (const data of spritesheet.packedTextureData) {
      frameAtlas[data.key] = atlasName;
    }
  }

  const definitionById: Record<string, SignDefinitionMetadata> = {};
  for (const definition of signDefinitionManifest.definitions) {
    if (frameIdsById[definition.id]?.length) {
      definitionById[definition.id] = {
        w: definition.width,
        h: definition.height,
        s_x: definition.sourceX,
        s_y: definition.sourceY,
        atlas: frameAtlas[frameIdsById[definition.id][0]],
        frames: frameIdsById[definition.id]
      }
    }
  }

  const json = {
    atlas: atlasNames,
    signs: definitionById
  }

  const metadataFile = path.join(outputDir, 'sign.metadata.json');
  fs.mkdirsSync(path.dirname(metadataFile));
  fs.writeFileSync(metadataFile, DEBUG_MODE ? JSON.stringify(json, null, 2) : JSON.stringify(json));
  console.log(` [OK] sign metadata saved to ${metadataFile}`);

  await Promise.all(writePromises);
  process.stdout.write('\n');
}

export default class CombineSignManifest {
  static async combine (signDir: string, targetDir: string): Promise<any> {
    const signDefinitionManifest = loadSignManifest(signDir);
    const signTextureManifest = await loadSignTextures(signDir);
    const { spritesheets, frameIdsById } = aggregate(signDefinitionManifest, signTextureManifest);
    await writeAssets(targetDir, signDefinitionManifest, spritesheets, frameIdsById);
  }
}

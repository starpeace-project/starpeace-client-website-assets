import fs from 'fs-extra';
import path from 'path';

import { EffectDefinition } from '@starpeace/starpeace-assets-types'

import AnimatedTexture from '../common/animated-texture.js';
import Manifest from '../common/manifest.js'
import Spritesheet from '../common/spritesheet.js';
import TextureManifest from '../common/texture-manifest.js';

const DEBUG_MODE = false;

const OUTPUT_TEXTURE_WIDTH = 256;
const OUTPUT_TEXTURE_HEIGHT = 256;

interface Aggregatation {
  spritesheets: Array<Spritesheet>;
  frameIdsById: Record<string, Array<string>>;
}

function loadEffectManifest (effectDir: string): Manifest {
  console.log(`loading effect definition manifest from ${effectDir}\n`);
  const definitions = JSON.parse(fs.readFileSync(path.join(effectDir, 'effect-manifest.json')).toString()).map(EffectDefinition.fromJson);
  console.log(`found and loaded ${definitions.length} effect definitions\n`);
  return new Manifest(definitions);
}

async function loadEffectTextures (effectDir: string): Promise<TextureManifest> {
  const textures = await AnimatedTexture.load(effectDir);
  console.log(`found and loaded ${textures.length} effect textures into manifest\n`);
  return new TextureManifest(textures);
}

function aggregate (definitionManifest: Manifest, textureManifest: TextureManifest): Aggregatation {
  const frameTextureGroups = [];
  const frameIdsById: Record<string, Array<string>> = {};
  for (const definition of definitionManifest.definitions) {
    const texture = textureManifest.byFilePath[definition.image];
    if (!texture) {
      console.log(`unable to find effect image ${definition.image}`);
      continue;
    }

    const frameTextures = texture.getFrameTextures(definition.id, definition.width, definition.height);
    frameIdsById[definition.id] = frameTextures.map((frame) => frame.id);

    frameTextureGroups.push(frameTextures);
    console.log(` [OK] ${definition.id} has ${frameTextures.length} frames`);
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
    const textureName = `effect.texture.${spritesheet.index}.png`;
    writePromises.push(spritesheet.saveTexture(outputDir, textureName));

    const atlasName = `effect.atlas.${spritesheet.index}.json`;
    atlasNames.push(`./${atlasName}`);

    spritesheet.saveAtlas(outputDir, textureName, atlasName, DEBUG_MODE);

    for (const data of spritesheet.packedTextureData) {
      frameAtlas[data.key] = atlasName;
    }
  }

  const definitions: Record<string, any> = {};
  for (const definition of definitionManifest.definitions) {
    if (frameIdsById[definition.id]?.length) {
      definitions[definition.id] = {
        w: definition.width,
        h: definition.height,
        s_x: definition.sourceX,
        s_y: definition.sourceY,
        atlas: frameAtlas[frameIdsById[definition.id][0]],
        frames: frameIdsById[definition.id]
      };
    }
  }

  const json = {
    atlas: atlasNames,
    effects: definitions
  };

  const metadataFile = path.join(outputDir, 'effect.metadata.json')
  fs.mkdirsSync(path.dirname(metadataFile));
  fs.writeFileSync(metadataFile, DEBUG_MODE ? JSON.stringify(json, null, 2) : JSON.stringify(json));
  console.log(` [OK] effect metadata saved to ${metadataFile}`);

  await Promise.all(writePromises);
  process.stdout.write('\n');
}

export default class CombineEffectManifest {
  static async combine (effectDir: string, targetDir: string) {
    const definitionManifest = loadEffectManifest(effectDir);
    const textureManifest = await loadEffectTextures(effectDir);
    const { spritesheets, frameIdsById } = aggregate(definitionManifest, textureManifest);
    await writeAssets(targetDir, definitionManifest, spritesheets, frameIdsById);
  }
}

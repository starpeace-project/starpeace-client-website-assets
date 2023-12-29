import fs from 'fs-extra';
import path from 'path';

import { OverlayDefinition } from '@starpeace/starpeace-assets-types';
import Manifest from '../common/manifest.js';
import TextureManifest from '../common/texture-manifest.js';
import Texture from '../common/texture.js';
import Spritesheet from '../common/spritesheet.js';


const DEBUG_MODE = false;

const TILE_WIDTH = 64;
const TILE_HEIGHT = 32;

const OUTPUT_TEXTURE_WIDTH = 1024;
const OUTPUT_TEXTURE_HEIGHT = 1024;

interface Aggregatation {
  spritesheets: Array<Spritesheet>;
  frameIdsById: Record<string, Array<string>>;
}

function loadOverlayManifest (overlayDir: string): Manifest {
  console.log(`loading concrete definition manifest from ${overlayDir}\n`);
  const definitions = JSON.parse(fs.readFileSync(path.join(overlayDir, 'overlay-manifest.json')).toString()).map(OverlayDefinition.fromJson)
  console.log(`found and loaded ${definitions.length} concrete definitions\n`);
  return new Manifest(definitions);
}

async function loadOverlayTextures (overlayDir: string): Promise<TextureManifest> {
  const textures = await Texture.load(overlayDir);
  console.log(`found and loaded ${textures.length} effect textures into manifest\n`);
  return new TextureManifest(textures);
}

function aggregate (definitionManifest: Manifest, textureManifest: TextureManifest): Aggregatation {
  const frameTextureGroups = [];
  const frameIdsById: Record<string, Array<string>> = {};
  for (const definition of definitionManifest.definitions) {
    const texture = textureManifest.byFilePath[definition.image];
    if (!texture) {
      console.log(`unable to find overlay image ${definition.image}`);
      continue;
    }

    const frameTextures = texture.getFrameTextures(definition.id, definition.tileWidth * TILE_WIDTH, definition.tileHeight * TILE_HEIGHT)
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
    const textureName = `overlay.texture.${spritesheet.index}.png`;
    writePromises.push(spritesheet.saveTexture(outputDir, textureName));

    const atlasName = `overlay.atlas.${spritesheet.index}.json`;
    atlasNames.push(`./${atlasName}`);

    spritesheet.saveAtlas(outputDir, textureName, atlasName, DEBUG_MODE);

    for (const data of spritesheet.packedTextureData) {
      frameAtlas[data.key] = atlasName;
    }
  }

  const definitions: Record<string, any> = {};
  for (const definition of definitionManifest.definitions) {
    definitions[definition.id] = {
      w: definition.tileWidth,
      h: definition.tileHeight,
      atlas: frameAtlas[frameIdsById[definition.id][0]],
      frames: frameIdsById[definition.id]
    };
  }

  const json = {
    atlas: atlasNames,
    overlays: definitions
  };

  const metadataFile = path.join(outputDir, "overlay.metadata.json");
  fs.mkdirsSync(path.dirname(metadataFile));
  fs.writeFileSync(metadataFile, DEBUG_MODE ? JSON.stringify(json, null, 2) : JSON.stringify(json));
  console.log(` [OK] overlay metadata saved to ${metadataFile}`);

  await Promise.all(writePromises);
  process.stdout.write('\n');
}

export default class CombineOverlayManifest {
  static async combine (overlayDir: string, targetDir: string): Promise<void> {
    const definitionManifest = loadOverlayManifest(overlayDir);
    const textureManifest = await loadOverlayTextures(overlayDir);
    const { spritesheets, frameIdsById } = aggregate(definitionManifest, textureManifest);
    await writeAssets(targetDir, definitionManifest, spritesheets, frameIdsById);
  }
}

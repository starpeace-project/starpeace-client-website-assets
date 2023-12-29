import fs from 'fs-extra';
import path from 'path';

import { PlaneDefinition } from '@starpeace/starpeace-assets-types';

import AnimatedTexture from '../common/animated-texture.js';
import Manifest from '../common/manifest.js';
import Spritesheet from '../common/spritesheet.js';
import TextureManifest from '../common/texture-manifest.js';


const DEBUG_MODE = false;

const OUTPUT_TEXTURE_WIDTH = 512;
const OUTPUT_TEXTURE_HEIGHT = 512;

interface Aggregatation {
  spritesheets: Array<Spritesheet>;
  frameIdsById: Record<string, Array<string>>;
}

function loadPlaneManifest (planeDir: string): Manifest {
  console.log(` [OK] loading plane definition manifest from ${planeDir}`);
  const definitions = JSON.parse(fs.readFileSync(path.join(planeDir, 'plane-manifest.json')).toString()).map(PlaneDefinition.fromJson);
  console.log(` [OK] found and loaded ${definitions.length} plane definitions\n`);
  return new Manifest(definitions);
}

async function loadPlaneTextures (planeDir: string): Promise<TextureManifest> {
  const textures = await AnimatedTexture.load(planeDir);
  console.log(` [OK] found and loaded ${textures.length} plane textures into manifest\n`);
  return new TextureManifest(textures);
}

function aggregate (definitionManifest: Manifest, textureManifest: TextureManifest): Aggregatation {
  const frameTextureGroups = [];
  const frameIdsById: Record<string, Array<string>> = {};
  for (const definition of definitionManifest.definitions) {
    const texture = textureManifest.byFilePath[definition.image];
    if (!texture) {
      console.log(`unable to find plane image ${definition.image}`);
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

async function writeAssets (outputDir: string, definitionManifest: Manifest, spritesheets: Array<Spritesheet>, frameIdsById: Record<string, Array<string>>) {
  const writePromises = [];

  const frameAtlas: Record<string, string> = {};
  const atlasNames = [];
  for (const spritesheet of spritesheets) {
    const textureName = `plane.texture.${spritesheet.index}.png`;
    writePromises.push(spritesheet.saveTexture(outputDir, textureName));

    const atlasName = `plane.atlas.${spritesheet.index}.json`;
    atlasNames.push(`./${atlasName}`);

    spritesheet.saveAtlas(outputDir, textureName, atlasName, DEBUG_MODE)
    for (const data of spritesheet.packedTextureData) {
      frameAtlas[data.key] = atlasName;
    }
  }

  const definitions: Record<string, any> = {};
  for (const definition of definitionManifest.definitions) {
    definitions[definition.id] = {
      w: definition.width,
      h: definition.height,
      atlas: frameAtlas[frameIdsById[definition.id][0]],
      frames: frameIdsById[definition.id]
    }
  }

  const json = {
    atlas: atlasNames,
    planes: definitions
  };

  const metadataFile = path.join(outputDir, "plane.metadata.json");
  fs.mkdirsSync(path.dirname(metadataFile));
  fs.writeFileSync(metadataFile, DEBUG_MODE ? JSON.stringify(json, null, 2) : JSON.stringify(json));
  console.log();
  console.log(` [OK] plane metadata saved to ${metadataFile}`);

  await Promise.all(writePromises);
  process.stdout.write('\n');
}

export default class CombinePlaneManifest {
  static async combine (planeDir: string, targetDir: string): Promise<void> {
    const definitionManifest = loadPlaneManifest(planeDir);
    const textureManifest = await loadPlaneTextures(planeDir);
    const { spritesheets, frameIdsById } = aggregate(definitionManifest, textureManifest);
    await writeAssets(targetDir, definitionManifest, spritesheets, frameIdsById);
  }
}

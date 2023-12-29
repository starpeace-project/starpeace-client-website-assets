import fs from 'fs-extra';
import path from 'path';

import { ConcreteDefinition } from '@starpeace/starpeace-assets-types';

import Manifest from '../common/manifest.js';
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

function loadConcreteManifest (concreteDir: string): Manifest {
  console.log(`loading concrete definition manifest from ${concreteDir}\n`);
  const definitions = JSON.parse(fs.readFileSync(path.join(concreteDir, 'concrete-manifest.json')).toString()).map(ConcreteDefinition.fromJson);
  console.log(`found and loaded ${definitions.length} concrete definitions\n`);
  return new Manifest(definitions);
}

async function loadConcreteTextures (concreteDir: string): Promise<TextureManifest> {
  const textures = await Texture.load(concreteDir);
  console.log(`found and loaded ${textures.length} effect textures into manifest\n`);
  return new TextureManifest(textures);
}

function aggregate (definitionManifest: Manifest, textureManifest: TextureManifest): Aggregatation {
  const frameTextureGroups = [];
  const frameIdsById: Record<string, Array<string>> = {};
  for (const definition of definitionManifest.definitions) {
    const texture = textureManifest.byFilePath[definition.image];
    if (!texture) {
      console.log(`unable to find concrete image ${definition.image}`);
      continue;
    }

    texture.id = definition.id;
    const frameTextures = texture.getFrameTextures(definition.id);
    frameIdsById[definition.id] = frameTextures.map((frame) => frame.id);
    frameTextureGroups.push(frameTextures);
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
    const textureName = `concrete.texture.${spritesheet.index}.png`;
    writePromises.push(spritesheet.saveTexture(outputDir, textureName));

    const atlasName = `concrete.atlas.${spritesheet.index}.json`;
    atlasNames.push(`./${atlasName}`);

    spritesheet.saveAtlas(outputDir, textureName, atlasName, DEBUG_MODE);

    for (const data of spritesheet.packedTextureData) {
      frameAtlas[data.key] = atlasName;
    }
  }

  const definitionById: Record<string, any> = {};
  for (const definition of definitionManifest.definitions) {
    definitionById[definition.id] = {
      atlas: frameAtlas[frameIdsById[definition.id][0]],
      frames: frameIdsById[definition.id]
    }
  }

  const json = {
    atlas: atlasNames,
    concrete: definitionById
  };

  const metadataFile = path.join(outputDir, "concrete.metadata.json");
  fs.mkdirsSync(path.dirname(metadataFile));
  fs.writeFileSync(metadataFile, DEBUG_MODE ? JSON.stringify(json, null, 2) : JSON.stringify(json));
  console.log(` [OK] concrete metadata saved to ${metadataFile}`);

  await Promise.all(writePromises);
  process.stdout.write('\n');
}

export default class CombineConcreteManifest {
  static async combine (concreteDir: string, targetDir: string): Promise<void> {
    const definitionManifest = loadConcreteManifest(concreteDir);
    const textureManifest = await loadConcreteTextures(concreteDir);
    const { spritesheets, frameIdsById } = aggregate(definitionManifest, textureManifest);
    await writeAssets(targetDir, definitionManifest, spritesheets, frameIdsById);
  }
}

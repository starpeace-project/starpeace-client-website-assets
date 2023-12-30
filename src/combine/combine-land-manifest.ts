import fs from 'fs-extra';
import path from 'path';

import GroundDefinitionManifest from '../land/ground/ground-definition-manifest.js';
import GroundTextureManifest from '../land/ground/ground-texture-manifest.js';
import LandManifest from '../land/land-manifest.js';
import TreeDefinitionManifest from '../land/tree/tree-definition-manifest.js';
import TreeTextureManifest from '../land/tree/tree-texture-manifest.js';


const PLANET_TYPES = ['earth', 'alien1', 'alien2'];
const DEBUG_MODE = false;

function aggregateByPlanet (groundDefinitionManifest: GroundDefinitionManifest, groundTextureManifest: GroundTextureManifest, treeDefinitionManifest: TreeDefinitionManifest, treeTextureManifest: TreeTextureManifest): Array<LandManifest> {
  const landManifests = [];
  for (const planetType of PLANET_TYPES) {
    landManifests.push(LandManifest.merge(planetType,
        groundDefinitionManifest.defintions, groundTextureManifest.texturesByPlanetType[planetType] ?? [],
        treeDefinitionManifest.defintions, treeTextureManifest.texturesByPlanetType[planetType] ?? []))
  }
  return landManifests;
}

async function writeAssets (outputDir: string, landManifests: Array<LandManifest>) {
  const writePromises = [];
  for (const manifest of landManifests) {
    const atlasNames = [];

    for (const spritesheet of manifest.groundSpritesheets) {
      const textureName = `ground.${manifest.planetType}.texture.${spritesheet.index}.png`;
      writePromises.push(spritesheet.saveTexture(outputDir, textureName));

      const atlasName = `ground.${manifest.planetType}.atlas.${spritesheet.index}.json`;
      atlasNames.push(`./${atlasName}`);

      spritesheet.saveAtlas(outputDir, textureName, atlasName, DEBUG_MODE);
    }

    for (const spritesheet of manifest.treeSpritesheets) {
      const textureName = `tree.${manifest.planetType}.texture.${spritesheet.index}.png`;
      writePromises.push(spritesheet.saveTexture(outputDir, textureName));

      const atlasName = `tree.${manifest.planetType}.atlas.${spritesheet.index}.json`;
      atlasNames.push(`./${atlasName}`);

      spritesheet.saveAtlas(outputDir, textureName, atlasName, DEBUG_MODE);
    }

    const json = {
      planet_type: manifest.planetType,
      atlas: atlasNames,
      ground_definitions: manifest.groundByKey,
      tree_definitions: manifest.treeByKey
    };

    const metadataFile = path.join(outputDir, `land.${manifest.planetType}.metadata.json`);
    fs.mkdirsSync(path.dirname(metadataFile));
    fs.writeFileSync(metadataFile, DEBUG_MODE ? JSON.stringify(json, null, 2) : JSON.stringify(json));
    console.log(` [OK] land metadata for planet ${manifest.planetType} saved to ${metadataFile}`);
  }

  await Promise.all(writePromises);
  process.stdout.write('\n');
}

export default class CombineLandManifest {
  static async combine (landDir: string, targetDir: string): Promise<void> {
    const groundDefinition: GroundDefinitionManifest = GroundDefinitionManifest.load(landDir);
    const treeDefinition: TreeDefinitionManifest = TreeDefinitionManifest.load(landDir);
    const [groundTextureManifest, treeTextureManifest] = await Promise.all([GroundTextureManifest.load(landDir), TreeTextureManifest.load(landDir)]);
    const landManifests: Array<LandManifest> = aggregateByPlanet(groundDefinition, groundTextureManifest, treeDefinition, treeTextureManifest);
    await writeAssets(targetDir, landManifests);
  }
}

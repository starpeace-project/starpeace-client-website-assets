import fs from 'fs-extra';
import path from 'path';

import TreeDefinition from './tree-definition.js';

export default class TreeDefinitionManifest {
  allDefinitions: Array<TreeDefinition>;

  constructor (allDefinitions: Array<TreeDefinition>) {
    this.allDefinitions = allDefinitions;
  }

  forPlanetType (_planetType: string): Array<any> {
    const definitions = [];
    for (const definition of this.allDefinitions) {
      //if (definition.planetType === planetType) {
        definitions.push(definition);
      //}
    }
    return definitions;
  }

  static load (landDir: string): TreeDefinitionManifest {
    console.log(`loading tree definition manifest from ${landDir}\n`);

    const manifest = new TreeDefinitionManifest(JSON.parse(fs.readFileSync(path.join(landDir, 'tree-manifest.json')).toString()).map(TreeDefinition.fromJson));
    console.log(`found and loaded ${manifest.allDefinitions.length} tree definitions\n`);
    return manifest;
  }
}

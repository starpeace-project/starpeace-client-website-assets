import fs from 'fs-extra';
import path from 'path';

import TreeDefinition from './tree-definition.js';

export default class TreeDefinitionManifest {
  defintions: Array<TreeDefinition>;

  constructor (defintions: Array<TreeDefinition>) {
    this.defintions = defintions;
  }

  static load (landDir: string): TreeDefinitionManifest {
    console.log(`loading tree definition manifest from ${landDir}\n`);
    const manifest = new TreeDefinitionManifest(JSON.parse(fs.readFileSync(path.join(landDir, 'tree-manifest.json')).toString()).map(TreeDefinition.fromJson));
    console.log(`found and loaded ${manifest.defintions.length} tree definitions\n`);
    return manifest;
  }
}

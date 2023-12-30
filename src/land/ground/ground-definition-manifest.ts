import fs from 'fs-extra';
import path from 'path';

import GroundDefinition from './ground-definition.js';


export default class GroundDefinitionManifest {
  defintions: Array<GroundDefinition>;

  constructor (defintions: Array<GroundDefinition>) {
    this.defintions = defintions;
  }

  static load (landDir: string): GroundDefinitionManifest {
    console.log(`loading ground definition manifest from ${landDir}\n`);
    const definitions = JSON.parse(fs.readFileSync(path.join(landDir, 'ground-manifest.json')).toString()).map(GroundDefinition.fromJson);
    console.log(`found and loaded ${definitions.length} ground definitions\n`);
    return new GroundDefinitionManifest(definitions);
  }
}

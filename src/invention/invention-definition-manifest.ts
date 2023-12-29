import fs from 'fs';

import InventionDefinition from './invention-definition.js';
import FileUtils from '../utils/file-utils.js';

export default class InventionDefinitionManifest {
  allDefinitions: Array<any>;

  constructor (allDefinitions: Array<any>) {
    this.allDefinitions = allDefinitions;
  }

  static async load (inventionsDir: string): Promise<InventionDefinitionManifest> {
    console.log(` [OK] loading invention manifests from ${inventionsDir}\n`);

    const definitionsById: Record<string, any> = {};
    const jsonFilePaths = FileUtils.readAllFiles(inventionsDir, (filePath) => filePath.endsWith('.json'));
    for (const jsonPath of jsonFilePaths) {
      const inventions = JSON.parse(fs.readFileSync(jsonPath).toString());
      for (const [key, invention] of Object.entries(inventions)) {
        definitionsById[key] = InventionDefinition.fromJson(invention);
      }
    }

    console.log(` [OK] found and loaded ${Object.keys(definitionsById).length} invention definitions\n`);
    return new InventionDefinitionManifest(Object.values(definitionsById));
  }
}

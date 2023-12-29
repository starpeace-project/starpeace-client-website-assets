import _ from 'lodash';
import fs from 'fs';

import FileUtils from '../utils/file-utils.js';

export default class SealManaifest {
  allDefinitions: Array<any>;

  constructor (allDefinitions: Array<any>) {
    this.allDefinitions = allDefinitions;
  }

  static async load (sealDir: string): Promise<Record<string, any>> {
    console.log(`loading seal definitions from ${sealDir}\n`);

    const sealFilePaths = FileUtils.readAllFiles(sealDir).filter((filePath) => filePath.endsWith('.json'));
    const definitionsById: Record<string, any> = {}
    for (const path of sealFilePaths) {
      const definition = JSON.parse(fs.readFileSync(path).toString());
      definition.buildings_by_id = {}
      for (const buildingId of definition.buildings) {
        definition.buildings_by_id[buildingId] = true;
      }
      definitionsById[definition.id] = definition;
    }

    console.log(`found and loaded ${Object.keys(definitionsById)} seal definitions\n`);
    return definitionsById;
  }
}

import fs from 'fs-extra';
import path from 'path';

import GroundDefinition from './ground-definition.js';


export default class GroundDefinitionManifest {
  allTiles: Array<GroundDefinition>;

  tilesById: Record<string, Array<GroundDefinition>> = {};
  tilesByColor: Record<string, Array<GroundDefinition>> = {};
  tilesByKey: Record<string, Array<GroundDefinition>> = {};

  constructor (allTiles: Array<GroundDefinition>) {
    this.allTiles = allTiles;
    for (const tile of this.allTiles) {
      this.tilesById[tile.id] ||= [];
      this.tilesById[tile.id].push(tile);
      this.tilesByColor[tile.mapColor] ||= [];
      this.tilesByColor[tile.mapColor].push(tile);
      this.tilesByKey[tile.key] ||= [];
      this.tilesByKey[tile.key].push(tile);
    }
  }

  forPlanetType (planetType: string): Array<GroundDefinition> {
    const definitions = [];
    for (const tile of this.allTiles) {
      if (tile.planetType === planetType) {
        definitions.push(tile);
      }
    }
    return definitions;
  }

  static load (landDir: string): GroundDefinitionManifest {
    console.log(`loading ground definition manifest from ${landDir}\n`);

    const manifest = new GroundDefinitionManifest(JSON.parse(fs.readFileSync(path.join(landDir, 'ground-manifest.json')).toString()).map(GroundDefinition.fromJson))
    console.log(`found and loaded ${manifest.allTiles.length} ground definitions\n`);
    return manifest;
  }
}

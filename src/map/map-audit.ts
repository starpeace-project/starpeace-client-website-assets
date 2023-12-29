import _ from 'lodash';

import MapImage from './map-image.js';
import ConsoleProgressUpdater from '../utils/console-progress-updater.js';

export default class MapAudit {
  metadataManifest: any;
  maps: Array<MapImage>;

  tileCountsByColor: Record<string, number>;
  missingColors: Record<string, number>;

  progress: ConsoleProgressUpdater;

  constructor (metadataManifest: any, maps: Array<any>) {
    this.metadataManifest = metadataManifest;
    this.maps = maps;

    this.tileCountsByColor = {};
    for (const tile of this.metadataManifest.all_tiles) {
      this.tileCountsByColor[tile.map_color] = 0;
    }
    this.missingColors = {};

    this.progress = new ConsoleProgressUpdater(this.maps.length);
    for (const map of this.maps) {
      for (const [color, count] of Object.entries(map.colors())) {
        if (this.tileCountsByColor[color] !== undefined) {
          this.tileCountsByColor[color] += count;
        }
        else {
          this.missingColors[color] ||= 0;
          this.missingColors[color] += count;
        }
      }
      this.progress.next();
    }
  }

  sorted_missing_colors (): Array<[string, number]> {
    return Object.entries(this.missingColors).sort((lhs, rhs) => rhs[1] - lhs[1]);
  }

  unused_tile_colors () {
    return Object.entries(this.tileCountsByColor).filter(([_color, count]) => count === 0).map(([color, _count]) => color);
  }

  static async audit (metadataManifest: any, maps: Array<MapImage>): Promise<MapAudit> {
    console.log('starting analysis and audit of maps\n');
    return new MapAudit(metadataManifest, maps);
  }

}

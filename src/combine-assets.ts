import _ from 'lodash';
import path from 'path';
import fs from 'fs-extra';

import CombineBuildingManifest from './combine/combine-building-manifest.js';
import CombineConcreteManifest from './combine/combine-concrete-manifest.js';
import CombineEffectManifest from './combine/combine-effect-manifest.js';
import CombineLandManifest from './combine/combine-land-manifest.js';
import CombineMapManifest from './combine/combine-map-manifest.js';
import CombineOverlayManifest from './combine/combine-overlay-manifest.js';
import CombinePlaneManifest from './combine/combine-plane-manifest.js';
import CombineRoadManifest from './combine/combine-road-manifest.js';
import CombineStaticMusic from './combine/combine-static-music.js';
import CombineStaticNews from './combine/combine-static-news.js';
import CombineSignManifest from './combine/combine-sign-manifest.js';

import Utils from './utils/utils.js';

const SKIP = {
  BUILDINGS: false,
  CONCRETE: false,
  EFFECTS: false,
  LAND: false,
  MAPS: false,
  MUSIC: false,
  NEWS: false,
  OVERLAYS: false,
  PLANES: false,
  ROADS: false,
  SIGNS: false,
  PLANET_ANIMATIONS: false
};


console.log("\n===============================================================================\n");
console.log(" combine-assets.js - https://www.starpeace.io\n");
console.log(" combine game textures and generate summary metadata for use with game client\n");
console.log(" see README.md for more details");
console.log("\n===============================================================================\n");


const root = process.cwd();
const assetsDir = path.join(root, process.argv[2]);
const targetDir = path.join(root, process.argv[3]);

const uniqueHash = Utils.randomMd5()
const targetWithVersion = path.join(targetDir, uniqueHash)

fs.mkdirsSync(targetWithVersion)

console.log(`input directory: ${assetsDir}`);
console.log(`output directory: ${targetDir}`);

console.log("\n-------------------------------------------------------------------------------\n");

const baseDir = path.dirname(assetsDir);
const soundDir = path.join(assetsDir, 'sounds');
const concreteDir = path.join(assetsDir, 'concrete');
const effectsDir = path.join(assetsDir, 'effects');
const landDir = path.join(assetsDir, 'land');
const mapsDir = path.join(assetsDir, 'maps');
const musicDir = path.join(soundDir, 'music');
const newsDir = path.join(assetsDir, 'news');
const overlaysDir = path.join(assetsDir, 'overlays');
const planesDir = path.join(assetsDir, 'planes');
const roadsDir = path.join(assetsDir, 'roads');
const signsDir = path.join(assetsDir, 'signs');


const jobs = [];
if (!SKIP.BUILDINGS) jobs.push(CombineBuildingManifest.combine(assetsDir, targetWithVersion));
if (!SKIP.CONCRETE) jobs.push(CombineConcreteManifest.combine(concreteDir, targetWithVersion));
if (!SKIP.EFFECTS) jobs.push(CombineEffectManifest.combine(effectsDir, targetWithVersion));
if (!SKIP.LAND) jobs.push(CombineLandManifest.combine(landDir, targetWithVersion));
if (!SKIP.MAPS) jobs.push(CombineMapManifest.combine(mapsDir, targetWithVersion));
if (!SKIP.MUSIC) jobs.push(CombineStaticMusic.combine(musicDir, targetWithVersion));
if (!SKIP.NEWS) jobs.push(CombineStaticNews.combine(newsDir, targetWithVersion));
if (!SKIP.OVERLAYS) jobs.push(CombineOverlayManifest.combine(overlaysDir, targetWithVersion));
if (!SKIP.PLANES) jobs.push(CombinePlaneManifest.combine(planesDir, targetWithVersion));
if (!SKIP.ROADS) jobs.push(CombineRoadManifest.combine(baseDir, roadsDir, targetWithVersion));
if (!SKIP.SIGNS) jobs.push(CombineSignManifest.combine(signsDir, targetWithVersion));

Promise.all(jobs)
  .then(() => {
    console.log("\nfinished successfully, thank you for using combine-assets.js!");
  })
  .catch((error) => {
    console.log("there was an error during execution:");
    console.log(error);
    process.exit(1)
  });

import Spritesheet from '../common/spritesheet.js';
import GroundDefinition from './ground/ground-definition.js';
import GroundTexture from './ground/ground-texture.js';
import TreeDefinition from './tree/tree-definition.js';
import TreeTexture from './tree/tree-texture.js';


// FIXME: TODO: add other orientations
const ORIENTATIONS = new Set(['0deg']);

export default class LandManifest {
  planetType: string;
  groundMetadata: Record<string, Record<string, GroundTexture>>;
  groundSpritesheets: Array<Spritesheet>;
  treeMetadata: Record<string, Record<string, TreeTexture>>;
  treeSpritesheets: Array<Spritesheet>;

  constructor (planetType: string, groundMetadata: Record<string, Record<string, GroundTexture>>, groundSpritesheets: Array<Spritesheet>, treeMetadata: Record<string, Record<string, TreeTexture>>, treeSpritesheets: Array<Spritesheet>) {
    this.planetType = planetType;
    this.groundMetadata = groundMetadata;
    this.groundSpritesheets = groundSpritesheets;
    this.treeMetadata = treeMetadata;
    this.treeSpritesheets = treeSpritesheets;
  }

  static merge (planetType: string, groundDefinitions: Array<GroundDefinition>, groundTextures: Array<GroundTexture>, treeDefinitions: Array<TreeDefinition>, treeTextures: Array<TreeTexture>) {
    const groundTextureByKeySeason: Record<string, Record<string, any>> = {};
    for (const texture of groundTextures) {
      const textureKey = texture.idealFileName;
      groundTextureByKeySeason[textureKey] ||= {};
      groundTextureByKeySeason[textureKey][texture.season] = texture;
    }

    const treeTextureByKeySeason: Record<string, Record<string, TreeTexture>> = {};
    for (const texture of treeTextures) {
      const textureKey = texture.idealFileName;
      treeTextureByKeySeason[textureKey] ||= {};
      treeTextureByKeySeason[textureKey][texture.season] = texture;
    }

    const groundMetadataByKey: Record<string, Record<string, GroundTexture>> = {};
    const groundTextureKeys = new Set<string>();
    for (const tile of groundDefinitions) {
      for (const [orientation, typeTextureKey] of Object.entries(tile.texturesByOrientationType)) {
        if (!ORIENTATIONS.has(orientation)) {
          continue;
        }
        const groundMetadata = groundMetadataByKey[tile.key] = tile.toCompiledJson();

        for (const season of Object.keys(groundTextureByKeySeason[typeTextureKey.key] || {})) {
          if (tile.seasons.has(season)) {
            const spritesheetKey = groundTextureByKeySeason[typeTextureKey.key][season].keyForSpritesheet;
            groundMetadata.textures ||= {};
            groundMetadata.textures[orientation] ||= {};
            groundMetadata.textures[orientation][season] ||= {};
            groundMetadata.textures[orientation][season][typeTextureKey.type] = spritesheetKey;
            groundTextureKeys.add(spritesheetKey);
          }
        }
      }
    }

    const treeMetadataByKey: Record<string, any> = {};
    const treeTextureKeys = new Set<string>();
    for (const definition of treeDefinitions) {
      const treeMetadata = treeMetadataByKey[definition.key] = definition.toCompiledJson();

      for (const season of Object.keys(treeTextureByKeySeason[definition.key] ?? {})) {
        if (definition.seasons.has(season)) {
          const spritesheetKey = treeTextureByKeySeason[definition.key][season].keyForSpritesheet;
          treeMetadata.textures ||= {};
          treeMetadata.textures[season] = spritesheetKey;
          treeTextureKeys.add(spritesheetKey);
        }
      }
    }

    const groundSpritesheets = Spritesheet.packTextures(groundTextures, groundTextureKeys, 2048, 2048);
    const treeSpritesheets = Spritesheet.packTextures(treeTextures, treeTextureKeys, 768, 768);

    return new LandManifest(planetType, groundMetadataByKey, groundSpritesheets, treeMetadataByKey, treeSpritesheets);
  }
}

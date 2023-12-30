import Spritesheet from '../common/spritesheet.js';
import GroundDefinition, { GroundDefitionJson } from './ground/ground-definition.js';
import GroundTexture from './ground/ground-texture.js';
import TreeDefinition, { TreeDefinitionJson } from './tree/tree-definition.js';
import TreeTexture from './tree/tree-texture.js';


// FIXME: TODO: add other orientations
const ORIENTATIONS = new Set(['0deg']);

export default class LandManifest {
  planetType: string;
  groundByKey: Record<string, GroundDefitionJson>;
  groundSpritesheets: Array<Spritesheet>;
  treeByKey: Record<string, TreeDefinitionJson>;
  treeSpritesheets: Array<Spritesheet>;

  constructor (planetType: string, groundByKey: Record<string, GroundDefitionJson>, groundSpritesheets: Array<Spritesheet>, treeByKey: Record<string, TreeDefinitionJson>, treeSpritesheets: Array<Spritesheet>) {
    this.planetType = planetType;
    this.groundByKey = groundByKey;
    this.groundSpritesheets = groundSpritesheets;
    this.treeByKey = treeByKey;
    this.treeSpritesheets = treeSpritesheets;
  }

  static merge (planetType: string, groundDefinitions: Array<GroundDefinition>, groundTextures: Array<GroundTexture>, treeDefinitions: Array<TreeDefinition>, treeTextures: Array<TreeTexture>) {
    const groundTextureByFileKeySeason: Record<string, Record<string, GroundTexture>> = {};
    for (const texture of groundTextures) {
      groundTextureByFileKeySeason[texture.fileKey] ||= {};
      groundTextureByFileKeySeason[texture.fileKey][texture.season] = texture;
    }

    const groundMetadataByKey: Record<string, GroundDefitionJson> = {};
    const groundTextureKeys = new Set<string>();
    for (const definition of groundDefinitions) {
      const groundMetadata = definition.toCompiledJson();
      for (const [orientation, textureInfo] of Object.entries(definition.textureByOrientation)) {
        if (!ORIENTATIONS.has(orientation) || !groundTextureByFileKeySeason[textureInfo.key]) {
          continue;
        }

        for (const [season, texture] of Object.entries(groundTextureByFileKeySeason[textureInfo.key])) {
          groundMetadata.textures[orientation] ||= {};
          groundMetadata.textures[orientation][season] ||= {};
          groundMetadata.textures[orientation][season][textureInfo.type] = texture.keyForSpritesheet;
          groundTextureKeys.add(texture.keyForSpritesheet);
        }
      }

      if (Object.keys(groundMetadata.textures).length > 0) {
        groundMetadataByKey[definition.textureKey] = groundMetadata;
      }
    }

    const treeTextureByFileKeySeason: Record<string, Record<string, TreeTexture>> = {};
    for (const texture of treeTextures) {
      treeTextureByFileKeySeason[texture.fileKey] ||= {};
      treeTextureByFileKeySeason[texture.fileKey][texture.season] = texture;
    }

    const treeMetadataByKey: Record<string, TreeDefinitionJson> = {};
    const treeTextureKeys = new Set<string>();
    for (const definition of treeDefinitions) {
      const treeMetadata = definition.toCompiledJson();
      for (const [season, texture] of Object.entries(treeTextureByFileKeySeason[definition.key] ?? {})) {
        treeMetadata.textures[season] = texture.keyForSpritesheet;
        treeTextureKeys.add(texture.keyForSpritesheet);
      }

      if (Object.keys(treeMetadata.textures).length > 0) {
        treeMetadataByKey[definition.textureKey] = treeMetadata;
      }
    }

    const groundSpritesheets = Spritesheet.packTextures(groundTextures, groundTextureKeys, 2048, 2048);
    const treeSpritesheets = Spritesheet.packTextures(treeTextures, treeTextureKeys, 768, 768);

    return new LandManifest(planetType, groundMetadataByKey, groundSpritesheets, treeMetadataByKey, treeSpritesheets);
  }
}

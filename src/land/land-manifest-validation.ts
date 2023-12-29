import _ from 'lodash';
import Jimp from 'jimp';

import GroundDefinitionManifest from "./ground/ground-definition-manifest.js";
import GroundTextureManifest from "./ground/ground-texture-manifest.js";
import GroundTexture from "./ground/ground-texture.js";

class Validations {
  safeCount: number = 0;
  warningCount: number = 0;
  tiles: Array<any> = [];
}

export default class LandManifestValidation {
  warnings: Record<string, Record<string, Validations>>;
  textureWarnings: Record<string, Array<string>>;

  constructor (metadataManifest: GroundDefinitionManifest, textureManifest: GroundTextureManifest) {
    this.warnings = {
      metadata: {
        valid_attributes: new Validations(),
        missing_texture_keys: new Validations()
      },
      texture: {
        valid_attributes: new Validations(),
        rename_key: new Validations(),
        no_metadata: new Validations(),
        duplicate_hash: new Validations(),
      }
    };

    this.textureWarnings = {
      matching_land_textures: [],
      missing_land_textures: [],
      unbound_land_textures: []
    };

    const metadataTextureKeys = new Set<string>();
    for (const tile of metadataManifest.allTiles) {
      for (const key of tile.textureKeys) {
        metadataTextureKeys.add(key);
      }

      if (tile.valid) {
        this.warnings.metadata.valid_attributes.safeCount += 1;
      }
      else {
        this.warnings.metadata.valid_attributes.warningCount += 1;
        this.warnings.metadata.valid_attributes.tiles.push(tile);
      }

      if (tile.missingTextureKeys.length) {
        this.warnings.metadata.missing_texture_keys.warningCount += 1;
      }
      else {
        this.warnings.metadata.missing_texture_keys.safeCount += 1;
      }
    }

    const foundTextureKeys = new Set<string>();
    const hashTile: Record<string, GroundTexture> = {};
    for (const texture of textureManifest.allTextures) {
      const key = texture.idealFileName;
      foundTextureKeys.add(key);

      if (texture.hasValidAttributes) {
        this.warnings.texture.valid_attributes.safeCount += 1;
        if (texture.hasValidFileName) {
          this.warnings.texture.rename_key.safeCount += 1;
        }
        else {
          this.warnings.texture.rename_key.warningCount += 1;
          this.warnings.texture.rename_key.tiles.push(texture);
        }
      }
      else {
        this.warnings.texture.valid_attributes.warningCount += 1;
        this.warnings.texture.valid_attributes.tiles.push(texture);
      }

      const existing_texture = hashTile[texture.hash];
      const existing_texture_key = existing_texture?.idealFileName;
      if (existing_texture && existing_texture_key != key) {
        const diff = Jimp.distance(existing_texture.image, texture.image);
        if (diff == 0) {
          this.warnings.texture.duplicate_hash.warningCount += 1;
        }
        else {
          this.warnings.texture.duplicate_hash.safeCount += 1
        }
      }
      else {
        this.warnings.texture.duplicate_hash.safeCount += 1
      }

      hashTile[texture.hash] = texture;
    }

    this.textureWarnings.matching_land_textures = _.intersection(Array.from(metadataTextureKeys), Array.from(foundTextureKeys));
    this.textureWarnings.missing_land_textures = _.difference(Array.from(metadataTextureKeys), Array.from(foundTextureKeys));
    this.textureWarnings.unbound_land_textures = _.difference(Array.from(foundTextureKeys), Array.from(metadataTextureKeys));
  }
}

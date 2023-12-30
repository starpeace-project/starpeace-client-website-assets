import LandAttributes from "../land-attributes.js";

export interface TreeDefinitionJson {
  zone: string;
  variant: number;

  // season -> key
  textures: Record<string, string>;
}

export default class TreeDefinition {
  zone: string;
  variant: number;
  key: string;

  constructor (zone: string, variant: number, key: string) {
    this.zone = zone;
    this.variant = variant;
    this.key = key;
  }

  get textureKey (): string {
    return `tree.${this.zone}.${this.variant.toString().padStart(2, '0')}`;
  }

  toJson (): any {
    return {
      zone: this.zone,
      variant: this.variant,
      key: this.key,
    };
  }

  toCompiledJson (): TreeDefinitionJson {
    return {
      zone: this.zone,
      variant: this.variant,
      textures: {}
    };
  }

  static fromJson (json: any): TreeDefinition {
    return new TreeDefinition(
      json.zone ?? LandAttributes.ZONES.other,
      json.variant ?? Number.NaN,
      json.key
    );
  }
}

import LandAttributes from "../land-attributes.js";

export default class TreeDefinition {
  id: number = Number.NaN;
  zone: string = LandAttributes.ZONES.other;
  variant: number = Number.NaN;

  get key (): string {
    return `tree.${this.zone}.${this.variant.toString().padStart(2, '0')}`;
  }

  toJson (): any {
    return {
      zone: this.zone,
      key: this.key,
      variant: this.variant,
    };
  }

  toCompiledJson (): any {
    return {
      zone: this.zone,
      variant: this.variant
    };
  }

  static fromJson (json: any): TreeDefinition {
    const tile = new TreeDefinition();
    tile.id = json.id ?? Number.NaN;
    tile.zone = json.zone ?? LandAttributes.ZONES.other;
    tile.variant = json.variant ?? Number.NaN;
    return tile;
  }
}

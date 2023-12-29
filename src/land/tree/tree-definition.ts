import LandAttributes from "../land-attributes.js";

export default class TreeDefinition {
  id: number = Number.NaN;
  zone: string = LandAttributes.ZONES.other;
  variant: number = Number.NaN;
  seasons: Set<string> = new Set();

  get key (): string {
    return `tree.${this.zone}.${this.variant.toString().padStart(2, '0')}`;
  }

  toJson (): any {
    return {
      id: this.id,
      zone: this.zone,
      key: this.key,
      variant: this.variant,
      seasons: Array.from(this.seasons)
    };
  }

  toCompiledJson (): any {
    return {
      id: this.id,
      zone: this.zone
    };
  }

  static fromJson (json: any): TreeDefinition {
    const tile = new TreeDefinition();
    tile.id = json.id ?? Number.NaN;
    tile.zone = json.zone ?? LandAttributes.ZONES.other;
    tile.variant = json.variant ?? Number.NaN;
    tile.seasons = new Set(json.seasons ?? [LandAttributes.SEASONS.winter, LandAttributes.SEASONS.spring, LandAttributes.SEASONS.summer, LandAttributes.SEASONS.fall]);
    return tile;
  }
}

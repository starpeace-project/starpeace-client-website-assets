
export default class InventionDefinition {
  id: string;
  category: string;
  industryType: string;
  dependsOn: Array<string>;
  name: string;
  description: string;
  properties: Record<string, any>;

  constructor (id: string, category: string, industryType: string, dependsOn: Array<any>, name: string, description: string, properties: Record<string, any>) {
    this.id = id;
    this.category = category;
    this.industryType = industryType;
    this.dependsOn = dependsOn;
    this.name = name;
    this.description = description;
    this.properties = properties;
  }

  get nameKey (): string {
    return `invention.${this.id}.name`;
  }
  get descriptionKey (): string {
    return `invention.${this.id}.description`;
  }

  toCompiledJson (): any {
    return {
      id: this.id,
      category: this.category,
      industry_type: this.industryType,
      depends_on: this.dependsOn,
      name_key: this.nameKey,
      description_key: this.descriptionKey,
      properties: this.properties
    };
  }

  static fromJson (json: any): InventionDefinition {
    return new InventionDefinition(json.id, json.category, json.industry_type, json.depends_on, json.name, json.description, json.properties);
  }
}

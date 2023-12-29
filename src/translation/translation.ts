import _ from 'lodash';

const LANGUAGE_CODES: Record<string, boolean> = {
  'EN': true,
  'ES': true,
  'DE': true,
  'FR': true,
  'IT': true,
  'PT': true
};

export default class Translation {
  id: string;
  textByLanguage: Record<string, string>;

  constructor (id: string, textByLanguage: string | Record<string, string>) {
    this.id = id;
    if (typeof textByLanguage === 'string') {
      this.textByLanguage = {
        'EN': textByLanguage
      }
    }
    else {
      this.textByLanguage = {};
      for (const [language, text] of Object.entries(textByLanguage)) {
        if (LANGUAGE_CODES[language.toUpperCase()]) {
          this.textByLanguage[language.toUpperCase()] = text;
        }
      }
    }
  }

  toJson (): any {
    return {
      id: this.id,
      text: Object.entries(this.textByLanguage).map(([code, text]) => {
        return {
          code: code,
          value: text
        };
      })
    }
  }

  static forLanguages (id: string, languageCodesToText: Record<string, string>): Translation {
    return new Translation(id, languageCodesToText);
  }

  static forEnglish (id: string, text: string): Translation {
    return new Translation(id, { 'EN': text });
  }

}

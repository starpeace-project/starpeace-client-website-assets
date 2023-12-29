import fs from 'fs-extra';
import path from 'path';

const NEWS_LANGUAGES = ['de', 'en', 'es', 'fr', 'it', 'pt'];

export default class CombineStaticNews {
  static combine (newsDir: string, targetDir: string): Array<string> {
    fs.mkdirsSync(targetDir);

    for (const language of NEWS_LANGUAGES) {
      const sourceNewsFile = path.join(newsDir, `news.static.${language}.json`);
      const targetNewsFile = path.join(targetDir, `news.static.${language}.json`);
      fs.copySync(sourceNewsFile, targetNewsFile)
      console.log(` [OK] static news ${sourceNewsFile} copied to ${targetNewsFile}`);
    }

    return [];
  }
}

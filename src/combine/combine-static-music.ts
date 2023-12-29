import fs from 'fs-extra';
import path from 'path';

export default class CombineStaticMusic {
  static async combine (musicDir: string, targetDir: string): Promise<Array<string>> {
    fs.mkdirsSync(targetDir);

    const files = ['inmap1.mp3', 'inmap2.mp3', 'inmap3.mp3', 'inmap4.mp3', 'intro.mp3'];

    for (const file of files) {
      const sourceFile = path.join(musicDir, file)
      const targetFile = path.join(targetDir, `music.${file}`);
      fs.copySync(sourceFile, targetFile);
      console.log(` [OK] static music ${sourceFile} copied to ${targetFile}`);
    }

    return [];
  }
}

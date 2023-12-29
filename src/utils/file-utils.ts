import _ from 'lodash';
import fs from 'fs';
import path from 'path';

export default class FileUtils {

  static readAllFiles (dir: string, fileMatcher?: (file: string) => boolean): Array<string> {
    return fs.readdirSync(dir).reduce((files: Array<string>, file: string) => {
      if (fs.statSync(path.join(dir, file)).isDirectory()) {
        return files.concat(FileUtils.readAllFiles(path.join(dir, file), fileMatcher));
      }
      else {
        return files.concat(!fileMatcher || fileMatcher(file) ? [path.join(dir, file)] : []);
      }
    }, []);
  }

  static parseToJson (rootDir: string, allowlistPatterns: Array<string>, blocklistPatterns: Array<string>) {
    return FileUtils.readAllFiles(rootDir, (filePath: string) => {
      for (const pattern of blocklistPatterns) {
        if (filePath.endsWith(pattern)) {
          return false;
        }
      }
      for (const pattern of allowlistPatterns) {
        if (!filePath.endsWith(pattern)) {
          return false;
        }
      }
      return true;
    }).map((path) => JSON.parse(fs.readFileSync(path).toString())).flat();
  }

}

import path from 'path';
import { createWorkshopText, createModInfo } from './createInformationText.js';
import { isTransitionFile } from './isTransitionFile.js';
import { convertEncoding } from './convertEncoding.js';

const options = {
  overwrite: true,
  expand: true,
  dot: false,
  junk: false,
  filter: ['**/*'],
  rename(filePath) {
    if (/\.utf8\.lua\.txt/.test(filePath)) {
      return filePath.replace('.utf8.lua.txt', '.txt');
    }
    return filePath;
  },
  transform(src) {
    if (path.basename(src) === 'workshop.txt') {
      return createWorkshopText();
    }
    if (path.basename(src) === 'mod.info') {
      return createModInfo();
    }
    if (isTransitionFile(src)) {
      return convertEncoding(src);
    }
    return null;
  },
};

export default options;

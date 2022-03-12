import path from 'path';
import { readFileSync } from 'fs';

const info = getInfo();

function getInfo() {
  const filePath = path.normalize('./info.json');
  const file = readFileSync(filePath);
  return JSON.parse(file);
}

export default info;

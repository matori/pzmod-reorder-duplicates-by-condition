import path from 'path';
import through from 'through2';
import iconv from 'iconv-lite';

import encodingList from './encodingList.js';

function convertEncoding(filePath) {
  const parentDir = path.basename(path.dirname(filePath));
  let targetEncoding = encodingList[parentDir];
  return through((chunk, enc, done) => {
    const text = chunk.toString();
    const output = iconv.encode(text, targetEncoding);
    done(null, output);
  });
}

export { convertEncoding };

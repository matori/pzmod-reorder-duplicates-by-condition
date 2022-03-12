import path from 'path';
import watch from 'node-watch';
import picomatch from 'picomatch';
import copy from 'recursive-copy';

import { src, dest } from './dir.js';
import copyOptions from './copyOptions.js';

const isMatch = picomatch('**/media/lua/**/*.*');
const watcher = watch('./src', {
  recursive: true,
  filter: (f) => isMatch(f),
});

watcher.on('change', (evt, name) => {
  console.info(`File changed: ${name}`);
  const basename = path.basename(name.toString());
  const options = Object.assign({}, copyOptions, { filter: `**/${basename}` });
  copy(src, dest, options)
    .then(function (results) {
      console.info(`Copied to: ${results[0].dest}`);
    })
    .catch(function (error) {
      console.error('Copy failed: ' + error);
    });
});

watcher.on('error', (err) => {
  console.error(err);
});

watcher.on('ready', function () {
  console.info('File watcher ready!');
});

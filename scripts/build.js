import copy from 'recursive-copy';

import copyOptions from './copyOptions.js';
import { src, dest } from './dir.js';

copy(src, dest, copyOptions)
  .then(function (results) {
    console.info('Copied ' + results.length + ' files');
  })
  .catch(function (error) {
    console.error('Copy failed: ' + error);
  });

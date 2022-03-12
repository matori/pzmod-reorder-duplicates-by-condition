import path from 'path';

function isTransitionFile(filePath) {
  const relative = path.relative('src/Contents/mods/ReorderDuplicatesByCondition/media/lua/shared/Translate', filePath);
  return relative && !relative.startsWith('..') && !path.isAbsolute(relative);
}

export { isTransitionFile };

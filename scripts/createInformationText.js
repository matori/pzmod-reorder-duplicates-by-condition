import through from 'through2';

import info from './info.js';

const isDevMode = process.env.NODE_ENV === 'development';

function createHeaders() {
  const title = isDevMode ? `[DEV] ${info.name}` : info.name;
  const headers = info.workshop;
  if (isDevMode) {
    delete headers.id;
    delete headers.tags;
    delete headers.visibility;
  }
  return Object.keys(headers).reduce((result, key, index) => {
    result.push(`${key}=${headers[key]}`);
    if (index === 0) {
      result.push(`title=${title}`);
    }
    return result;
  }, []);
}

function createDescription(text) {
  const textArr = text.split('\n');
  return textArr.map((line) => `description=${line}`);
}

function createWorkshopText() {
  return through((chunk, enc, done) => {
    const text = chunk.toString();
    const output = [...createHeaders(), ...createDescription(text)];
    done(null, output.join('\n'));
  });
}

function createModInfo() {
  const { name, modInfo } = info;
  const { id, description } = modInfo;
  const data = {
    name,
    id,
    description,
  };

  if (isDevMode) {
    data.name = `[DEV] ${data.name}`;
    data.id = `${data.id}_Dev`;
  }

  return through((chunk, enc, done) => {
    const text = chunk.toString();
    const output = Object.keys(data).reduce((result, key) => {
      result.push(`${key}=${data[key]}`);
      return result;
    }, []);
    output.push(text);
    done(null, output.join('\n'));
  });
}

export { createWorkshopText, createModInfo };

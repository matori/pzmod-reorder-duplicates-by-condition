import os from 'os';
import info from './info.js';

const userDir = os.homedir();
const isDevMode = process.env.NODE_ENV === 'development';

const productionDirName = info.modInfo.id;
const developmentDirName = `${info.modInfo.id}_Dev`;
const dirName = isDevMode ? developmentDirName : productionDirName;

const src = './src';
const dest = `${userDir}/Zomboid/Workshop/${dirName}`;

export { src, dest };

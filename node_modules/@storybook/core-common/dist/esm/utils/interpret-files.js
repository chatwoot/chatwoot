import "core-js/modules/es.array.sort.js";
import fs from 'fs';
import { extensions } from 'interpret';
export var boost = new Set(['.js', '.jsx', '.ts', '.tsx', '.cjs', '.mjs']);

function sortExtensions() {
  return [...Array.from(boost), ...Object.keys(extensions).filter(function (ext) {
    return !boost.has(ext);
  }).sort(function (a, b) {
    return a.length - b.length;
  })];
}

var possibleExtensions = sortExtensions();
export function getInterpretedFile(pathToFile) {
  return possibleExtensions.map(function (ext) {
    return pathToFile.endsWith(ext) ? pathToFile : `${pathToFile}${ext}`;
  }).find(function (candidate) {
    return fs.existsSync(candidate);
  });
}
export function getInterpretedFileWithExt(pathToFile) {
  return possibleExtensions.map(function (ext) {
    return {
      path: pathToFile.endsWith(ext) ? pathToFile : `${pathToFile}${ext}`,
      ext: ext
    };
  }).find(function (candidate) {
    return fs.existsSync(candidate.path);
  });
}
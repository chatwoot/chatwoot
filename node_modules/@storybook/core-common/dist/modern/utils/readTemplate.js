import "core-js/modules/es.promise.js";
import fse from 'fs-extra';
export async function readTemplate(filename) {
  return fse.readFile(filename, {
    encoding: 'utf8'
  });
}
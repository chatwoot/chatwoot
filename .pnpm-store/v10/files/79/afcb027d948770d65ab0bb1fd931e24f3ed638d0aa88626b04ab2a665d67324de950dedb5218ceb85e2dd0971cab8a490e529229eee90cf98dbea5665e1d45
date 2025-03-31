const fs = require('fs');
const path = require('path');
const baseDir = path.join(__dirname, '..');
const formatDir = path.join(baseDir, 'test', 'fixtures', 'formats');
const parsingDir = path.join(baseDir, 'test', 'fixtures', 'parsing');

const getFiles = (dir) => (fs.readdirSync(dir) || []).reduce((acc, d) => {
  d = path.resolve(dir, d);

  const stat = fs.statSync(d);

  if (!stat.isDirectory()) {
    return acc;
  }

  const subfiles = fs.readdirSync(d).map((f) => path.resolve(d, f));

  return acc.concat(subfiles);
}, []);

const buildDataString = function(files, id) {
  const data = {};

  files.forEach((file) => {
    // read the file directly as a buffer before converting to base64
    const base64 = fs.readFileSync(file).toString('base64');

    data[path.basename(file)] = base64;
  });

  const dataExportStrings = Object.keys(data).reduce((acc, key) => {
    // use a function since the segment may be cleared out on usage
    acc.push(`${id}Files['${key}'] = () => {
        cache['${key}'] = cache['${key}'] || base64ToUint8Array('${data[key]}');
        const dest = new Uint8Array(cache['${key}'].byteLength);
        dest.set(cache['${key}']);
        return dest;
      };`);
    return acc;
  }, []);

  const file =
    '/* istanbul ignore file */\n' +
    '\n' +
    `import base64ToUint8Array from "${path.resolve(baseDir, 'src/decode-b64-to-uint8-array.js')}";\n` +
    'const cache = {};\n' +
    `const ${id}Files = {};\n` +
    dataExportStrings.join('\n') +
    `export default ${id}Files`;

  return file;
};

/* we refer to them as .js, so that babel and other plugins can work on them */
const formatsKey = 'create-test-data!formats.js';
const parsingKey = 'create-test-data!parsing.js';

module.exports = function() {
  return {
    name: 'createTestData',
    buildStart() {
      this.addWatchFile(formatDir);
      this.addWatchFile(parsingDir);

      getFiles(formatDir).forEach((file) => this.addWatchFile(file));
      getFiles(parsingDir).forEach((file) => this.addWatchFile(file));
    },
    resolveId(importee, importer) {
      // if this is not an id we can resolve return
      if (importee.indexOf('create-test-data!') !== 0) {
        return;
      }

      const name = importee.split('!')[1];

      if (name.indexOf('formats') !== -1) {
        return formatsKey;
      }

      if (name.indexOf('parsing') !== -1) {
        return parsingKey;
      }

      return null;
    },
    load(id) {
      if (id === formatsKey) {
        return buildDataString.call(this, getFiles(formatDir), 'format');
      }

      if (id === parsingKey) {
        return buildDataString.call(this, getFiles(parsingDir), 'parsing');
      }
    }
  };
};

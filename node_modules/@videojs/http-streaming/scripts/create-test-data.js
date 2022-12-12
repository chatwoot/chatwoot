/* global window */
const fs = require('fs');
const path = require('path');
const baseDir = path.join(__dirname, '..');
const manifestsDir = path.join(baseDir, 'test', 'manifests');
const segmentsDir = path.join(baseDir, 'test', 'segments');

const base64ToUint8Array = function(base64) {
  const decoded = window.atob(base64);
  const uint8Array = new Uint8Array(new ArrayBuffer(decoded.length));

  for (let i = 0; i < decoded.length; i++) {
    uint8Array[i] = decoded.charCodeAt(i);
  }

  return uint8Array;
};

const getManifests = () => (fs.readdirSync(manifestsDir) || [])
  .filter((f) => ((/\.(m3u8|mpd)/).test(path.extname(f))))
  .map((f) => path.resolve(manifestsDir, f));

const getSegments = () => (fs.readdirSync(segmentsDir) || [])
  .filter((f) => ((/\.(ts|mp4|key|webm|aac|ac3)/).test(path.extname(f))))
  .map((f) => path.resolve(segmentsDir, f));

const buildManifestString = function() {
  let manifests = 'export default {\n';

  getManifests().forEach((file) => {
    // translate this manifest
    manifests += '  \'' + path.basename(file, path.extname(file)) + '\': ';
    manifests += fs.readFileSync(file, 'utf8')
      .split(/\r\n|\n/)
    // quote and concatenate
      .map((line) => '    \'' + line + '\\n\' +\n')
      .join('')
    // strip leading spaces and the trailing '+'
      .slice(4, -3);
    manifests += ',\n';
  });

  // clean up and close the objects
  manifests = manifests.slice(0, -2);
  manifests += '\n};\n';

  return manifests;
};

const buildSegmentString = function() {
  const segmentData = {};

  getSegments().forEach((file) => {
    // read the file directly as a buffer before converting to base64
    const base64Segment = fs.readFileSync(file).toString('base64');

    segmentData[path.basename(file, path.extname(file))] = base64Segment;
  });

  const segmentDataExportStrings = Object.keys(segmentData).reduce((acc, key) => {
    // use a function since the segment may be cleared out on usage
    acc.push(`export const ${key} = () => {
        cache.${key} = cache.${key} || base64ToUint8Array('${segmentData[key]}');
        const dest = new Uint8Array(cache.${key}.byteLength);
        dest.set(cache.${key});
        return dest;
      };`);

    return acc;
  }, []);

  const segmentsFile =
    'const cache = {};\n' +
    `const base64ToUint8Array = ${base64ToUint8Array.toString()};\n` +
    segmentDataExportStrings.join('\n');

  return segmentsFile;
};

/* we refer to them as .js, so that babel and other plugins can work on them */
const segmentsKey = 'create-test-data!segments.js';
const manifestsKey = 'create-test-data!manifests.js';

module.exports = function() {
  return {
    name: 'createTestData',
    buildStart() {
      this.addWatchFile(segmentsDir);
      this.addWatchFile(manifestsDir);

      [].concat(getSegments())
        .concat(getManifests())
        .forEach((file) => this.addWatchFile(file));
    },
    resolveId(importee, importer) {
      // if this is not an id we can resolve return
      if (importee.indexOf('create-test-data!') !== 0) {
        return;
      }

      const name = importee.split('!')[1];

      return (name.indexOf('segments') === 0) ? segmentsKey : manifestsKey;
    },
    load(id) {
      if (id === segmentsKey) {
        return buildSegmentString.call(this);
      }

      if (id === manifestsKey) {
        return buildManifestString.call(this);
      }
    }
  };
};

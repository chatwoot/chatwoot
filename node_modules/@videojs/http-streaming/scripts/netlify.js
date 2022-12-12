const path = require('path');
const sh = require('shelljs');

const deployDir = 'deploy';
const files = [
  'node_modules/video.js/dist/video-js.css',
  'node_modules/video.js/dist/alt/video.core.js',
  'node_modules/video.js/dist/alt/video.core.min.js',
  'node_modules/videojs-contrib-eme/dist/videojs-contrib-eme.js',
  'node_modules/videojs-contrib-eme/dist/videojs-contrib-eme.min.js',
  'node_modules/videojs-contrib-quality-levels/dist/videojs-contrib-quality-levels.js',
  'node_modules/videojs-contrib-quality-levels/dist/videojs-contrib-quality-levels.min.js',
  'node_modules/videojs-http-source-selector/dist/videojs-http-source-selector.css',
  'node_modules/videojs-http-source-selector/dist/videojs-http-source-selector.js',
  'node_modules/videojs-http-source-selector/dist/videojs-http-source-selector.min.js',
  'node_modules/bootstrap/dist/js/bootstrap.js',
  'node_modules/bootstrap/dist/css/bootstrap.css',
  'node_modules/d3/d3.min.js',
  'logo.svg',
  'scripts/sources.json',
  'scripts/index.js',
  'scripts/old-index.js',
  'scripts/dash-manifest-object.json',
  'scripts/hls-manifest-object.json',
  'test/dist/bundle.js'
];

// cleanup previous deploy
sh.rm('-rf', deployDir);
// make sure the directory exists
sh.mkdir('-p', deployDir);

// create nested directories
files
  .map((file) => path.dirname(file))
  .forEach((dir) => sh.mkdir('-p', path.join(deployDir, dir)));

// copy files/folders to deploy dir
files
  .concat('dist', 'index.html', 'old-index.html', 'utils')
  .forEach((file) => sh.cp('-r', file, path.join(deployDir, file)));

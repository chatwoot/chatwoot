const path = require('path');
const sh = require('shelljs');

const files = ['dist', 'index.html'];
const deployDir = 'deploy';

// cleanup previous deploy
sh.rm('-rf', deployDir);
// make sure the directory exists
sh.mkdir('-p', deployDir);

// copy over dist, and html files
files
  .forEach((file) => sh.cp('-r', file, path.join(deployDir, file)));

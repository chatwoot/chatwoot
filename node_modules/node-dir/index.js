var dirpaths = require('./lib/paths');

Object.assign(exports, dirpaths)
exports.readFiles = require('./lib/readfiles');
exports.readFilesStream = require('./lib/readfilesstream');

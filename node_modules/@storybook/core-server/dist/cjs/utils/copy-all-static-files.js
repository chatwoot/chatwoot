"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.copyAllStaticFiles = copyAllStaticFiles;
exports.copyAllStaticFilesRelativeToMain = copyAllStaticFilesRelativeToMain;

require("core-js/modules/es.promise.js");

var _chalk = _interopRequireDefault(require("chalk"));

var _fsExtra = _interopRequireDefault(require("fs-extra"));

var _path = _interopRequireDefault(require("path"));

var _nodeLogger = require("@storybook/node-logger");

var _coreCommon = require("@storybook/core-common");

var _serverStatics = require("./server-statics");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

async function copyAllStaticFiles(staticDirs, outputDir) {
  if (staticDirs && staticDirs.length > 0) {
    await Promise.all(staticDirs.map(async function (dir) {
      try {
        var _await$parseStaticDir = await (0, _serverStatics.parseStaticDir)(dir),
            staticDir = _await$parseStaticDir.staticDir,
            staticPath = _await$parseStaticDir.staticPath,
            targetDir = _await$parseStaticDir.targetDir;

        var targetPath = _path.default.join(outputDir, targetDir);

        _nodeLogger.logger.info((0, _chalk.default)`=> Copying static files: {cyan ${staticDir}} => {cyan ${targetDir}}`); // Storybook's own files should not be overwritten, so we skip such files if we find them


        var skipPaths = ['index.html', 'iframe.html'].map(function (f) {
          return _path.default.join(targetPath, f);
        });
        await _fsExtra.default.copy(staticPath, targetPath, {
          dereference: true,
          preserveTimestamps: true,
          filter: function (_, dest) {
            return !skipPaths.includes(dest);
          }
        });
      } catch (e) {
        _nodeLogger.logger.error(e.message);

        process.exit(-1);
      }
    }));
  }
}

async function copyAllStaticFilesRelativeToMain(staticDirs, outputDir, configDir) {
  staticDirs.forEach(async function (dir) {
    var staticDirAndTarget = typeof dir === 'string' ? dir : `${dir.from}:${dir.to}`;

    var _await$parseStaticDir2 = await (0, _serverStatics.parseStaticDir)((0, _coreCommon.getDirectoryFromWorkingDir)({
      configDir: configDir,
      workingDir: process.cwd(),
      directory: staticDirAndTarget
    })),
        from = _await$parseStaticDir2.staticPath,
        to = _await$parseStaticDir2.targetEndpoint;

    var targetPath = _path.default.join(outputDir, to);

    var skipPaths = ['index.html', 'iframe.html'].map(function (f) {
      return _path.default.join(targetPath, f);
    });

    _nodeLogger.logger.info((0, _chalk.default)`=> Copying static files: {cyan ${from}} at {cyan ${targetPath}}`);

    await _fsExtra.default.copy(from, targetPath, {
      dereference: true,
      preserveTimestamps: true,
      filter: function (_, dest) {
        return !skipPaths.includes(dest);
      }
    });
  });
}
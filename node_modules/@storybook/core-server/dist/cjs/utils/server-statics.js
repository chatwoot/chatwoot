"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.parseStaticDir = void 0;
exports.useStatics = useStatics;

require("core-js/modules/es.promise.js");

var _nodeLogger = require("@storybook/node-logger");

var _coreCommon = require("@storybook/core-common");

var _chalk = _interopRequireDefault(require("chalk"));

var _express = _interopRequireDefault(require("express"));

var _fsExtra = require("fs-extra");

var _path = _interopRequireDefault(require("path"));

var _serveFavicon = _interopRequireDefault(require("serve-favicon"));

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var defaultFavIcon = require.resolve('@storybook/core-server/public/favicon.ico');

async function useStatics(router, options) {
  var hasCustomFavicon = false;
  var staticDirs = await options.presets.apply('staticDirs');

  if (staticDirs && options.staticDir) {
    throw new Error((0, _tsDedent.default)`
      Conflict when trying to read staticDirs:
      * Storybook's configuration option: 'staticDirs'
      * Storybook's CLI flag: '--staticDir' or '-s'
      
      Choose one of them, but not both.
    `);
  }

  var statics = staticDirs ? staticDirs.map(function (dir) {
    return typeof dir === 'string' ? dir : `${dir.from}:${dir.to}`;
  }) : options.staticDir;

  if (statics && statics.length > 0) {
    await Promise.all(statics.map(async function (dir) {
      try {
        var relativeDir = staticDirs ? (0, _coreCommon.getDirectoryFromWorkingDir)({
          configDir: options.configDir,
          workingDir: process.cwd(),
          directory: dir
        }) : dir;

        var _await$parseStaticDir = await parseStaticDir(relativeDir),
            staticDir = _await$parseStaticDir.staticDir,
            staticPath = _await$parseStaticDir.staticPath,
            targetEndpoint = _await$parseStaticDir.targetEndpoint;

        _nodeLogger.logger.info((0, _chalk.default)`=> Serving static files from {cyan ${staticDir}} at {cyan ${targetEndpoint}}`);

        router.use(targetEndpoint, _express.default.static(staticPath, {
          index: false
        }));

        if (!hasCustomFavicon && targetEndpoint === '/') {
          var faviconPath = _path.default.join(staticPath, 'favicon.ico');

          if (await (0, _fsExtra.pathExists)(faviconPath)) {
            hasCustomFavicon = true;
            router.use((0, _serveFavicon.default)(faviconPath));
          }
        }
      } catch (e) {
        _nodeLogger.logger.warn(e.message);
      }
    }));
  }

  if (!hasCustomFavicon) {
    router.use((0, _serveFavicon.default)(defaultFavIcon));
  }
}

var parseStaticDir = async function (arg) {
  // Split on last index of ':', for Windows compatibility (e.g. 'C:\some\dir:\foo')
  var lastColonIndex = arg.lastIndexOf(':');

  var isWindowsAbsolute = _path.default.win32.isAbsolute(arg);

  var isWindowsRawDirOnly = isWindowsAbsolute && lastColonIndex === 1; // e.g. 'C:\some\dir'

  var splitIndex = lastColonIndex !== -1 && !isWindowsRawDirOnly ? lastColonIndex : arg.length;
  var targetRaw = arg.substring(splitIndex + 1) || '/';
  var target = targetRaw.split(_path.default.sep).join(_path.default.posix.sep); // Ensure target has forward-slash path

  var rawDir = arg.substring(0, splitIndex);
  var staticDir = _path.default.isAbsolute(rawDir) ? rawDir : `./${rawDir}`;

  var staticPath = _path.default.resolve(staticDir);

  var targetDir = target.replace(/^\/?/, './');
  var targetEndpoint = targetDir.substring(1);

  if (!(await (0, _fsExtra.pathExists)(staticPath))) {
    throw new Error((0, _tsDedent.default)((0, _chalk.default)`
        Failed to load static files, no such directory: {cyan ${staticPath}}
        Make sure this directory exists, or omit the {bold -s (--static-dir)} option.
      `));
  }

  return {
    staticDir: staticDir,
    staticPath: staticPath,
    targetDir: targetDir,
    targetEndpoint: targetEndpoint
  };
};

exports.parseStaticDir = parseStaticDir;
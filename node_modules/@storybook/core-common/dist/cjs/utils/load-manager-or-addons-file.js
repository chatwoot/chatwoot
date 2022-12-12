"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.loadManagerOrAddonsFile = loadManagerOrAddonsFile;

var _path = _interopRequireDefault(require("path"));

var _nodeLogger = require("@storybook/node-logger");

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

var _interpretFiles = require("./interpret-files");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function loadManagerOrAddonsFile({
  configDir: configDir
}) {
  var storybookCustomAddonsPath = (0, _interpretFiles.getInterpretedFile)(_path.default.resolve(configDir, 'addons'));
  var storybookCustomManagerPath = (0, _interpretFiles.getInterpretedFile)(_path.default.resolve(configDir, 'manager'));

  if (storybookCustomAddonsPath || storybookCustomManagerPath) {
    _nodeLogger.logger.info('=> Loading custom manager config');
  }

  if (storybookCustomAddonsPath && storybookCustomManagerPath) {
    throw new Error((0, _tsDedent.default)`
      You have both a "addons.js" and a "manager.js", remove the "addons.js" file from your configDir (${_path.default.resolve(configDir, 'addons')})`);
  }

  return storybookCustomManagerPath || storybookCustomAddonsPath;
}
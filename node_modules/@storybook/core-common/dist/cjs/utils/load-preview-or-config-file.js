"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.loadPreviewOrConfigFile = loadPreviewOrConfigFile;

var _path = _interopRequireDefault(require("path"));

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

var _interpretFiles = require("./interpret-files");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function loadPreviewOrConfigFile({
  configDir: configDir
}) {
  var storybookConfigPath = (0, _interpretFiles.getInterpretedFile)(_path.default.resolve(configDir, 'config'));
  var storybookPreviewPath = (0, _interpretFiles.getInterpretedFile)(_path.default.resolve(configDir, 'preview'));

  if (storybookConfigPath && storybookPreviewPath) {
    throw new Error((0, _tsDedent.default)`
      You have both a "config.js" and a "preview.js", remove the "config.js" file from your configDir (${_path.default.resolve(configDir, 'config')})`);
  }

  return storybookPreviewPath || storybookConfigPath;
}
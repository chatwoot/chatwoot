"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.loadCustomPresets = loadCustomPresets;

var _path = _interopRequireDefault(require("path"));

var _interpretRequire = require("./interpret-require");

var _validateConfigurationFiles = require("./validate-configuration-files");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function loadCustomPresets({
  configDir: configDir
}) {
  (0, _validateConfigurationFiles.validateConfigurationFiles)(configDir);
  var presets = (0, _interpretRequire.serverRequire)(_path.default.resolve(configDir, 'presets'));
  var main = (0, _interpretRequire.serverRequire)(_path.default.resolve(configDir, 'main'));

  if (main) {
    return [(0, _interpretRequire.serverResolve)(_path.default.resolve(configDir, 'main'))];
  }

  return presets || [];
}
"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.loadMainConfig = loadMainConfig;

var _path = _interopRequireDefault(require("path"));

var _interpretRequire = require("./interpret-require");

var _validateConfigurationFiles = require("./validate-configuration-files");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function loadMainConfig({
  configDir: configDir
}) {
  (0, _validateConfigurationFiles.validateConfigurationFiles)(configDir);
  return (0, _interpretRequire.serverRequire)(_path.default.resolve(configDir, 'main'));
}
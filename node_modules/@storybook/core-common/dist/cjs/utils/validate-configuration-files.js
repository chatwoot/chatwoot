"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.validateConfigurationFiles = validateConfigurationFiles;

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

var _utilDeprecate = _interopRequireDefault(require("util-deprecate"));

var _glob = _interopRequireDefault(require("glob"));

var _path = _interopRequireDefault(require("path"));

var _interpretFiles = require("./interpret-files");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var warnLegacyConfigurationFiles = (0, _utilDeprecate.default)(function () {}, (0, _tsDedent.default)`
    Configuration files such as "config", "presets" and "addons" are deprecated and will be removed in Storybook 7.0.
    Read more about it in the migration guide: https://github.com/storybookjs/storybook/blob/master/MIGRATION.md#to-mainjs-configuration
  `);

var errorMixingConfigFiles = function (first, second, configDir) {
  var firstPath = _path.default.resolve(configDir, first);

  var secondPath = _path.default.resolve(configDir, second);

  throw new Error((0, _tsDedent.default)`
    You have mixing configuration files:
    ${firstPath}
    ${secondPath}
    "${first}" and "${second}" cannot coexist.
    Please check the documentation for migration steps: https://github.com/storybookjs/storybook/blob/master/MIGRATION.md#to-mainjs-configuration
  `);
};

function validateConfigurationFiles(configDir) {
  var extensionsPattern = `{${Array.from(_interpretFiles.boost).join(',')}}`;

  var exists = function (file) {
    return !!_glob.default.sync(_path.default.resolve(configDir, `${file}${extensionsPattern}`)).length;
  };

  var main = exists('main');
  var config = exists('config');

  if (!main && !config) {
    throw new Error((0, _tsDedent.default)`
      No configuration files have been found in your configDir (${_path.default.resolve(configDir)}).
      Storybook needs either a "main" or "config" file.
    `);
  }

  if (main && config) {
    throw new Error((0, _tsDedent.default)`
      You have both a "main" and a "config". Please remove the "config" file from your configDir (${_path.default.resolve(configDir, 'config')})`);
  }

  var presets = exists('presets');

  if (main && presets) {
    errorMixingConfigFiles('main', 'presets', configDir);
  }

  var preview = exists('preview');

  if (preview && config) {
    errorMixingConfigFiles('preview', 'config', configDir);
  }

  var addons = exists('addons');
  var manager = exists('manager');

  if (manager && addons) {
    errorMixingConfigFiles('manager', 'addons', configDir);
  }

  if (presets || config || addons) {
    warnLegacyConfigurationFiles();
  }
}
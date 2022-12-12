"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.checkDocsLoaded = void 0;

require("core-js/modules/es.array.join.js");

var _coreCommon = require("@storybook/core-common");

var _path = _interopRequireDefault(require("path"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var checkDocsLoaded = function checkDocsLoaded(configDir) {
  (0, _coreCommon.checkAddonOrder)({
    before: {
      name: '@storybook/addon-docs',
      inEssentials: true
    },
    after: {
      name: '@storybook/addon-controls',
      inEssentials: true
    },
    configFile: _path.default.isAbsolute(configDir) ? _path.default.join(configDir, 'main') : _path.default.join(process.cwd(), configDir, 'main'),
    getConfig: function getConfig(configFile) {
      return (0, _coreCommon.serverRequire)(configFile);
    }
  });
};

exports.checkDocsLoaded = checkDocsLoaded;
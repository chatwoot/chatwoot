"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = getAllConfigs;

var _defaultConfigStub = _interopRequireDefault(require("../../stubs/defaultConfig.stub.js"));

var _featureFlags = require("../featureFlags");

var _uniformColorPalette = _interopRequireDefault(require("../flagged/uniformColorPalette.js"));

var _extendedSpacingScale = _interopRequireDefault(require("../flagged/extendedSpacingScale.js"));

var _defaultLineHeights = _interopRequireDefault(require("../flagged/defaultLineHeights.js"));

var _extendedFontSizeScale = _interopRequireDefault(require("../flagged/extendedFontSizeScale.js"));

var _darkModeVariant = _interopRequireDefault(require("../flagged/darkModeVariant.js"));

var _standardFontWeights = _interopRequireDefault(require("../flagged/standardFontWeights"));

var _additionalBreakpoint = _interopRequireDefault(require("../flagged/additionalBreakpoint"));

var _lodash = require("lodash");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function getAllConfigs(config) {
  const configs = (0, _lodash.flatMap)([...(0, _lodash.get)(config, 'presets', [_defaultConfigStub.default])].reverse(), preset => {
    return getAllConfigs(preset);
  });
  const features = {
    uniformColorPalette: _uniformColorPalette.default,
    extendedSpacingScale: _extendedSpacingScale.default,
    defaultLineHeights: _defaultLineHeights.default,
    extendedFontSizeScale: _extendedFontSizeScale.default,
    standardFontWeights: _standardFontWeights.default,
    darkModeVariant: _darkModeVariant.default,
    additionalBreakpoint: _additionalBreakpoint.default
  };
  Object.keys(features).forEach(feature => {
    if ((0, _featureFlags.flagEnabled)(config, feature)) {
      configs.unshift(features[feature]);
    }
  });
  return [config, ...configs];
}
"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _helperPluginUtils = require("@babel/helper-plugin-utils");

var _pluginSyntaxDecorators = _interopRequireDefault(require("@babel/plugin-syntax-decorators"));

var _helperCreateClassFeaturesPlugin = require("@babel/helper-create-class-features-plugin");

var _transformerLegacy = _interopRequireDefault(require("./transformer-legacy"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var _default = (0, _helperPluginUtils.declare)((api, options) => {
  api.assertVersion(7);
  const {
    legacy = false
  } = options;

  if (typeof legacy !== "boolean") {
    throw new Error("'legacy' must be a boolean.");
  }

  const {
    decoratorsBeforeExport
  } = options;

  if (decoratorsBeforeExport === undefined) {
    if (!legacy) {
      throw new Error("The decorators plugin requires a 'decoratorsBeforeExport' option," + " whose value must be a boolean. If you want to use the legacy" + " decorators semantics, you can set the 'legacy: true' option.");
    }
  } else {
    if (legacy) {
      throw new Error("'decoratorsBeforeExport' can't be used with legacy decorators.");
    }

    if (typeof decoratorsBeforeExport !== "boolean") {
      throw new Error("'decoratorsBeforeExport' must be a boolean.");
    }
  }

  if (legacy) {
    return {
      name: "proposal-decorators",
      inherits: _pluginSyntaxDecorators.default,

      manipulateOptions({
        generatorOpts
      }) {
        generatorOpts.decoratorsBeforeExport = decoratorsBeforeExport;
      },

      visitor: _transformerLegacy.default
    };
  }

  return (0, _helperCreateClassFeaturesPlugin.createClassFeaturePlugin)({
    name: "proposal-decorators",
    api,
    feature: _helperCreateClassFeaturesPlugin.FEATURES.decorators,

    manipulateOptions({
      generatorOpts,
      parserOpts
    }) {
      parserOpts.plugins.push(["decorators", {
        decoratorsBeforeExport
      }]);
      generatorOpts.decoratorsBeforeExport = decoratorsBeforeExport;
    }

  });
});

exports.default = _default;
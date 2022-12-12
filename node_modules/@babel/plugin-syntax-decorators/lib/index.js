"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _helperPluginUtils = require("@babel/helper-plugin-utils");

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
      throw new Error("The '@babel/plugin-syntax-decorators' plugin requires a" + " 'decoratorsBeforeExport' option, whose value must be a boolean." + " If you want to use the legacy decorators semantics, you can set" + " the 'legacy: true' option.");
    }
  } else {
    if (legacy) {
      throw new Error("'decoratorsBeforeExport' can't be used with legacy decorators.");
    }

    if (typeof decoratorsBeforeExport !== "boolean") {
      throw new Error("'decoratorsBeforeExport' must be a boolean.");
    }
  }

  return {
    name: "syntax-decorators",

    manipulateOptions(opts, parserOpts) {
      parserOpts.plugins.push(legacy ? "decorators-legacy" : ["decorators", {
        decoratorsBeforeExport
      }]);
    }

  };
});

exports.default = _default;
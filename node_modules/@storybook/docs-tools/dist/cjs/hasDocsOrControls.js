"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.hasDocsOrControls = void 0;

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.function.name.js");

// `addons/x` is for the monorepo, `addon-x` is for normal usage
var packageRe = /(addons\/|addon-)(docs|controls)/;

var hasDocsOrControls = function hasDocsOrControls(options) {
  var _options$presetsList;

  return (_options$presetsList = options.presetsList) === null || _options$presetsList === void 0 ? void 0 : _options$presetsList.some(function (preset) {
    return packageRe.test(preset.name);
  });
};

exports.hasDocsOrControls = hasDocsOrControls;
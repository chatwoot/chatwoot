import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.function.name.js";
// `addons/x` is for the monorepo, `addon-x` is for normal usage
var packageRe = /(addons\/|addon-)(docs|controls)/;
export var hasDocsOrControls = function hasDocsOrControls(options) {
  var _options$presetsList;

  return (_options$presetsList = options.presetsList) === null || _options$presetsList === void 0 ? void 0 : _options$presetsList.some(function (preset) {
    return packageRe.test(preset.name);
  });
};
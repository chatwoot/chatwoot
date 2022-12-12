"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.withBackground = void 0;

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.array.concat.js");

var _addons = require("@storybook/addons");

var _constants = require("../constants");

var _helpers = require("../helpers");

var withBackground = function withBackground(StoryFn, context) {
  var _globals$BACKGROUNDS_;

  var globals = context.globals,
      parameters = context.parameters;
  var globalsBackgroundColor = (_globals$BACKGROUNDS_ = globals[_constants.PARAM_KEY]) === null || _globals$BACKGROUNDS_ === void 0 ? void 0 : _globals$BACKGROUNDS_.value;
  var backgroundsConfig = parameters[_constants.PARAM_KEY];
  var selectedBackgroundColor = (0, _addons.useMemo)(function () {
    if (backgroundsConfig.disable) {
      return 'transparent';
    }

    return (0, _helpers.getBackgroundColorByName)(globalsBackgroundColor, backgroundsConfig.values, backgroundsConfig.default);
  }, [backgroundsConfig, globalsBackgroundColor]);
  var isActive = (0, _addons.useMemo)(function () {
    return selectedBackgroundColor && selectedBackgroundColor !== 'transparent';
  }, [selectedBackgroundColor]);
  var selector = context.viewMode === 'docs' ? "#anchor--".concat(context.id, " .docs-story") : '.sb-show-main';
  var backgroundStyles = (0, _addons.useMemo)(function () {
    var transitionStyle = 'transition: background-color 0.3s;';
    return "\n      ".concat(selector, " {\n        background: ").concat(selectedBackgroundColor, " !important;\n        ").concat((0, _helpers.isReduceMotionEnabled)() ? '' : transitionStyle, "\n      }\n    ");
  }, [selectedBackgroundColor, selector]);
  (0, _addons.useEffect)(function () {
    var selectorId = context.viewMode === 'docs' ? "addon-backgrounds-docs-".concat(context.id) : "addon-backgrounds-color";

    if (!isActive) {
      (0, _helpers.clearStyles)(selectorId);
      return;
    }

    (0, _helpers.addBackgroundStyle)(selectorId, backgroundStyles, context.viewMode === 'docs' ? context.id : null);
  }, [isActive, backgroundStyles, context]);
  return StoryFn();
};

exports.withBackground = withBackground;
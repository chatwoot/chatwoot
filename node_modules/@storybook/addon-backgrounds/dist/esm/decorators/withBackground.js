import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.array.concat.js";
import { useMemo, useEffect } from '@storybook/addons';
import { PARAM_KEY as BACKGROUNDS_PARAM_KEY } from '../constants';
import { clearStyles, addBackgroundStyle, getBackgroundColorByName, isReduceMotionEnabled } from '../helpers';
export var withBackground = function withBackground(StoryFn, context) {
  var _globals$BACKGROUNDS_;

  var globals = context.globals,
      parameters = context.parameters;
  var globalsBackgroundColor = (_globals$BACKGROUNDS_ = globals[BACKGROUNDS_PARAM_KEY]) === null || _globals$BACKGROUNDS_ === void 0 ? void 0 : _globals$BACKGROUNDS_.value;
  var backgroundsConfig = parameters[BACKGROUNDS_PARAM_KEY];
  var selectedBackgroundColor = useMemo(function () {
    if (backgroundsConfig.disable) {
      return 'transparent';
    }

    return getBackgroundColorByName(globalsBackgroundColor, backgroundsConfig.values, backgroundsConfig.default);
  }, [backgroundsConfig, globalsBackgroundColor]);
  var isActive = useMemo(function () {
    return selectedBackgroundColor && selectedBackgroundColor !== 'transparent';
  }, [selectedBackgroundColor]);
  var selector = context.viewMode === 'docs' ? "#anchor--".concat(context.id, " .docs-story") : '.sb-show-main';
  var backgroundStyles = useMemo(function () {
    var transitionStyle = 'transition: background-color 0.3s;';
    return "\n      ".concat(selector, " {\n        background: ").concat(selectedBackgroundColor, " !important;\n        ").concat(isReduceMotionEnabled() ? '' : transitionStyle, "\n      }\n    ");
  }, [selectedBackgroundColor, selector]);
  useEffect(function () {
    var selectorId = context.viewMode === 'docs' ? "addon-backgrounds-docs-".concat(context.id) : "addon-backgrounds-color";

    if (!isActive) {
      clearStyles(selectorId);
      return;
    }

    addBackgroundStyle(selectorId, backgroundStyles, context.viewMode === 'docs' ? context.id : null);
  }, [isActive, backgroundStyles, context]);
  return StoryFn();
};
import { useMemo, useEffect } from '@storybook/addons';
import { clearStyles, addOutlineStyles } from './helpers';
import { PARAM_KEY } from './constants';
import outlineCSS from './outlineCSS';
export var withOutline = function withOutline(StoryFn, context) {
  var globals = context.globals;
  var isActive = globals[PARAM_KEY] === true;
  var isInDocs = context.viewMode === 'docs';
  var outlineStyles = useMemo(function () {
    var selector = isInDocs ? "#anchor--".concat(context.id, " .docs-story") : '.sb-show-main';
    return outlineCSS(selector);
  }, [context]);
  useEffect(function () {
    var selectorId = isInDocs ? "addon-outline-docs-".concat(context.id) : "addon-outline";

    if (!isActive) {
      clearStyles(selectorId);
    } else {
      addOutlineStyles(selectorId, outlineStyles);
    }

    return function () {
      clearStyles(selectorId);
    };
  }, [isActive, outlineStyles, context]);
  return StoryFn();
};
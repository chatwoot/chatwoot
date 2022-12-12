import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.object.freeze.js";

var _templateObject, _templateObject2;

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

import deprecate from 'util-deprecate';
import dedent from 'ts-dedent';
export var decorateAction = function decorateAction(_decorators) {
  return deprecate(function () {}, dedent(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n    decorateAction is no longer supported as of Storybook 6.0.\n  "]))));
};
var deprecatedCallback = deprecate(function () {}, 'decorate.* is no longer supported as of Storybook 6.0.');
export var decorate = function decorate(_decorators) {
  return deprecate(function () {
    return {
      action: deprecatedCallback,
      actions: deprecatedCallback,
      withActions: deprecatedCallback
    };
  }, dedent(_templateObject2 || (_templateObject2 = _taggedTemplateLiteral(["\n    decorate is deprecated, please configure addon-actions using the addParameter api:\n      \n      addParameters({\n        actions: {\n          handles: options\n        },\n      });\n    "]))));
};
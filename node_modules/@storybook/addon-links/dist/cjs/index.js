"use strict";

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.object.freeze.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.LinkTo = LinkTo;
Object.defineProperty(exports, "hrefTo", {
  enumerable: true,
  get: function get() {
    return _utils.hrefTo;
  }
});
Object.defineProperty(exports, "linkTo", {
  enumerable: true,
  get: function get() {
    return _utils.linkTo;
  }
});
Object.defineProperty(exports, "navigate", {
  enumerable: true,
  get: function get() {
    return _utils.navigate;
  }
});
Object.defineProperty(exports, "withLinks", {
  enumerable: true,
  get: function get() {
    return _utils.withLinks;
  }
});

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

var _utils = require("./utils");

var _templateObject;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

var hasWarned = false;

function LinkTo() {
  if (!hasWarned) {
    // eslint-disable-next-line no-console
    console.error((0, _tsDedent.default)(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n      LinkTo has moved to addon-links/react:\n      import LinkTo from '@storybook/addon-links/react';\n    "]))));
    hasWarned = true;
  }

  return null;
}

if (module && module.hot && module.hot.decline) {
  module.hot.decline();
}
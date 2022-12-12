"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.Subheading = void 0;

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.string.replace.js");

var _react = _interopRequireDefault(require("react"));

var _components = require("@storybook/components");

var _mdx = require("./mdx");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Subheading = function Subheading(_ref) {
  var children = _ref.children,
      disableAnchor = _ref.disableAnchor;

  if (disableAnchor || typeof children !== 'string') {
    return /*#__PURE__*/_react.default.createElement(_components.H3, null, children);
  }

  var tagID = children.toLowerCase().replace(/[^a-z0-9]/gi, '-');
  return /*#__PURE__*/_react.default.createElement(_mdx.HeaderMdx, {
    as: "h3",
    id: tagID
  }, children);
};

exports.Subheading = Subheading;
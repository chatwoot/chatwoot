"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.anchorBlockIdFromId = exports.Anchor = void 0;

var _react = _interopRequireDefault(require("react"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var anchorBlockIdFromId = function anchorBlockIdFromId(storyId) {
  return "anchor--".concat(storyId);
};

exports.anchorBlockIdFromId = anchorBlockIdFromId;

var Anchor = function Anchor(_ref) {
  var storyId = _ref.storyId,
      children = _ref.children;
  return /*#__PURE__*/_react.default.createElement("div", {
    id: anchorBlockIdFromId(storyId)
  }, children);
};

exports.Anchor = Anchor;
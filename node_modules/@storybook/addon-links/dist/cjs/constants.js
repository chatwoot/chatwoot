"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = exports.PARAM_KEY = exports.ADDON_ID = void 0;
var ADDON_ID = 'storybook/links';
exports.ADDON_ID = ADDON_ID;
var PARAM_KEY = "links";
exports.PARAM_KEY = PARAM_KEY;
var _default = {
  NAVIGATE: "".concat(ADDON_ID, "/navigate"),
  REQUEST: "".concat(ADDON_ID, "/request"),
  RECEIVE: "".concat(ADDON_ID, "/receive")
};
exports.default = _default;
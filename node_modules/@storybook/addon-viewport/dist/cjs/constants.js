"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.UPDATE = exports.SET = exports.PARAM_KEY = exports.CONFIGURE = exports.CHANGED = exports.ADDON_ID = void 0;
var ADDON_ID = 'storybook/viewport';
exports.ADDON_ID = ADDON_ID;
var PARAM_KEY = 'viewport';
exports.PARAM_KEY = PARAM_KEY;
var UPDATE = "".concat(ADDON_ID, "/update");
exports.UPDATE = UPDATE;
var CONFIGURE = "".concat(ADDON_ID, "/configure");
exports.CONFIGURE = CONFIGURE;
var SET = "".concat(ADDON_ID, "/setStoryDefaultViewport");
exports.SET = SET;
var CHANGED = "".concat(ADDON_ID, "/viewportChanged");
exports.CHANGED = CHANGED;
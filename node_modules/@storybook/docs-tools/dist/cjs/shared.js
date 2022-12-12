"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.SourceType = exports.SNIPPET_RENDERED = exports.PARAM_KEY = exports.PANEL_ID = exports.ADDON_ID = void 0;
var ADDON_ID = 'storybook/docs';
exports.ADDON_ID = ADDON_ID;
var PANEL_ID = "".concat(ADDON_ID, "/panel");
exports.PANEL_ID = PANEL_ID;
var PARAM_KEY = "docs";
exports.PARAM_KEY = PARAM_KEY;
var SNIPPET_RENDERED = "".concat(ADDON_ID, "/snippet-rendered");
exports.SNIPPET_RENDERED = SNIPPET_RENDERED;
var SourceType;
exports.SourceType = SourceType;

(function (SourceType) {
  SourceType["AUTO"] = "auto";
  SourceType["CODE"] = "code";
  SourceType["DYNAMIC"] = "dynamic";
})(SourceType || (exports.SourceType = SourceType = {}));
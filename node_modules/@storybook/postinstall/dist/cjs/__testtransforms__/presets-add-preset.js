"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = transformer;

var _presets = require("../presets");

function transformer(file, api) {
  var j = api.jscodeshift;
  var root = j(file.source);
  (0, _presets.addPreset)('test', null, {
    root: root,
    api: api
  });
  return root.toSource({
    quote: 'single'
  });
}
"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = transformer;

var _presets = require("../presets");

function transformer(file, api) {
  var j = api.jscodeshift;
  var root = j(file.source);
  var options = {
    a: [1, 2, 3],
    b: {
      foo: 'bar'
    },
    c: 'baz'
  };
  (0, _presets.addPreset)('test', options, {
    root: root,
    api: api
  });
  return root.toSource({
    quote: 'single'
  });
}
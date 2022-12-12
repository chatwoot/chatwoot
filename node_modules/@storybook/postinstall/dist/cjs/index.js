"use strict";

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/web.dom-collections.for-each.js");

require("core-js/modules/es.object.keys.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
var _exportNames = {
  presetsAddPreset: true
};
Object.defineProperty(exports, "presetsAddPreset", {
  enumerable: true,
  get: function get() {
    return _presets.addPreset;
  }
});

var _presets = require("./presets");

var _frameworks = require("./frameworks");

Object.keys(_frameworks).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  if (Object.prototype.hasOwnProperty.call(_exportNames, key)) return;
  if (key in exports && exports[key] === _frameworks[key]) return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _frameworks[key];
    }
  });
});
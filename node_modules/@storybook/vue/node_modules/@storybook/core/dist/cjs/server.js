"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _coreServer = require("@storybook/core-server");

Object.keys(_coreServer).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  if (key in exports && exports[key] === _coreServer[key]) return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function () {
      return _coreServer[key];
    }
  });
});
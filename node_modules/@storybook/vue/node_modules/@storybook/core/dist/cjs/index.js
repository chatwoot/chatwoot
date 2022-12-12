"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _coreClient = require("@storybook/core-client");

Object.keys(_coreClient).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  if (key in exports && exports[key] === _coreClient[key]) return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function () {
      return _coreClient[key];
    }
  });
});
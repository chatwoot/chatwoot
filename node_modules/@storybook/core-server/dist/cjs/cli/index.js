"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _dev = require("./dev");

Object.keys(_dev).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  if (key in exports && exports[key] === _dev[key]) return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function () {
      return _dev[key];
    }
  });
});

var _prod = require("./prod");

Object.keys(_prod).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  if (key in exports && exports[key] === _prod[key]) return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function () {
      return _prod[key];
    }
  });
});
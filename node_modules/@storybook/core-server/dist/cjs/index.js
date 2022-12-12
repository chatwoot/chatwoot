"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
var _exportNames = {
  getPreviewHeadTemplate: true,
  getManagerHeadTemplate: true,
  getManagerMainTemplate: true,
  getPreviewBodyTemplate: true,
  getPreviewMainTemplate: true
};
Object.defineProperty(exports, "getManagerHeadTemplate", {
  enumerable: true,
  get: function () {
    return _coreCommon.getManagerHeadTemplate;
  }
});
Object.defineProperty(exports, "getManagerMainTemplate", {
  enumerable: true,
  get: function () {
    return _coreCommon.getManagerMainTemplate;
  }
});
Object.defineProperty(exports, "getPreviewBodyTemplate", {
  enumerable: true,
  get: function () {
    return _coreCommon.getPreviewBodyTemplate;
  }
});
Object.defineProperty(exports, "getPreviewHeadTemplate", {
  enumerable: true,
  get: function () {
    return _coreCommon.getPreviewHeadTemplate;
  }
});
Object.defineProperty(exports, "getPreviewMainTemplate", {
  enumerable: true,
  get: function () {
    return _coreCommon.getPreviewMainTemplate;
  }
});

var _coreCommon = require("@storybook/core-common");

var _buildStatic = require("./build-static");

Object.keys(_buildStatic).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  if (Object.prototype.hasOwnProperty.call(_exportNames, key)) return;
  if (key in exports && exports[key] === _buildStatic[key]) return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function () {
      return _buildStatic[key];
    }
  });
});

var _buildDev = require("./build-dev");

Object.keys(_buildDev).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  if (Object.prototype.hasOwnProperty.call(_exportNames, key)) return;
  if (key in exports && exports[key] === _buildDev[key]) return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function () {
      return _buildDev[key];
    }
  });
});
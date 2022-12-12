"use strict";

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/web.dom-collections.for-each.js");

require("core-js/modules/es.object.keys.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _normalizeInputTypes = require("./normalizeInputTypes");

Object.keys(_normalizeInputTypes).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  if (key in exports && exports[key] === _normalizeInputTypes[key]) return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _normalizeInputTypes[key];
    }
  });
});

var _normalizeStory = require("./normalizeStory");

Object.keys(_normalizeStory).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  if (key in exports && exports[key] === _normalizeStory[key]) return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _normalizeStory[key];
    }
  });
});

var _processCSFFile = require("./processCSFFile");

Object.keys(_processCSFFile).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  if (key in exports && exports[key] === _processCSFFile[key]) return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _processCSFFile[key];
    }
  });
});

var _prepareStory = require("./prepareStory");

Object.keys(_prepareStory).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  if (key in exports && exports[key] === _prepareStory[key]) return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _prepareStory[key];
    }
  });
});

var _normalizeComponentAnnotations = require("./normalizeComponentAnnotations");

Object.keys(_normalizeComponentAnnotations).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  if (key in exports && exports[key] === _normalizeComponentAnnotations[key]) return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _normalizeComponentAnnotations[key];
    }
  });
});

var _normalizeProjectAnnotations = require("./normalizeProjectAnnotations");

Object.keys(_normalizeProjectAnnotations).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  if (key in exports && exports[key] === _normalizeProjectAnnotations[key]) return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _normalizeProjectAnnotations[key];
    }
  });
});

var _getValuesFromArgTypes = require("./getValuesFromArgTypes");

Object.keys(_getValuesFromArgTypes).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  if (key in exports && exports[key] === _getValuesFromArgTypes[key]) return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _getValuesFromArgTypes[key];
    }
  });
});

var _composeConfigs = require("./composeConfigs");

Object.keys(_composeConfigs).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  if (key in exports && exports[key] === _composeConfigs[key]) return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _composeConfigs[key];
    }
  });
});

var _testingUtils = require("./testing-utils");

Object.keys(_testingUtils).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  if (key in exports && exports[key] === _testingUtils[key]) return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _testingUtils[key];
    }
  });
});
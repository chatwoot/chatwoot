"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

require("core-js/modules/es.promise.js");

var _buildStatic = require("./build-static");

var _buildDev = require("./build-dev");

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

async function build(options = {}, frameworkOptions = {}) {
  var _options$mode = options.mode,
      mode = _options$mode === void 0 ? 'dev' : _options$mode;

  var commonOptions = _objectSpread(_objectSpread(_objectSpread({}, options), frameworkOptions), {}, {
    frameworkPresets: [...(options.frameworkPresets || []), ...(frameworkOptions.frameworkPresets || [])]
  });

  if (mode === 'dev') {
    return (0, _buildDev.buildDevStandalone)(commonOptions);
  }

  if (mode === 'static') {
    return (0, _buildStatic.buildStaticStandalone)(commonOptions);
  }

  throw new Error(`'mode' parameter should be either 'dev' or 'static'`);
}

var _default = build;
exports.default = _default;
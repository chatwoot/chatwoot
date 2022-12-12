"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.mergeConfigs = mergeConfigs;

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function plugins({
  plugins: defaultPlugins = []
}, {
  plugins: customPlugins = []
}) {
  return [...defaultPlugins, ...customPlugins];
}

function rules({
  rules: defaultRules = []
}, {
  rules: customRules = []
}) {
  return [...defaultRules, ...customRules];
}

function extensions({
  extensions: defaultExtensions = []
}, {
  extensions: customExtensions = []
}) {
  return [...defaultExtensions, ...customExtensions];
}

function alias({
  alias: defaultAlias = {}
}, {
  alias: customAlias = {}
}) {
  return _objectSpread(_objectSpread({}, defaultAlias), customAlias);
}

function _module({
  module: defaultModule = {
    rules: []
  }
}, {
  module: customModule = {
    rules: []
  }
}) {
  return _objectSpread(_objectSpread(_objectSpread({}, defaultModule), customModule), {}, {
    rules: rules(defaultModule, customModule)
  });
}

function resolve({
  resolve: defaultResolve = {}
}, {
  resolve: customResolve = {}
}) {
  return _objectSpread(_objectSpread(_objectSpread({}, defaultResolve), customResolve), {}, {
    alias: alias(defaultResolve, customResolve),
    extensions: extensions(defaultResolve, customResolve)
  });
}

function optimization({
  optimization: defaultOptimization = {}
}, {
  optimization: customOptimization = {}
}) {
  return _objectSpread(_objectSpread({}, defaultOptimization), customOptimization);
}

function mergeConfigs(config, customConfig) {
  return _objectSpread(_objectSpread(_objectSpread({}, customConfig), config), {}, {
    devtool: customConfig.devtool || config.devtool,
    plugins: plugins(config, customConfig),
    module: _module(config, customConfig),
    resolve: resolve(config, customConfig),
    optimization: optimization(config, customConfig)
  });
}
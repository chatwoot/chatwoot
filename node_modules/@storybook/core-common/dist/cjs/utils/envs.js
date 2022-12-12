"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.loadEnvs = loadEnvs;
exports.stringifyProcessEnvs = exports.stringifyEnvs = void 0;

var _lazyUniversalDotenv = require("lazy-universal-dotenv");

var _paths = require("./paths");

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

// Load environment variables starts with STORYBOOK_ to the client side.
function loadEnvs(options = {}) {
  var defaultNodeEnv = options.production ? 'production' : 'development';
  var env = {
    NODE_ENV: process.env.NODE_ENV || defaultNodeEnv,
    NODE_PATH: process.env.NODE_PATH || '',
    STORYBOOK: process.env.STORYBOOK || 'true',
    // This is to support CRA's public folder feature.
    // In production we set this to dot(.) to allow the browser to access these assets
    // even when deployed inside a subpath. (like in GitHub pages)
    // In development this is just empty as we always serves from the root.
    PUBLIC_URL: options.production ? '.' : ''
  };
  Object.keys(process.env).filter(function (name) {
    return /^STORYBOOK_/.test(name);
  }).forEach(function (name) {
    env[name] = process.env[name];
  });
  var base = Object.entries(env).reduce(function (acc, [k, v]) {
    return Object.assign(acc, {
      [k]: JSON.stringify(v)
    });
  }, {});

  var _getEnvironment = (0, _lazyUniversalDotenv.getEnvironment)({
    nodeEnv: env.NODE_ENV
  }),
      stringified = _getEnvironment.stringified,
      raw = _getEnvironment.raw;

  var fullRaw = _objectSpread(_objectSpread({}, env), raw);

  fullRaw.NODE_PATH = (0, _paths.nodePathsToArray)(fullRaw.NODE_PATH || '');
  return {
    stringified: _objectSpread(_objectSpread({}, base), stringified),
    raw: fullRaw
  };
}

var stringifyEnvs = function (raw) {
  return Object.entries(raw).reduce(function (acc, [key, value]) {
    acc[key] = JSON.stringify(value);
    return acc;
  }, {});
};

exports.stringifyEnvs = stringifyEnvs;

var stringifyProcessEnvs = function (raw) {
  var envs = Object.entries(raw).reduce(function (acc, [key, value]) {
    acc[`process.env.${key}`] = JSON.stringify(value);
    return acc;
  }, {
    // Default fallback
    'process.env.XSTORYBOOK_EXAMPLE_APP': '""'
  }); // FIXME: something like this is necessary to support destructuring like:
  //
  // const { foo } = process.env;
  //
  // However, it also means that process.env.foo = 'bar' will fail, so removing this:
  //
  // envs['process.env'] = JSON.stringify(raw);

  return envs;
};

exports.stringifyProcessEnvs = stringifyProcessEnvs;
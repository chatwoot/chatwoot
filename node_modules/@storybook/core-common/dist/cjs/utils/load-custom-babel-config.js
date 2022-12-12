"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.loadCustomBabelConfig = void 0;

require("core-js/modules/es.promise.js");

var _fs = _interopRequireDefault(require("fs"));

var _path = _interopRequireDefault(require("path"));

var _json = _interopRequireDefault(require("json5"));

var _nodeLogger = require("@storybook/node-logger");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function removeReactHmre(presets) {
  var index = presets.indexOf('react-hmre');

  if (index > -1) {
    presets.splice(index, 1);
  }
} // Tries to load a .babelrc and returns the parsed object if successful


function loadFromPath(babelConfigPath) {
  var config;
  var error = {};

  if (_fs.default.existsSync(babelConfigPath)) {
    var content = _fs.default.readFileSync(babelConfigPath, 'utf-8');

    try {
      // eslint-disable-next-line global-require, import/no-dynamic-require
      config = require(babelConfigPath);

      _nodeLogger.logger.info('=> Loading custom babel config as JS');
    } catch (e) {
      error.js = e;
    }

    try {
      config = _json.default.parse(content);

      _nodeLogger.logger.info('=> Loading custom babel config');
    } catch (e) {
      error.json = e;
    }

    if (!config) {
      _nodeLogger.logger.error(`=> Error parsing babel config file: ${babelConfigPath}

      We tried both loading as JS & JSON, neither worked.
      Maybe there's a syntax error in the file?`);

      _nodeLogger.logger.error(`=> From JS loading we got: ${error.js.message}`);

      _nodeLogger.logger.error(`=> From JSON loading we got: ${error.json && error.json.message}`);

      throw error.js;
    }

    config = _objectSpread(_objectSpread({}, config), {}, {
      babelrc: false
    });
  }

  if (!config) return null; // Remove react-hmre preset.
  // It causes issues with react-storybook.
  // We don't really need it.
  // Earlier, we fix this by running storybook in the production mode.
  // But, that hide some useful debug messages.

  if (config.presets) {
    removeReactHmre(config.presets);
  }

  if (config.env && config.env.development && config.env.development.presets) {
    removeReactHmre(config.env.development.presets);
  }

  return config;
}

var loadCustomBabelConfig = async function (configDir, getDefaultConfig) {
  // Between versions 5.1.0 - 5.1.9 this loaded babel.config.js from the project
  // root, which was an unintentional breaking change. We can add back project support
  // in 6.0.
  var babelConfig = loadFromPath(_path.default.resolve(configDir, '.babelrc')) || loadFromPath(_path.default.resolve(configDir, '.babelrc.json')) || loadFromPath(_path.default.resolve(configDir, '.babelrc.js')) || loadFromPath(_path.default.resolve(configDir, 'babel.config.json')) || loadFromPath(_path.default.resolve(configDir, 'babel.config.js'));

  if (babelConfig) {
    // If the custom config uses babel's `extends` clause, then replace it with
    // an absolute path. `extends` will not work unless we do this.
    if (babelConfig.extends) {
      babelConfig.extends = _path.default.resolve(configDir, babelConfig.extends);
    }

    return babelConfig;
  }

  return getDefaultConfig();
};

exports.loadCustomBabelConfig = loadCustomBabelConfig;
import "core-js/modules/es.symbol.description.js";

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

import path from 'path';
import fse from 'fs-extra';
import { getStorybookConfiguration } from './get-storybook-configuration';
var viewLayers = {
  '@storybook/react': 'react',
  '@storybook/vue': 'vue',
  '@storybook/vue3': 'vue3',
  '@storybook/angular': 'angular',
  '@storybook/html': 'html',
  '@storybook/web-components': 'web-components',
  '@storybook/polymer': 'polymer',
  '@storybook/ember': 'ember',
  '@storybook/marko': 'marko',
  '@storybook/mithril': 'mithril',
  '@storybook/riot': 'riot',
  '@storybook/svelte': 'svelte',
  '@storybook/preact': 'preact',
  '@storybook/rax': 'rax'
};
var logger = console;

var findDependency = function ({
  dependencies: dependencies,
  devDependencies: devDependencies,
  peerDependencies: peerDependencies
}, predicate) {
  return [Object.entries(dependencies || {}).find(predicate), Object.entries(devDependencies || {}).find(predicate), Object.entries(peerDependencies || {}).find(predicate)];
};

var getFrameworkInfo = function (packageJson) {
  // Pull the viewlayer from dependencies in package.json
  var _findDependency = findDependency(packageJson, function ([key]) {
    return viewLayers[key];
  }),
      _findDependency2 = _slicedToArray(_findDependency, 3),
      dep = _findDependency2[0],
      devDep = _findDependency2[1],
      peerDep = _findDependency2[2];

  var _ref = dep || devDep || peerDep || [],
      _ref2 = _slicedToArray(_ref, 2),
      pkg = _ref2[0],
      version = _ref2[1];

  var framework = viewLayers[pkg];

  if (dep && devDep && dep[0] === devDep[0]) {
    logger.warn(`Found "${dep[0]}" in both "dependencies" and "devDependencies". This is probably a mistake.`);
  }

  if (dep && peerDep && dep[0] === peerDep[0]) {
    logger.warn(`Found "${dep[0]}" in both "dependencies" and "peerDependencies". This is probably a mistake.`);
  }

  return {
    framework: framework,
    version: version,
    frameworkPackage: pkg
  };
};

var validConfigExtensions = ['ts', 'js', 'tsx', 'jsx', 'mjs', 'cjs'];

var findConfigFile = function (prefix, configDir) {
  var filePrefix = path.join(configDir, prefix);
  var extension = validConfigExtensions.find(function (ext) {
    return fse.existsSync(`${filePrefix}.${ext}`);
  });
  return extension ? `${filePrefix}.${extension}` : null;
};

var getConfigInfo = function (packageJson) {
  var _packageJson$scripts;

  var configDir = '.storybook';
  var storybookScript = (_packageJson$scripts = packageJson.scripts) === null || _packageJson$scripts === void 0 ? void 0 : _packageJson$scripts.storybook;

  if (storybookScript) {
    var configParam = getStorybookConfiguration(storybookScript, '-c', '--config-dir');
    if (configParam) configDir = configParam;
  }

  return {
    configDir: configDir,
    mainConfig: findConfigFile('main', configDir),
    previewConfig: findConfigFile('preview', configDir),
    managerConfig: findConfigFile('manager', configDir)
  };
};

export var getStorybookInfo = function (packageJson) {
  var frameworkInfo = getFrameworkInfo(packageJson);
  var configInfo = getConfigInfo(packageJson);
  return _objectSpread(_objectSpread({}, frameworkInfo), configInfo);
};
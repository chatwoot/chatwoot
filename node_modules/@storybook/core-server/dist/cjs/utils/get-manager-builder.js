"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getManagerBuilder = getManagerBuilder;

require("core-js/modules/es.promise.js");

var _path = _interopRequireDefault(require("path"));

var _coreCommon = require("@storybook/core-common");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function (nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || typeof obj !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

async function getManagerBuilder(configDir) {
  var _core$builder;

  var main = _path.default.resolve(configDir, 'main');

  var mainFile = (0, _coreCommon.getInterpretedFile)(main);

  var _ref = mainFile ? (0, _coreCommon.serverRequire)(mainFile) : {
    core: null
  },
      core = _ref.core;

  var builderName = typeof (core === null || core === void 0 ? void 0 : core.builder) === 'string' ? core.builder : core === null || core === void 0 ? void 0 : (_core$builder = core.builder) === null || _core$builder === void 0 ? void 0 : _core$builder.name; // Builder can be any string including community builders like `storybook-builder-vite`.
  // - For now, `webpack5` triggers `manager-webpack5`
  // - Everything else builds with `manager-webpack4`
  //
  // Unlike preview builders, manager building is not pluggable!

  var builderPackage = ['webpack5', '@storybook/builder-webpack5'].includes(builderName) ? require.resolve('@storybook/manager-webpack5', {
    paths: [main]
  }) : '@storybook/manager-webpack4';
  var managerBuilder = await Promise.resolve(`${builderPackage}`).then(function (s) {
    return _interopRequireWildcard(require(s));
  });
  return managerBuilder;
}
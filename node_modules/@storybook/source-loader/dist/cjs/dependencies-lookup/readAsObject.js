"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.readStory = readStory;

require("core-js/modules/es.object.assign.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.promise.js");

var _loaderUtils = require("loader-utils");

var _injectDecorator = _interopRequireDefault(require("../abstract-syntax-tree/inject-decorator"));

var _generateHelpers = require("../abstract-syntax-tree/generate-helpers");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function readAsObject(classLoader, inputSource, mainFile) {
  var options = (0, _loaderUtils.getOptions)(classLoader) || {};
  var result = (0, _injectDecorator.default)(inputSource, classLoader.resourcePath, Object.assign({}, options, {
    parser: options.parser || classLoader.extension
  }), classLoader.emitWarning.bind(classLoader));
  var sourceJson = (0, _generateHelpers.sanitizeSource)(result.storySource || inputSource);
  var addsMap = result.addsMap || {};
  var source = mainFile ? result.source : inputSource;
  return new Promise(function (resolve) {
    return resolve({
      source: source,
      sourceJson: sourceJson,
      addsMap: addsMap
    });
  });
}

function readStory(classLoader, inputSource) {
  return readAsObject(classLoader, inputSource, true);
}
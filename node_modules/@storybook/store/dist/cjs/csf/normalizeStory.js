"use strict";

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.object.freeze.js");

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.array.from.js");

require("core-js/modules/es.regexp.exec.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.normalizeStory = normalizeStory;

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.array.concat.js");

require("core-js/modules/es.object.assign.js");

var _csf = require("@storybook/csf");

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

var _clientLogger = require("@storybook/client-logger");

var _utilDeprecate = _interopRequireDefault(require("util-deprecate"));

var _normalizeInputTypes = require("./normalizeInputTypes");

var _templateObject;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) return _arrayLikeToArray(arr); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

var deprecatedStoryAnnotation = (0, _tsDedent.default)(_templateObject || (_templateObject = _taggedTemplateLiteral(["\nCSF .story annotations deprecated; annotate story functions directly:\n- StoryFn.story.name => StoryFn.storyName\n- StoryFn.story.(parameters|decorators) => StoryFn.(parameters|decorators)\nSee https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#hoisted-csf-annotations for details and codemod.\n"])));
var deprecatedStoryAnnotationWarning = (0, _utilDeprecate.default)(function () {}, deprecatedStoryAnnotation);

function normalizeStory(key, storyAnnotations, meta) {
  var userStoryFn;
  var storyObject;

  if (typeof storyAnnotations === 'function') {
    userStoryFn = storyAnnotations;
    storyObject = storyAnnotations;
  } else {
    storyObject = storyAnnotations;
  }

  var _storyObject = storyObject,
      story = _storyObject.story;

  if (story) {
    _clientLogger.logger.debug('deprecated story', story);

    deprecatedStoryAnnotationWarning();
  }

  var exportName = (0, _csf.storyNameFromExport)(key);
  var name = typeof storyObject !== 'function' && storyObject.name || storyObject.storyName || (story === null || story === void 0 ? void 0 : story.name) || exportName;
  var decorators = [].concat(_toConsumableArray(storyObject.decorators || []), _toConsumableArray((story === null || story === void 0 ? void 0 : story.decorators) || []));
  var parameters = Object.assign({}, story === null || story === void 0 ? void 0 : story.parameters, storyObject.parameters);
  var args = Object.assign({}, story === null || story === void 0 ? void 0 : story.args, storyObject.args);
  var argTypes = Object.assign({}, story === null || story === void 0 ? void 0 : story.argTypes, storyObject.argTypes);
  var loaders = [].concat(_toConsumableArray(storyObject.loaders || []), _toConsumableArray((story === null || story === void 0 ? void 0 : story.loaders) || []));
  var _storyObject2 = storyObject,
      render = _storyObject2.render,
      play = _storyObject2.play; // eslint-disable-next-line no-underscore-dangle

  var id = parameters.__id || (0, _csf.toId)(meta.id || meta.title, exportName);
  return Object.assign({
    id: id,
    name: name,
    decorators: decorators,
    parameters: parameters,
    args: args,
    argTypes: (0, _normalizeInputTypes.normalizeInputTypes)(argTypes),
    loaders: loaders
  }, render && {
    render: render
  }, userStoryFn && {
    userStoryFn: userStoryFn
  }, play && {
    play: play
  });
}
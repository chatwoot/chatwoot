import "core-js/modules/es.object.keys.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.array.from.js";
import "core-js/modules/es.regexp.exec.js";
var _excluded = ["default", "__esModule", "__namedExportsOrder"];

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

import "core-js/modules/es.function.name.js";
import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.object.entries.js";
import { isExportStory } from '@storybook/csf';
import { composeConfigs } from '../composeConfigs';
import { prepareStory } from '../prepareStory';
import { normalizeStory } from '../normalizeStory';
import { HooksContext } from '../../hooks';
import { normalizeComponentAnnotations } from '../normalizeComponentAnnotations';
import { getValuesFromArgTypes } from '../getValuesFromArgTypes';
import { normalizeProjectAnnotations } from '../normalizeProjectAnnotations';
export * from './types';
var GLOBAL_STORYBOOK_PROJECT_ANNOTATIONS = {};
export function setProjectAnnotations(projectAnnotations) {
  GLOBAL_STORYBOOK_PROJECT_ANNOTATIONS = Array.isArray(projectAnnotations) ? composeConfigs(projectAnnotations) : projectAnnotations;
}
export function composeStory(storyAnnotations, componentAnnotations) {
  var _componentAnnotations, _storyAnnotations$sto;

  var projectAnnotations = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : GLOBAL_STORYBOOK_PROJECT_ANNOTATIONS;
  var defaultConfig = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : {};
  var exportsName = arguments.length > 4 ? arguments[4] : undefined;

  if (storyAnnotations === undefined) {
    throw new Error('Expected a story but received undefined.');
  } // @TODO: Support auto title
  // eslint-disable-next-line no-param-reassign


  componentAnnotations.title = (_componentAnnotations = componentAnnotations.title) !== null && _componentAnnotations !== void 0 ? _componentAnnotations : 'ComposedStory';
  var normalizedComponentAnnotations = normalizeComponentAnnotations(componentAnnotations);
  var storyName = exportsName || storyAnnotations.storyName || ((_storyAnnotations$sto = storyAnnotations.story) === null || _storyAnnotations$sto === void 0 ? void 0 : _storyAnnotations$sto.name) || storyAnnotations.name;
  var normalizedStory = normalizeStory(storyName, storyAnnotations, normalizedComponentAnnotations);
  var normalizedProjectAnnotations = normalizeProjectAnnotations(Object.assign({}, projectAnnotations, defaultConfig));
  var story = prepareStory(normalizedStory, normalizedComponentAnnotations, normalizedProjectAnnotations);
  var defaultGlobals = getValuesFromArgTypes(projectAnnotations.globalTypes);

  var composedStory = function composedStory(extraArgs) {
    var context = Object.assign({}, story, {
      hooks: new HooksContext(),
      globals: defaultGlobals,
      args: Object.assign({}, story.initialArgs, extraArgs)
    });
    return story.unboundStoryFn(context);
  };

  composedStory.storyName = storyName;
  composedStory.args = story.initialArgs;
  composedStory.play = story.playFunction;
  composedStory.parameters = story.parameters;
  return composedStory;
}
export function composeStories(storiesImport, globalConfig, composeStoryFn) {
  var meta = storiesImport.default,
      __esModule = storiesImport.__esModule,
      __namedExportsOrder = storiesImport.__namedExportsOrder,
      stories = _objectWithoutProperties(storiesImport, _excluded);

  var composedStories = Object.entries(stories).reduce(function (storiesMap, _ref) {
    var _ref2 = _slicedToArray(_ref, 2),
        exportsName = _ref2[0],
        story = _ref2[1];

    if (!isExportStory(exportsName, meta)) {
      return storiesMap;
    }

    var result = Object.assign(storiesMap, _defineProperty({}, exportsName, composeStoryFn(story, meta, globalConfig, exportsName)));
    return result;
  }, {});
  return composedStories;
}
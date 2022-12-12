import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.object.freeze.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.array.from.js";
import "core-js/modules/es.regexp.exec.js";

var _templateObject;

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

import "core-js/modules/es.object.keys.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/web.dom-collections.for-each.js";
import "core-js/modules/es.object.entries.js";
import "core-js/modules/es.object.assign.js";

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

import deprecate from 'util-deprecate';
import dedent from 'ts-dedent';
import { isStory } from '../lib/stories';
var warnDisabledDeprecated = deprecate(function () {}, dedent(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n    Use 'parameters.key.disable' instead of 'parameters.key.disabled'.\n    \n    https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-disabled-parameter\n  "]))));
export var types;

(function (types) {
  types["TAB"] = "tab";
  types["PANEL"] = "panel";
  types["TOOL"] = "tool";
  types["PREVIEW"] = "preview";
  types["NOTES_ELEMENT"] = "notes-element";
})(types || (types = {}));

export function ensurePanel(panels, selectedPanel, currentPanel) {
  var keys = Object.keys(panels);

  if (keys.indexOf(selectedPanel) >= 0) {
    return selectedPanel;
  }

  if (keys.length) {
    return keys[0];
  }

  return currentPanel;
}
export var init = function init(_ref) {
  var provider = _ref.provider,
      store = _ref.store,
      fullAPI = _ref.fullAPI;
  var api = {
    getElements: function getElements(type) {
      return provider.getElements(type);
    },
    getPanels: function getPanels() {
      return api.getElements(types.PANEL);
    },
    getStoryPanels: function getStoryPanels() {
      var allPanels = api.getPanels();

      var _store$getState = store.getState(),
          storyId = _store$getState.storyId;

      var story = fullAPI.getData(storyId);

      if (!allPanels || !story || !isStory(story)) {
        return allPanels;
      }

      var parameters = story.parameters;
      var filteredPanels = {};
      Object.entries(allPanels).forEach(function (_ref2) {
        var _ref3 = _slicedToArray(_ref2, 2),
            id = _ref3[0],
            panel = _ref3[1];

        var paramKey = panel.paramKey;

        if (paramKey && parameters && parameters[paramKey] && (parameters[paramKey].disabled || parameters[paramKey].disable)) {
          if (parameters[paramKey].disabled) {
            warnDisabledDeprecated();
          }

          return;
        }

        filteredPanels[id] = panel;
      });
      return filteredPanels;
    },
    getSelectedPanel: function getSelectedPanel() {
      var _store$getState2 = store.getState(),
          selectedPanel = _store$getState2.selectedPanel;

      return ensurePanel(api.getPanels(), selectedPanel, selectedPanel);
    },
    setSelectedPanel: function setSelectedPanel(panelName) {
      store.setState({
        selectedPanel: panelName
      }, {
        persistence: 'session'
      });
    },
    setAddonState: function setAddonState(addonId, newStateOrMerger, options) {
      var nextState;

      var _store$getState3 = store.getState(),
          existing = _store$getState3.addons;

      if (typeof newStateOrMerger === 'function') {
        var merger = newStateOrMerger;
        nextState = merger(api.getAddonState(addonId));
      } else {
        nextState = newStateOrMerger;
      }

      return store.setState({
        addons: Object.assign({}, existing, _defineProperty({}, addonId, nextState))
      }, options).then(function () {
        return api.getAddonState(addonId);
      });
    },
    getAddonState: function getAddonState(addonId) {
      return store.getState().addons[addonId];
    }
  };
  return {
    api: api,
    state: {
      selectedPanel: ensurePanel(api.getPanels(), store.getState().selectedPanel),
      addons: {}
    }
  };
};
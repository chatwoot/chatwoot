var _templateObject;

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

import "core-js/modules/es.object.keys.js";
import "core-js/modules/es.array.find.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.string.starts-with.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.object.entries.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.array.from.js";
import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.object.freeze.js";

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

import dedent from 'ts-dedent';
export var StoryIndexStore = /*#__PURE__*/function () {
  function StoryIndexStore() {
    var _ref = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {
      v: 3,
      stories: {}
    },
        stories = _ref.stories;

    _classCallCheck(this, StoryIndexStore);

    this.channel = void 0;
    this.stories = void 0;
    this.stories = stories;
  }

  _createClass(StoryIndexStore, [{
    key: "storyIdFromSpecifier",
    value: function storyIdFromSpecifier(specifier) {
      var storyIds = Object.keys(this.stories);

      if (specifier === '*') {
        // '*' means select the first story. If there is none, we have no selection.
        return storyIds[0];
      }

      if (typeof specifier === 'string') {
        // Find the story with the exact id that matches the specifier (see #11571)
        if (storyIds.indexOf(specifier) >= 0) {
          return specifier;
        } // Fallback to the first story that starts with the specifier


        return storyIds.find(function (storyId) {
          return storyId.startsWith(specifier);
        });
      } // Try and find a story matching the name/kind, setting no selection if they don't exist.


      var name = specifier.name,
          title = specifier.title;
      var match = Object.entries(this.stories).find(function (_ref2) {
        var _ref3 = _slicedToArray(_ref2, 2),
            id = _ref3[0],
            story = _ref3[1];

        return story.name === name && story.title === title;
      });
      return match && match[0];
    }
  }, {
    key: "storyIdToEntry",
    value: function storyIdToEntry(storyId) {
      var storyEntry = this.stories[storyId];

      if (!storyEntry) {
        throw new Error(dedent(_templateObject || (_templateObject = _taggedTemplateLiteral(["Couldn't find story matching '", "' after HMR.\n      - Did you remove it from your CSF file?\n      - Are you sure a story with that id exists?\n      - Please check your stories field of your main.js config.\n      - Also check the browser console and terminal for error messages."])), storyId));
      }

      return storyEntry;
    }
  }]);

  return StoryIndexStore;
}();
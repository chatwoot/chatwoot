"use strict";

require("core-js/modules/es.object.freeze.js");

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.array.from.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.WebView = void 0;

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.string.search.js");

require("core-js/modules/es.array.join.js");

require("core-js/modules/es.object.keys.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/web.dom-collections.for-each.js");

require("core-js/modules/es.string.split.js");

require("core-js/modules/es.array.slice.js");

var _global = _interopRequireDefault(require("global"));

var _clientLogger = require("@storybook/client-logger");

var _ansiToHtml = _interopRequireDefault(require("ansi-to-html"));

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

var _qs = _interopRequireDefault(require("qs"));

var _templateObject;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

var document = _global.default.document;
var PREPARING_DELAY = 100;
var layoutClassMap = {
  centered: 'sb-main-centered',
  fullscreen: 'sb-main-fullscreen',
  padded: 'sb-main-padded'
};
var Mode;

(function (Mode) {
  Mode["MAIN"] = "MAIN";
  Mode["NOPREVIEW"] = "NOPREVIEW";
  Mode["PREPARING_STORY"] = "PREPARING_STORY";
  Mode["PREPARING_DOCS"] = "PREPARING_DOCS";
  Mode["ERROR"] = "ERROR";
})(Mode || (Mode = {}));

var classes = {
  PREPARING_STORY: 'sb-show-preparing-story',
  PREPARING_DOCS: 'sb-show-preparing-docs',
  MAIN: 'sb-show-main',
  NOPREVIEW: 'sb-show-nopreview',
  ERROR: 'sb-show-errordisplay'
};
var ansiConverter = new _ansiToHtml.default({
  escapeXML: true
});

var WebView = /*#__PURE__*/function () {
  function WebView() {
    _classCallCheck(this, WebView);

    this.currentLayoutClass = void 0;
    this.testing = false;
    this.preparingTimeout = null;

    // Special code for testing situations
    var _qs$parse = _qs.default.parse(document.location.search, {
      ignoreQueryPrefix: true
    }),
        __SPECIAL_TEST_PARAMETER__ = _qs$parse.__SPECIAL_TEST_PARAMETER__;

    switch (__SPECIAL_TEST_PARAMETER__) {
      case 'preparing-story':
        {
          this.showPreparingStory();
          this.testing = true;
          break;
        }

      case 'preparing-docs':
        {
          this.showPreparingDocs();
          this.testing = true;
          break;
        }

      default: // pass;

    }
  } // Get ready to render a story, returning the element to render to


  _createClass(WebView, [{
    key: "prepareForStory",
    value: function prepareForStory(story) {
      this.showStory();
      this.applyLayout(story.parameters.layout);
      document.documentElement.scrollTop = 0;
      document.documentElement.scrollLeft = 0;
      return this.storyRoot();
    }
  }, {
    key: "storyRoot",
    value: function storyRoot() {
      return document.getElementById('root');
    }
  }, {
    key: "prepareForDocs",
    value: function prepareForDocs() {
      this.showMain();
      this.showDocs();
      this.applyLayout('fullscreen');
      return this.docsRoot();
    }
  }, {
    key: "docsRoot",
    value: function docsRoot() {
      return document.getElementById('docs-root');
    }
  }, {
    key: "applyLayout",
    value: function applyLayout() {
      var layout = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : 'padded';

      if (layout === 'none') {
        document.body.classList.remove(this.currentLayoutClass);
        this.currentLayoutClass = null;
        return;
      }

      this.checkIfLayoutExists(layout);
      var layoutClass = layoutClassMap[layout];
      document.body.classList.remove(this.currentLayoutClass);
      document.body.classList.add(layoutClass);
      this.currentLayoutClass = layoutClass;
    }
  }, {
    key: "checkIfLayoutExists",
    value: function checkIfLayoutExists(layout) {
      if (!layoutClassMap[layout]) {
        _clientLogger.logger.warn((0, _tsDedent.default)(_templateObject || (_templateObject = _taggedTemplateLiteral(["The desired layout: ", " is not a valid option.\n         The possible options are: ", ", none."])), layout, Object.keys(layoutClassMap).join(', ')));
      }
    }
  }, {
    key: "showMode",
    value: function showMode(mode) {
      clearTimeout(this.preparingTimeout);
      Object.keys(Mode).forEach(function (otherMode) {
        if (otherMode === mode) {
          document.body.classList.add(classes[otherMode]);
        } else {
          document.body.classList.remove(classes[otherMode]);
        }
      });
    }
  }, {
    key: "showErrorDisplay",
    value: function showErrorDisplay(_ref) {
      var _ref$message = _ref.message,
          message = _ref$message === void 0 ? '' : _ref$message,
          _ref$stack = _ref.stack,
          stack = _ref$stack === void 0 ? '' : _ref$stack;
      var header = message;
      var detail = stack;
      var parts = message.split('\n');

      if (parts.length > 1) {
        var _parts = _slicedToArray(parts, 1);

        header = _parts[0];
        detail = parts.slice(1).join('\n');
      }

      document.getElementById('error-message').innerHTML = ansiConverter.toHtml(header);
      document.getElementById('error-stack').innerHTML = ansiConverter.toHtml(detail);
      this.showMode(Mode.ERROR);
    }
  }, {
    key: "showNoPreview",
    value: function showNoPreview() {
      var _this$storyRoot, _this$docsRoot;

      if (this.testing) return;
      this.showMode(Mode.NOPREVIEW); // In storyshots this can get called and these two can be null

      (_this$storyRoot = this.storyRoot()) === null || _this$storyRoot === void 0 ? void 0 : _this$storyRoot.setAttribute('hidden', 'true');
      (_this$docsRoot = this.docsRoot()) === null || _this$docsRoot === void 0 ? void 0 : _this$docsRoot.setAttribute('hidden', 'true');
    }
  }, {
    key: "showPreparingStory",
    value: function showPreparingStory() {
      var _this = this;

      var _ref2 = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {},
          _ref2$immediate = _ref2.immediate,
          immediate = _ref2$immediate === void 0 ? false : _ref2$immediate;

      clearTimeout(this.preparingTimeout);

      if (immediate) {
        this.showMode(Mode.PREPARING_STORY);
      } else {
        this.preparingTimeout = setTimeout(function () {
          return _this.showMode(Mode.PREPARING_STORY);
        }, PREPARING_DELAY);
      }
    }
  }, {
    key: "showPreparingDocs",
    value: function showPreparingDocs() {
      var _this2 = this;

      clearTimeout(this.preparingTimeout);
      this.preparingTimeout = setTimeout(function () {
        return _this2.showMode(Mode.PREPARING_DOCS);
      }, PREPARING_DELAY);
    }
  }, {
    key: "showMain",
    value: function showMain() {
      this.showMode(Mode.MAIN);
    }
  }, {
    key: "showDocs",
    value: function showDocs() {
      this.storyRoot().setAttribute('hidden', 'true');
      this.docsRoot().removeAttribute('hidden');
    }
  }, {
    key: "showStory",
    value: function showStory() {
      this.docsRoot().setAttribute('hidden', 'true');
      this.storyRoot().removeAttribute('hidden');
    }
  }, {
    key: "showStoryDuringRender",
    value: function showStoryDuringRender() {
      // When 'showStory' is called (at the start of rendering) we get rid of our display:none
      // from all children of the root (but keep the preparing spinner visible). This may mean
      // that very weird and high z-index stories are briefly visible.
      // See https://github.com/storybookjs/storybook/issues/16847 and
      //   http://localhost:9011/?path=/story/core-rendering--auto-focus (official SB)
      document.body.classList.add(classes.MAIN);
    }
  }]);

  return WebView;
}();

exports.WebView = WebView;
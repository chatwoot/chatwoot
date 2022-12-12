"use strict";

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.object.freeze.js");

require("core-js/modules/es.weak-map.js");

require("core-js/modules/es.object.get-own-property-descriptor.js");

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.iterator.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.DocsContainer = void 0;

require("core-js/modules/es.object.assign.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/web.url.js");

require("core-js/modules/web.url-search-params.js");

var _react = _interopRequireWildcard(require("react"));

var _global = _interopRequireDefault(require("global"));

var _utilDeprecate = _interopRequireDefault(require("util-deprecate"));

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

var _react2 = require("@mdx-js/react");

var _theming = require("@storybook/theming");

var _components = require("@storybook/components");

var _DocsContext = require("./DocsContext");

var _Anchor = require("./Anchor");

var _Story = require("./Story");

var _SourceContainer = require("./SourceContainer");

var _mdx = require("./mdx");

var _utils = require("./utils");

var _templateObject;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function _getRequireWildcardCache(nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || _typeof(obj) !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

var document = _global.default.document,
    globalWindow = _global.default.window;
var defaultComponents = Object.assign({}, _components.components, {
  code: _mdx.CodeOrSourceMdx,
  a: _mdx.AnchorMdx
}, _mdx.HeadersMdx);
var warnOptionsTheme = (0, _utilDeprecate.default)(function () {}, (0, _tsDedent.default)(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n    Deprecated parameter: options.theme => docs.theme\n\n    https://github.com/storybookjs/storybook/blob/next/addons/docs/docs/theming.md#storybook-theming\n"]))));

var DocsContainer = function DocsContainer(_ref) {
  var context = _ref.context,
      children = _ref.children;
  var storyId = context.id,
      storyById = context.storyById;

  var _storyById = storyById(storyId),
      _storyById$parameters = _storyById.parameters,
      _storyById$parameters2 = _storyById$parameters.options,
      options = _storyById$parameters2 === void 0 ? {} : _storyById$parameters2,
      _storyById$parameters3 = _storyById$parameters.docs,
      docs = _storyById$parameters3 === void 0 ? {} : _storyById$parameters3;

  var themeVars = docs.theme;

  if (!themeVars && options.theme) {
    warnOptionsTheme();
    themeVars = options.theme;
  }

  var theme = (0, _theming.ensure)(themeVars);
  var allComponents = Object.assign({}, defaultComponents, docs.components);
  (0, _react.useEffect)(function () {
    var url;

    try {
      url = new URL(globalWindow.parent.location);
    } catch (err) {
      return;
    }

    if (url.hash) {
      var element = document.getElementById(url.hash.substring(1));

      if (element) {
        // Introducing a delay to ensure scrolling works when it's a full refresh.
        setTimeout(function () {
          (0, _utils.scrollToElement)(element);
        }, 200);
      }
    } else {
      var _element = document.getElementById((0, _Anchor.anchorBlockIdFromId)(storyId)) || document.getElementById((0, _Story.storyBlockIdFromId)(storyId));

      if (_element) {
        var allStories = _element.parentElement.querySelectorAll('[id|="anchor-"]');

        var scrollTarget = _element;

        if (allStories && allStories[0] === _element) {
          // Include content above first story
          scrollTarget = document.getElementById('docs-root');
        } // Introducing a delay to ensure scrolling works when it's a full refresh.


        setTimeout(function () {
          (0, _utils.scrollToElement)(scrollTarget, 'start');
        }, 200);
      }
    }
  }, [storyId]);
  return /*#__PURE__*/_react.default.createElement(_DocsContext.DocsContext.Provider, {
    value: context
  }, /*#__PURE__*/_react.default.createElement(_SourceContainer.SourceContainer, null, /*#__PURE__*/_react.default.createElement(_theming.ThemeProvider, {
    theme: theme
  }, /*#__PURE__*/_react.default.createElement(_react2.MDXProvider, {
    components: allComponents
  }, /*#__PURE__*/_react.default.createElement(_components.DocsWrapper, {
    className: "sbdocs sbdocs-wrapper"
  }, /*#__PURE__*/_react.default.createElement(_components.DocsContent, {
    className: "sbdocs sbdocs-content"
  }, children))))));
};

exports.DocsContainer = DocsContainer;
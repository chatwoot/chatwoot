"use strict";

require("core-js/modules/es.object.keys.js");

require("core-js/modules/es.symbol.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.assertIsFn = exports.HeadersMdx = exports.HeaderMdx = exports.CodeOrSourceMdx = exports.AnchorMdx = exports.AddContext = void 0;

require("core-js/modules/es.object.assign.js");

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.string.match.js");

require("core-js/modules/es.string.split.js");

require("core-js/modules/es.string.starts-with.js");

require("core-js/modules/es.object.to-string.js");

var _react = _interopRequireDefault(require("react"));

var _addons = require("@storybook/addons");

var _coreEvents = require("@storybook/core-events");

var _components = require("@storybook/components");

var _global = _interopRequireDefault(require("global"));

var _theming = require("@storybook/theming");

var _DocsContext = require("./DocsContext");

var _excluded = ["children"],
    _excluded2 = ["className", "children"],
    _excluded3 = ["href", "target", "children"],
    _excluded4 = ["as", "id", "children"],
    _excluded5 = ["as", "id", "children"];

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _extends() { _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; return _extends.apply(this, arguments); }

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

var document = _global.default.document; // Hacky utility for asserting identifiers in MDX Story elements

var assertIsFn = function assertIsFn(val) {
  if (typeof val !== 'function') {
    throw new Error("Expected story function, got: ".concat(val));
  }

  return val;
}; // Hacky utility for adding mdxStoryToId to the default context


exports.assertIsFn = assertIsFn;

var AddContext = function AddContext(props) {
  var children = props.children,
      rest = _objectWithoutProperties(props, _excluded);

  var parentContext = _react.default.useContext(_DocsContext.DocsContext);

  return /*#__PURE__*/_react.default.createElement(_DocsContext.DocsContext.Provider, {
    value: Object.assign({}, parentContext, rest)
  }, children);
};

exports.AddContext = AddContext;

var CodeOrSourceMdx = function CodeOrSourceMdx(_ref) {
  var className = _ref.className,
      children = _ref.children,
      rest = _objectWithoutProperties(_ref, _excluded2);

  // markdown-to-jsx does not add className to inline code
  if (typeof className !== 'string' && (typeof children !== 'string' || !children.match(/[\n\r]/g))) {
    return /*#__PURE__*/_react.default.createElement(_components.Code, null, children);
  } // className: "lang-jsx"


  var language = className && className.split('-');
  return /*#__PURE__*/_react.default.createElement(_components.Source, _extends({
    language: language && language[1] || 'plaintext',
    format: false,
    code: children
  }, rest));
};

exports.CodeOrSourceMdx = CodeOrSourceMdx;

function navigate(url) {
  _addons.addons.getChannel().emit(_coreEvents.NAVIGATE_URL, url);
} // @ts-ignore


var A = _components.components.a;

var AnchorInPage = function AnchorInPage(_ref2) {
  var hash = _ref2.hash,
      children = _ref2.children;
  return /*#__PURE__*/_react.default.createElement(A, {
    href: hash,
    target: "_self",
    onClick: function onClick(event) {
      var id = hash.substring(1);
      var element = document.getElementById(id);

      if (element) {
        navigate(hash);
      }
    }
  }, children);
};

var AnchorMdx = function AnchorMdx(props) {
  var href = props.href,
      target = props.target,
      children = props.children,
      rest = _objectWithoutProperties(props, _excluded3);

  if (href) {
    // Enable scrolling for in-page anchors.
    if (href.startsWith('#')) {
      return /*#__PURE__*/_react.default.createElement(AnchorInPage, {
        hash: href
      }, children);
    } // Links to other pages of SB should use the base URL of the top level iframe instead of the base URL of the preview iframe.


    if (target !== '_blank' && !href.startsWith('https://')) {
      return /*#__PURE__*/_react.default.createElement(A, _extends({
        href: href,
        onClick: function onClick(event) {
          event.preventDefault(); // use the A element's href, which has been modified for
          // local paths without a `?path=` query param prefix

          navigate(event.currentTarget.getAttribute('href'));
        },
        target: target
      }, rest), children);
    }
  } // External URL dont need any modification.


  return /*#__PURE__*/_react.default.createElement(A, props);
};

exports.AnchorMdx = AnchorMdx;
var SUPPORTED_MDX_HEADERS = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'];
var OcticonHeaders = SUPPORTED_MDX_HEADERS.reduce(function (acc, headerType) {
  return Object.assign({}, acc, _defineProperty({}, headerType, (0, _theming.styled)(_components.components[headerType])({
    '& svg': {
      visibility: 'hidden'
    },
    '&:hover svg': {
      visibility: 'visible'
    }
  })));
}, {});

var OcticonAnchor = _theming.styled.a(function () {
  return {
    float: 'left',
    paddingRight: '4px',
    marginLeft: '-20px',
    // Allow the theme's text color to override the default link color.
    color: 'inherit'
  };
});

var HeaderWithOcticonAnchor = function HeaderWithOcticonAnchor(_ref3) {
  var as = _ref3.as,
      id = _ref3.id,
      children = _ref3.children,
      rest = _objectWithoutProperties(_ref3, _excluded4);

  // @ts-ignore
  var OcticonHeader = OcticonHeaders[as];
  var hash = "#".concat(id);
  return /*#__PURE__*/_react.default.createElement(OcticonHeader, _extends({
    id: id
  }, rest), /*#__PURE__*/_react.default.createElement(OcticonAnchor, {
    "aria-hidden": "true",
    href: hash,
    tabIndex: -1,
    target: "_self",
    onClick: function onClick(event) {
      var element = document.getElementById(id);

      if (element) {
        navigate(hash);
      }
    }
  }, /*#__PURE__*/_react.default.createElement("svg", {
    viewBox: "0 0 16 16",
    version: "1.1",
    width: "16",
    height: "16",
    "aria-hidden": "true",
    fill: "currentColor"
  }, /*#__PURE__*/_react.default.createElement("path", {
    fillRule: "evenodd",
    d: "M4 9h1v1H4c-1.5 0-3-1.69-3-3.5S2.55 3 4 3h4c1.45 0 3 1.69 3 3.5 0 1.41-.91 2.72-2 3.25V8.59c.58-.45 1-1.27 1-2.09C10 5.22 8.98 4 8 4H4c-.98 0-2 1.22-2 2.5S3 9 4 9zm9-3h-1v1h1c1 0 2 1.22 2 2.5S13.98 12 13 12H9c-.98 0-2-1.22-2-2.5 0-.83.42-1.64 1-2.09V6.25c-1.09.53-2 1.84-2 3.25C6 11.31 7.55 13 9 13h4c1.45 0 3-1.69 3-3.5S14.5 6 13 6z"
  }))), children);
};

var HeaderMdx = function HeaderMdx(props) {
  var as = props.as,
      id = props.id,
      children = props.children,
      rest = _objectWithoutProperties(props, _excluded5); // An id should have been added on every header by the "remark-slug" plugin.


  if (id) {
    return /*#__PURE__*/_react.default.createElement(HeaderWithOcticonAnchor, _extends({
      as: as,
      id: id
    }, rest), children);
  } // @ts-ignore


  var Header = _components.components[as]; // Make sure it still work if "remark-slug" plugin is not present.

  return /*#__PURE__*/_react.default.createElement(Header, props);
};

exports.HeaderMdx = HeaderMdx;
var HeadersMdx = SUPPORTED_MDX_HEADERS.reduce(function (acc, headerType) {
  return Object.assign({}, acc, _defineProperty({}, headerType, function (props) {
    return /*#__PURE__*/_react.default.createElement(HeaderMdx, _extends({
      as: headerType
    }, props));
  }));
}, {});
exports.HeadersMdx = HeadersMdx;
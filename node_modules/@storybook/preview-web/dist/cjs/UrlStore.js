"use strict";

require("core-js/modules/es.object.keys.js");

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getSelectionSpecifierFromPath = exports.UrlStore = void 0;
exports.pathToId = pathToId;
exports.setPath = void 0;

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.string.match.js");

require("core-js/modules/es.string.search.js");

require("core-js/modules/es.object.assign.js");

require("core-js/modules/es.array.concat.js");

require("core-js/modules/es.object.values.js");

var _global = _interopRequireDefault(require("global"));

var _qs = _interopRequireDefault(require("qs"));

var _utilDeprecate = _interopRequireDefault(require("util-deprecate"));

var _parseArgsParam = require("./parseArgsParam");

var _excluded = ["path", "selectedKind", "selectedStory"];

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

var history = _global.default.history,
    document = _global.default.document;

function pathToId(path) {
  var match = (path || '').match(/^\/story\/(.+)/);

  if (!match) {
    throw new Error("Invalid path '".concat(path, "',  must start with '/story/'"));
  }

  return match[1];
}

var getQueryString = function getQueryString(_ref) {
  var selection = _ref.selection,
      extraParams = _ref.extraParams;
  var _document$location$se = document.location.search,
      search = _document$location$se === void 0 ? '' : _document$location$se;

  var _qs$parse = _qs.default.parse(search, {
    ignoreQueryPrefix: true
  }),
      path = _qs$parse.path,
      selectedKind = _qs$parse.selectedKind,
      selectedStory = _qs$parse.selectedStory,
      rest = _objectWithoutProperties(_qs$parse, _excluded);

  return _qs.default.stringify(Object.assign({}, rest, extraParams, selection && {
    id: selection.storyId,
    viewMode: selection.viewMode
  }), {
    encode: false,
    addQueryPrefix: true
  });
};

var setPath = function setPath(selection) {
  if (!selection) return;
  var query = getQueryString({
    selection: selection
  });
  var _document$location$ha = document.location.hash,
      hash = _document$location$ha === void 0 ? '' : _document$location$ha;
  document.title = selection.storyId;
  history.replaceState({}, '', "".concat(document.location.pathname).concat(query).concat(hash));
};

exports.setPath = setPath;

var isObject = function isObject(val) {
  return val != null && _typeof(val) === 'object' && Array.isArray(val) === false;
};

var getFirstString = function getFirstString(v) {
  if (typeof v === 'string') {
    return v;
  }

  if (Array.isArray(v)) {
    return getFirstString(v[0]);
  }

  if (isObject(v)) {
    // @ts-ignore
    return getFirstString(Object.values(v));
  }

  return undefined;
};

var deprecatedLegacyQuery = (0, _utilDeprecate.default)(function () {
  return 0;
}, "URL formats with `selectedKind` and `selectedName` query parameters are deprecated.\nUse `id=$storyId` instead.\nSee https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#new-url-structure");

var getSelectionSpecifierFromPath = function getSelectionSpecifierFromPath() {
  var query = _qs.default.parse(document.location.search, {
    ignoreQueryPrefix: true
  });

  var args = typeof query.args === 'string' ? (0, _parseArgsParam.parseArgsParam)(query.args) : undefined;
  var globals = typeof query.globals === 'string' ? (0, _parseArgsParam.parseArgsParam)(query.globals) : undefined;
  var viewMode = getFirstString(query.viewMode);

  if (typeof viewMode !== 'string' || !viewMode.match(/docs|story/)) {
    viewMode = 'story';
  }

  var path = getFirstString(query.path);
  var storyId = path ? pathToId(path) : getFirstString(query.id);

  if (storyId) {
    return {
      storySpecifier: storyId,
      args: args,
      globals: globals,
      viewMode: viewMode
    };
  } // Legacy URL format


  var title = getFirstString(query.selectedKind);
  var name = getFirstString(query.selectedStory);

  if (title && name) {
    deprecatedLegacyQuery();
    return {
      storySpecifier: {
        title: title,
        name: name
      },
      args: args,
      globals: globals,
      viewMode: viewMode
    };
  }

  return null;
};

exports.getSelectionSpecifierFromPath = getSelectionSpecifierFromPath;

var UrlStore = /*#__PURE__*/function () {
  function UrlStore() {
    _classCallCheck(this, UrlStore);

    this.selectionSpecifier = void 0;
    this.selection = void 0;
    this.selectionSpecifier = getSelectionSpecifierFromPath();
  }

  _createClass(UrlStore, [{
    key: "setSelection",
    value: function setSelection(selection) {
      this.selection = selection;
      setPath(this.selection);
    }
  }, {
    key: "setQueryParams",
    value: function setQueryParams(queryParams) {
      var query = getQueryString({
        extraParams: queryParams
      });
      var _document$location$ha2 = document.location.hash,
          hash = _document$location$ha2 === void 0 ? '' : _document$location$ha2;
      history.replaceState({}, '', "".concat(document.location.pathname).concat(query).concat(hash));
    }
  }]);

  return UrlStore;
}();

exports.UrlStore = UrlStore;
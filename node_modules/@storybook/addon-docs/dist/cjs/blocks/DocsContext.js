"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.DocsContext = void 0;

var _react = require("react");

var _global = require("global");

// We add DocsContext to window. The reason is that in case DocsContext.ts is
// imported multiple times (maybe once directly, and another time from a minified bundle)
// we will have multiple DocsContext definitions - leading to lost context in
// the React component tree.
// This was specifically a problem with the Vite builder.

/* eslint-disable no-underscore-dangle */
if (_global.window && _global.window.__DOCS_CONTEXT__ === undefined) {
  _global.window.__DOCS_CONTEXT__ = /*#__PURE__*/(0, _react.createContext)({});
  _global.window.__DOCS_CONTEXT__.displayName = 'DocsContext';
}

var DocsContext = _global.window ? _global.window.__DOCS_CONTEXT__ : /*#__PURE__*/(0, _react.createContext)({});
exports.DocsContext = DocsContext;
"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;
var withParams = process.env.BUILD === 'web' ? require('./withParamsBrowser').withParams : require('./params').withParams;
var _default = withParams;
exports.default = _default;
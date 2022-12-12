"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getQueryParams = exports.getQueryParam = void 0;

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.string.search.js");

var _global = _interopRequireDefault(require("global"));

var _qs = require("qs");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var document = _global.default.document;

var getQueryParams = function getQueryParams() {
  // document.location is not defined in react-native
  if (document && document.location && document.location.search) {
    return (0, _qs.parse)(document.location.search, {
      ignoreQueryPrefix: true
    });
  }

  return {};
};

exports.getQueryParams = getQueryParams;

var getQueryParam = function getQueryParam(key) {
  var params = getQueryParams();
  return params[key];
};

exports.getQueryParam = getQueryParam;
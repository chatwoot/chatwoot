"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.trimQuotes = exports.includesQuotes = void 0;

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.string.replace.js");

var QUOTE_REGEX = /^['"]|['"]$/g;

var trimQuotes = function trimQuotes(str) {
  return str.replace(QUOTE_REGEX, '');
};

exports.trimQuotes = trimQuotes;

var includesQuotes = function includesQuotes(str) {
  return QUOTE_REGEX.test(str);
};

exports.includesQuotes = includesQuotes;
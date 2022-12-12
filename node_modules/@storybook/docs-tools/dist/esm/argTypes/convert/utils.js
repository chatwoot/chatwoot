import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.string.replace.js";
var QUOTE_REGEX = /^['"]|['"]$/g;
export var trimQuotes = function trimQuotes(str) {
  return str.replace(QUOTE_REGEX, '');
};
export var includesQuotes = function includesQuotes(str) {
  return QUOTE_REGEX.test(str);
};
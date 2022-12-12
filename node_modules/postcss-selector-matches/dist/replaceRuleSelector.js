"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = replaceRuleSelector;

var _list = require("postcss/lib/list");

var _list2 = _interopRequireDefault(_list);

var _balancedMatch = require("balanced-match");

var _balancedMatch2 = _interopRequireDefault(_balancedMatch);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _toConsumableArray(arr) { if (Array.isArray(arr)) { for (var i = 0, arr2 = Array(arr.length); i < arr.length; i++) { arr2[i] = arr[i]; } return arr2; } else { return Array.from(arr); } }

var pseudoClass = ":matches";
var selectorElementRE = /^[a-zA-Z]/;

function isElementSelector(selector) {
  var matches = selectorElementRE.exec(selector);
  // console.log({selector, matches})
  return matches;
}

function normalizeSelector(selector, preWhitespace, pre) {
  if (isElementSelector(selector) && !isElementSelector(pre)) {
    return `${preWhitespace}${selector}${pre}`;
  }

  return `${preWhitespace}${pre}${selector}`;
}

function explodeSelector(selector, options) {
  if (selector && selector.indexOf(pseudoClass) > -1) {
    var newSelectors = [];
    var preWhitespaceMatches = selector.match(/^\s+/);
    var preWhitespace = preWhitespaceMatches ? preWhitespaceMatches[0] : "";
    var selectorPart = _list2.default.comma(selector);
    selectorPart.forEach(function (part) {
      var position = part.indexOf(pseudoClass);
      var pre = part.slice(0, position);
      var body = part.slice(position);
      var matches = (0, _balancedMatch2.default)("(", ")", body);

      var bodySelectors = matches && matches.body ? _list2.default.comma(matches.body).reduce(function (acc, s) {
        return [].concat(_toConsumableArray(acc), _toConsumableArray(explodeSelector(s, options)));
      }, []) : [body];

      var postSelectors = matches && matches.post ? explodeSelector(matches.post, options) : [];

      var newParts = void 0;
      if (postSelectors.length === 0) {
        // the test below is a poor way to try we are facing a piece of a
        // selector...
        if (position === -1 || pre.indexOf(" ") > -1) {
          newParts = bodySelectors.map(function (s) {
            return preWhitespace + pre + s;
          });
        } else {
          newParts = bodySelectors.map(function (s) {
            return normalizeSelector(s, preWhitespace, pre);
          });
        }
      } else {
        newParts = [];
        postSelectors.forEach(function (postS) {
          bodySelectors.forEach(function (s) {
            newParts.push(preWhitespace + pre + s + postS);
          });
        });
      }
      newSelectors = [].concat(_toConsumableArray(newSelectors), _toConsumableArray(newParts));
    });

    return newSelectors;
  }
  return [selector];
}

function replaceRuleSelector(rule, options) {
  var indentation = rule.raws && rule.raws.before ? rule.raws.before.split("\n").pop() : "";
  return explodeSelector(rule.selector, options).join("," + (options.lineBreak ? "\n" + indentation : " "));
}
module.exports = exports.default;
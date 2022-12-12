"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _postcss = require("postcss");

var _postcss2 = _interopRequireDefault(_postcss);

var _list = require("postcss/lib/list");

var _list2 = _interopRequireDefault(_list);

var _balancedMatch = require("balanced-match");

var _balancedMatch2 = _interopRequireDefault(_balancedMatch);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function explodeSelector(pseudoClass, selector) {
  var position = locatePseudoClass(selector, pseudoClass);
  if (selector && position > -1) {
    var pre = selector.slice(0, position);
    var matches = (0, _balancedMatch2.default)("(", ")", selector.slice(position));

    if (!matches) {
      return selector;
    }

    var bodySelectors = matches.body ? _list2.default.comma(matches.body).map(function (s) {
      return explodeSelector(pseudoClass, s);
    }).join(`)${pseudoClass}(`) : "";
    var postSelectors = matches.post ? explodeSelector(pseudoClass, matches.post) : "";

    return `${pre}${pseudoClass}(${bodySelectors})${postSelectors}`;
  }
  return selector;
}

var patternCache = {};

function locatePseudoClass(selector, pseudoClass) {
  patternCache[pseudoClass] = patternCache[pseudoClass] || new RegExp(`([^\\\\]|^)${pseudoClass}`);

  // The regex is used to ensure that selectors with
  // escaped colons in them are treated properly
  // Ex: .foo\:not-bar is a valid CSS selector
  // But it is not a reference to a pseudo selector
  var pattern = patternCache[pseudoClass];
  var position = selector.search(pattern);

  if (position === -1) {
    return -1;
  }

  // The offset returned by the regex may be off by one because
  // of it including the negated character match in the position
  return position + selector.slice(position).indexOf(pseudoClass);
}

function explodeSelectors(pseudoClass) {
  return function () {
    return function (css) {
      css.walkRules(function (rule) {
        if (rule.selector && rule.selector.indexOf(pseudoClass) > -1) {
          rule.selector = explodeSelector(pseudoClass, rule.selector);
        }
      });
    };
  };
}

exports.default = _postcss2.default.plugin("postcss-selector-not", explodeSelectors(":not"));
module.exports = exports.default;
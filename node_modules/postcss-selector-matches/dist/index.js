"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _postcss = require("postcss");

var _postcss2 = _interopRequireDefault(_postcss);

var _replaceRuleSelector = require("./replaceRuleSelector");

var _replaceRuleSelector2 = _interopRequireDefault(_replaceRuleSelector);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function explodeSelectors() {
  var options = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};

  return function (css) {
    css.walkRules(function (rule) {
      if (rule.selector && rule.selector.indexOf(":matches") > -1) {
        rule.selector = (0, _replaceRuleSelector2.default)(rule, options);
      }
    });
  };
}

exports.default = _postcss2.default.plugin("postcss-selector-matches", explodeSelectors);
module.exports = exports.default;
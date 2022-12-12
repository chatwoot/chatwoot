"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = _default;

var _buildSelectorVariant = _interopRequireDefault(require("../util/buildSelectorVariant"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _default({
  addVariant,
  config,
  postcss,
  prefix
}) {
  addVariant('dark', ({
    container,
    separator,
    modifySelectors
  }) => {
    if (config('dark') === false) {
      return postcss.root();
    }

    if (config('dark') === 'media') {
      const modified = modifySelectors(({
        selector
      }) => {
        return (0, _buildSelectorVariant.default)(selector, 'dark', separator, message => {
          throw container.error(message);
        });
      });
      const mediaQuery = postcss.atRule({
        name: 'media',
        params: '(prefers-color-scheme: dark)'
      });
      mediaQuery.append(modified);
      container.append(mediaQuery);
      return container;
    }

    if (config('dark') === 'class') {
      const modified = modifySelectors(({
        selector
      }) => {
        return (0, _buildSelectorVariant.default)(selector, 'dark', separator, message => {
          throw container.error(message);
        });
      });
      modified.walkRules(rule => {
        rule.selectors = rule.selectors.map(selector => {
          return `${prefix('.dark')} ${selector}`;
        });
      });
      return modified;
    }

    throw new Error("The `dark` config option must be either 'media' or 'class'.");
  }, {
    unstable_stack: true
  });
}
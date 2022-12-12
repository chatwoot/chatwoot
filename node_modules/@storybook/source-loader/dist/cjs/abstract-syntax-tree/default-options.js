"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;
var defaultOptions = {
  prettierConfig: {
    printWidth: 100,
    tabWidth: 2,
    bracketSpacing: true,
    trailingComma: 'es5',
    singleQuote: true
  },
  uglyCommentsRegex: [/^eslint-.*/, /^global.*/]
};
var _default = defaultOptions;
exports.default = _default;
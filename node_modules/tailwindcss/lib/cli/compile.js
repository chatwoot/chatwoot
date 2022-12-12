"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = compile;

var _postcss = _interopRequireDefault(require("postcss"));

var utils = _interopRequireWildcard(require("./utils"));

function _getRequireWildcardCache() { if (typeof WeakMap !== "function") return null; var cache = new WeakMap(); _getRequireWildcardCache = function () { return cache; }; return cache; }

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } if (obj === null || typeof obj !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * Compiler options
 *
 * @typedef {Object} CompileOptions
 * @property {string} inputFile
 * @property {string} outputFile
 * @property {array} plugins
 */
const defaultOptions = {
  inputFile: null,
  outputFile: null,
  plugins: []
};
/**
 * Compiles CSS file.
 *
 * @param {CompileOptions} options
 * @return {Promise}
 */

function compile(options = {}) {
  const config = { ...defaultOptions,
    ...options
  };
  const css = config.inputFile ? utils.readFile(config.inputFile) : `
    @tailwind base;
    @tailwind components;
    @tailwind utilities;
  `;
  return new Promise((resolve, reject) => {
    (0, _postcss.default)(config.plugins).process(css, {
      from: config.inputFile,
      to: config.outputFile
    }).then(resolve).catch(reject);
  });
}
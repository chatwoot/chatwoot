"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.parseCliParams = parseCliParams;
exports.parseCliOptions = parseCliOptions;
exports.log = log;
exports.header = header;
exports.footer = footer;
exports.error = error;
exports.die = die;
exports.exists = exists;
exports.copyFile = copyFile;
exports.readFile = readFile;
exports.writeFile = writeFile;
exports.getSimplePath = getSimplePath;

var _fsExtra = require("fs-extra");

var _lodash = require("lodash");

var colors = _interopRequireWildcard(require("./colors"));

var emoji = _interopRequireWildcard(require("./emoji"));

var _package = _interopRequireDefault(require("../../package.json"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _getRequireWildcardCache() { if (typeof WeakMap !== "function") return null; var cache = new WeakMap(); _getRequireWildcardCache = function () { return cache; }; return cache; }

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } if (obj === null || typeof obj !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

/**
 * Gets CLI parameters.
 *
 * @param {string[]} cliArgs
 * @return {string[]}
 */
function parseCliParams(cliArgs) {
  const firstOptionIndex = cliArgs.findIndex(cliArg => cliArg.startsWith('-'));
  return firstOptionIndex > -1 ? cliArgs.slice(0, firstOptionIndex) : cliArgs;
}
/**
 * Gets mapped CLI options.
 *
 * @param {string[]} cliArgs
 * @param {object} [optionMap]
 * @return {object}
 */


function parseCliOptions(cliArgs, optionMap = {}) {
  let options = {};
  let currentOption = [];
  cliArgs.forEach(cliArg => {
    const option = cliArg.startsWith('-') && (0, _lodash.trimStart)(cliArg, '-').toLowerCase();
    const resolvedOption = (0, _lodash.findKey)(optionMap, aliases => aliases.includes(option));

    if (resolvedOption) {
      currentOption = options[resolvedOption] || (options[resolvedOption] = []);
    } else if (option) {
      currentOption = [];
    } else {
      currentOption.push(cliArg);
    }
  });
  return { ...(0, _lodash.mapValues)(optionMap, () => undefined),
    ...options
  };
}
/**
 * Prints messages to console.
 *
 * @param {...string} [msgs]
 */


function log(...msgs) {
  console.log('  ', ...msgs);
}
/**
 * Prints application header to console.
 */


function header() {
  log();
  log(colors.bold(_package.default.name), colors.info(_package.default.version));
}
/**
 * Prints application footer to console.
 */


function footer() {
  log();
}
/**
 * Prints error messages to console.
 *
 * @param {...string} [msgs]
 */


function error(...msgs) {
  log();
  console.error('  ', emoji.no, colors.error(msgs.join(' ')));
}
/**
 * Kills the process. Optionally prints error messages to console.
 *
 * @param {...string} [msgs]
 */


function die(...msgs) {
  msgs.length && error(...msgs);
  footer();
  process.exit(1); // eslint-disable-line
}
/**
 * Checks if path exists.
 *
 * @param {string} path
 * @return {boolean}
 */


function exists(path) {
  return (0, _fsExtra.existsSync)(path);
}
/**
 * Copies file source to destination.
 *
 * @param {string} source
 * @param {string} destination
 */


function copyFile(source, destination) {
  (0, _fsExtra.copyFileSync)(source, destination);
}
/**
 * Gets file content.
 *
 * @param {string} path
 * @return {string}
 */


function readFile(path) {
  return (0, _fsExtra.readFileSync)(path, 'utf-8');
}
/**
 * Writes content to file.
 *
 * @param {string} path
 * @param {string} content
 * @return {string}
 */


function writeFile(path, content) {
  (0, _fsExtra.ensureFileSync)(path);
  return (0, _fsExtra.outputFileSync)(path, content);
}
/**
 * Strips leading ./ from path
 *
 * @param {string} path
 * @return {string}
 */


function getSimplePath(path) {
  return (0, _lodash.startsWith)(path, './') ? path.slice(2) : path;
}
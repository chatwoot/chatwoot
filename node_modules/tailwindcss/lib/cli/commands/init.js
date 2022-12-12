"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.run = run;
exports.optionMap = exports.options = exports.description = exports.usage = void 0;

var constants = _interopRequireWildcard(require("../../constants"));

var colors = _interopRequireWildcard(require("../colors"));

var emoji = _interopRequireWildcard(require("../emoji"));

var utils = _interopRequireWildcard(require("../utils"));

function _getRequireWildcardCache() { if (typeof WeakMap !== "function") return null; var cache = new WeakMap(); _getRequireWildcardCache = function () { return cache; }; return cache; }

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } if (obj === null || typeof obj !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

const usage = 'init [file]';
exports.usage = usage;
const description = 'Creates Tailwind config file. Default: ' + colors.file(utils.getSimplePath(constants.defaultConfigFile));
exports.description = description;
const options = [{
  usage: '--full',
  description: 'Generate complete configuration file.'
}, {
  usage: '-p',
  description: 'Generate postcss.config.js file.'
}];
exports.options = options;
const optionMap = {
  full: ['full'],
  postcss: ['p']
};
/**
 * Runs the command.
 *
 * @param {string[]} cliParams
 * @param {object} cliOptions
 * @return {Promise}
 */

exports.optionMap = optionMap;

function run(cliParams, cliOptions) {
  return new Promise(resolve => {
    utils.header();
    const full = cliOptions.full;
    const file = cliParams[0] || constants.defaultConfigFile;
    const simplePath = utils.getSimplePath(file);
    utils.exists(file) && utils.die(colors.file(simplePath), 'already exists.');
    const stubFile = full ? constants.defaultConfigStubFile : constants.simpleConfigStubFile;
    utils.copyFile(stubFile, file);
    utils.log();
    utils.log(emoji.yes, 'Created Tailwind config file:', colors.file(simplePath));

    if (cliOptions.postcss) {
      const path = utils.getSimplePath(constants.defaultPostCssConfigFile);
      utils.exists(constants.defaultPostCssConfigFile) && utils.die(colors.file(path), 'already exists.');
      utils.copyFile(constants.defaultPostCssConfigStubFile, constants.defaultPostCssConfigFile);
      utils.log(emoji.yes, 'Created PostCSS config file:', colors.file(path));
    }

    utils.footer();
    resolve();
  });
}
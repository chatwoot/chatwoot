"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.run = run;
exports.optionMap = exports.options = exports.description = exports.usage = void 0;

var _autoprefixer = _interopRequireDefault(require("autoprefixer"));

var _bytes = _interopRequireDefault(require("bytes"));

var _prettyHrtime = _interopRequireDefault(require("pretty-hrtime"));

var _ = _interopRequireDefault(require("../.."));

var _compile = _interopRequireDefault(require("../compile"));

var colors = _interopRequireWildcard(require("../colors"));

var emoji = _interopRequireWildcard(require("../emoji"));

var utils = _interopRequireWildcard(require("../utils"));

function _getRequireWildcardCache() { if (typeof WeakMap !== "function") return null; var cache = new WeakMap(); _getRequireWildcardCache = function () { return cache; }; return cache; }

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } if (obj === null || typeof obj !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const usage = 'build <file> [options]';
exports.usage = usage;
const description = 'Compiles Tailwind CSS file.';
exports.description = description;
const options = [{
  usage: '-o, --output <file>',
  description: 'Output file.'
}, {
  usage: '-c, --config <file>',
  description: 'Tailwind config file.'
}, {
  usage: '--no-autoprefixer',
  description: "Don't add vendor prefixes using autoprefixer."
}];
exports.options = options;
const optionMap = {
  output: ['output', 'o'],
  config: ['config', 'c'],
  noAutoprefixer: ['no-autoprefixer']
};
/**
 * Prints the error message and stops the process.
 *
 * @param {...string} [msgs]
 */

exports.optionMap = optionMap;

function stop(...msgs) {
  utils.header();
  utils.error(...msgs);
  utils.die();
}
/**
 * Compiles CSS file and writes it to stdout.
 *
 * @param {CompileOptions} compileOptions
 * @return {Promise}
 */


function buildToStdout(compileOptions) {
  return (0, _compile.default)(compileOptions).then(result => process.stdout.write(result.css));
}
/**
 * Compiles CSS file and writes it to a file.
 *
 * @param {CompileOptions} compileOptions
 * @param {int[]} startTime
 * @return {Promise}
 */


function buildToFile(compileOptions, startTime) {
  const inputFileSimplePath = utils.getSimplePath(compileOptions.inputFile);
  const outputFileSimplePath = utils.getSimplePath(compileOptions.outputFile);
  utils.header();
  utils.log();
  utils.log(emoji.go, ...(inputFileSimplePath ? ['Building:', colors.file(inputFileSimplePath)] : ['Building from default CSS...', colors.info('(No input file provided)')]));
  return (0, _compile.default)(compileOptions).then(result => {
    utils.writeFile(compileOptions.outputFile, result.css);
    const prettyTime = (0, _prettyHrtime.default)(process.hrtime(startTime));
    utils.log();
    utils.log(emoji.yes, 'Finished in', colors.info(prettyTime));
    utils.log(emoji.pack, 'Size:', colors.info((0, _bytes.default)(result.css.length)));
    utils.log(emoji.disk, 'Saved to', colors.file(outputFileSimplePath));
    utils.footer();
  });
}
/**
 * Runs the command.
 *
 * @param {string[]} cliParams
 * @param {object} cliOptions
 * @return {Promise}
 */


function run(cliParams, cliOptions) {
  return new Promise((resolve, reject) => {
    const startTime = process.hrtime();
    const inputFile = cliParams[0];
    const configFile = cliOptions.config && cliOptions.config[0];
    const outputFile = cliOptions.output && cliOptions.output[0];
    const autoprefix = !cliOptions.noAutoprefixer;
    const inputFileSimplePath = utils.getSimplePath(inputFile);
    const configFileSimplePath = utils.getSimplePath(configFile);

    if (inputFile) {
      !utils.exists(inputFile) && stop(colors.file(inputFileSimplePath), 'does not exist.');
    }

    configFile && !utils.exists(configFile) && stop(colors.file(configFileSimplePath), 'does not exist.');
    const compileOptions = {
      inputFile,
      outputFile,
      plugins: [(0, _.default)(configFile)].concat(autoprefix ? [_autoprefixer.default] : [])
    };
    const buildPromise = outputFile ? buildToFile(compileOptions, startTime) : buildToStdout(compileOptions);
    buildPromise.then(resolve).catch(reject);
  });
}
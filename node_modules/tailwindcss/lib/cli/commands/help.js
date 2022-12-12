"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.forApp = forApp;
exports.forCommand = forCommand;
exports.invalidCommand = invalidCommand;
exports.run = run;
exports.description = exports.usage = void 0;

var _lodash = require("lodash");

var _ = _interopRequireDefault(require("."));

var constants = _interopRequireWildcard(require("../../constants"));

var colors = _interopRequireWildcard(require("../colors"));

var utils = _interopRequireWildcard(require("../utils"));

function _getRequireWildcardCache() { if (typeof WeakMap !== "function") return null; var cache = new WeakMap(); _getRequireWildcardCache = function () { return cache; }; return cache; }

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } if (obj === null || typeof obj !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const usage = 'help [command]';
exports.usage = usage;
const description = 'More information about the command.';
exports.description = description;
const PADDING_SIZE = 3;
/**
 * Prints general help.
 */

function forApp() {
  const pad = Math.max(...(0, _lodash.map)(_.default, 'usage.length')) + PADDING_SIZE;
  utils.log();
  utils.log('Usage:');
  utils.log('  ', colors.bold(constants.cli + ' <command> [options]'));
  utils.log();
  utils.log('Commands:');
  (0, _lodash.forEach)(_.default, command => {
    utils.log('  ', colors.bold((0, _lodash.padEnd)(command.usage, pad)), command.description);
  });
}
/**
 * Prints help for a command.
 *
 * @param {object} command
 */


function forCommand(command) {
  utils.log();
  utils.log('Usage:');
  utils.log('  ', colors.bold(constants.cli, command.usage));
  utils.log();
  utils.log('Description:');
  utils.log('  ', colors.bold(command.description));

  if (command.options) {
    const pad = Math.max(...(0, _lodash.map)(command.options, 'usage.length')) + PADDING_SIZE;
    utils.log();
    utils.log('Options:');
    (0, _lodash.forEach)(command.options, option => {
      utils.log('  ', colors.bold((0, _lodash.padEnd)(option.usage, pad)), option.description);
    });
  }
}
/**
 * Prints invalid command error and general help. Kills the process.
 *
 * @param {string} commandName
 */


function invalidCommand(commandName) {
  utils.error('Invalid command:', colors.command(commandName));
  forApp();
  utils.die();
}
/**
 * Runs the command.
 *
 * @param {string[]} cliParams
 * @return {Promise}
 */


function run(cliParams) {
  return new Promise(resolve => {
    utils.header();
    const commandName = cliParams[0];
    const command = _.default[commandName];
    !commandName && forApp();
    commandName && command && forCommand(command);
    commandName && !command && invalidCommand(commandName);
    utils.footer();
    resolve();
  });
}
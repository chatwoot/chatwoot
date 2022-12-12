"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = run;

var _commands = _interopRequireDefault(require("./commands"));

var utils = _interopRequireWildcard(require("./utils"));

function _getRequireWildcardCache() { if (typeof WeakMap !== "function") return null; var cache = new WeakMap(); _getRequireWildcardCache = function () { return cache; }; return cache; }

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } if (obj === null || typeof obj !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * CLI application entrypoint.
 *
 * @param {string[]} cliArgs
 * @return {Promise}
 */
function run(cliArgs) {
  return new Promise((resolve, reject) => {
    const params = utils.parseCliParams(cliArgs);
    const command = _commands.default[params[0]];
    const options = command ? utils.parseCliOptions(cliArgs, command.optionMap) : {};
    const commandPromise = command ? command.run(params.slice(1), options) : _commands.default.help.run(params);
    commandPromise.then(resolve).catch(reject);
  });
}
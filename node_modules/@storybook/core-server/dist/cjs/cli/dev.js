"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getDevCli = getDevCli;

require("core-js/modules/es.promise.js");

var _commander = _interopRequireDefault(require("commander"));

var _chalk = _interopRequireDefault(require("chalk"));

var _nodeLogger = require("@storybook/node-logger");

var _utils = require("./utils");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

async function getDevCli(packageJson) {
  process.env.NODE_ENV = process.env.NODE_ENV || 'development';

  _commander.default.version(packageJson.version).option('-p, --port <number>', 'Port to run Storybook', function (str) {
    return parseInt(str, 10);
  }).option('-h, --host <string>', 'Host to run Storybook').option('-s, --static-dir <dir-names>', 'Directory where to load static files from', _utils.parseList).option('-c, --config-dir <dir-name>', 'Directory where to load Storybook configurations from').option('--https', 'Serve Storybook over HTTPS. Note: You must provide your own certificate information.').option('--ssl-ca <ca>', 'Provide an SSL certificate authority. (Optional with --https, required if using a self-signed certificate)', _utils.parseList).option('--ssl-cert <cert>', 'Provide an SSL certificate. (Required with --https)').option('--ssl-key <key>', 'Provide an SSL key. (Required with --https)').option('--smoke-test', 'Exit after successful start').option('--ci', "CI mode (skip interactive prompts, don't open browser)").option('--no-open', 'Do not open Storybook automatically in the browser').option('--loglevel <level>', 'Control level of logging during build').option('--quiet', 'Suppress verbose build output').option('--no-version-updates', 'Suppress update check', true).option('--disable-telemetry', 'Disable sending telemetry', // default value is false, but if the user sets STORYBOOK_DISABLE_TELEMETRY, it can be true
  process.env.STORYBOOK_DISABLE_TELEMETRY && process.env.STORYBOOK_DISABLE_TELEMETRY !== 'false').option('--enable-crash-reports', 'enable sending crash reports to telemetry data').option('--no-release-notes', 'Suppress automatic redirects to the release notes after upgrading', true).option('--no-manager-cache', 'Do not cache the manager UI').option('--no-dll', 'Do not use dll references (no-op)').option('--docs-dll', 'Use Docs dll reference (legacy)').option('--ui-dll', 'Use UI dll reference (legacy)').option('--debug-webpack', 'Display final webpack configurations for debugging purposes').option('--webpack-stats-json [directory]', 'Write Webpack Stats JSON to disk').option('--preview-url <string>', 'Disables the default storybook preview and lets your use your own').option('--force-build-preview', 'Build the preview iframe even if you are using --preview-url').option('--docs', 'Build a documentation-only site using addon-docs').option('--modern', 'Use modern browser modules').parse(process.argv);

  _nodeLogger.logger.setLevel(_commander.default.loglevel); // Workaround the `-h` shorthand conflict.
  // Output the help if `-h` is called without any value.
  // See storybookjs/storybook#5360


  _commander.default.on('option:host', function (value) {
    if (!value) {
      _commander.default.help();
    }
  });

  _nodeLogger.logger.info(_chalk.default.bold(`${packageJson.name} v${packageJson.version}`) + _chalk.default.reset('\n')); // The key is the field created in `program` variable for
  // each command line argument. Value is the env variable.


  (0, _utils.getEnvConfig)(_commander.default, {
    port: 'SBCONFIG_PORT',
    host: 'SBCONFIG_HOSTNAME',
    staticDir: 'SBCONFIG_STATIC_DIR',
    configDir: 'SBCONFIG_CONFIG_DIR',
    ci: 'CI'
  });

  if (typeof _commander.default.port === 'string' && _commander.default.port.length > 0) {
    _commander.default.port = parseInt(_commander.default.port, 10);
  }

  (0, _utils.checkDeprecatedFlags)(_commander.default);
  return _objectSpread({}, _commander.default);
}
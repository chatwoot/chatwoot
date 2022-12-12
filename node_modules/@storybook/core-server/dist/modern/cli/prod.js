function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

import program from 'commander';
import chalk from 'chalk';
import { logger } from '@storybook/node-logger';
import { parseList, getEnvConfig, checkDeprecatedFlags } from './utils';
export function getProdCli(packageJson) {
  process.env.NODE_ENV = process.env.NODE_ENV || 'production';
  program.version(packageJson.version).option('-s, --static-dir <dir-names>', 'Directory where to load static files from', parseList).option('-o, --output-dir <dir-name>', 'Directory where to store built files').option('-c, --config-dir <dir-name>', 'Directory where to load Storybook configurations from').option('--quiet', 'Suppress verbose build output').option('--loglevel <level>', 'Control level of logging during build').option('--no-dll', 'Do not use dll reference (no-op)').option('--docs-dll', 'Use Docs dll reference (legacy)').option('--ui-dll', 'Use UI dll reference (legacy)').option('--debug-webpack', 'Display final webpack configurations for debugging purposes').option('--webpack-stats-json [directory]', 'Write Webpack Stats JSON to disk').option('--preview-url <string>', 'Disables the default storybook preview and lets your use your own').option('--force-build-preview', 'Build the preview iframe even if you are using --preview-url').option('--docs', 'Build a documentation-only site using addon-docs').option('--modern', 'Use modern browser modules').option('--no-manager-cache', 'Do not cache the manager UI').option('--disable-telemetry', 'Disable sending telemetry', // default value is false, but if the user sets STORYBOOK_DISABLE_TELEMETRY, it can be true
  process.env.STORYBOOK_DISABLE_TELEMETRY && process.env.STORYBOOK_DISABLE_TELEMETRY !== 'false').option('--enable-crash-reports', 'enable sending crash reports to telemetry data').parse(process.argv);
  logger.setLevel(program.loglevel);
  logger.info(chalk.bold(`${packageJson.name} v${packageJson.version}\n`)); // The key is the field created in `program` variable for
  // each command line argument. Value is the env variable.

  getEnvConfig(program, {
    staticDir: 'SBCONFIG_STATIC_DIR',
    outputDir: 'SBCONFIG_OUTPUT_DIR',
    configDir: 'SBCONFIG_CONFIG_DIR'
  });
  checkDeprecatedFlags(program);
  return _objectSpread({}, program);
}
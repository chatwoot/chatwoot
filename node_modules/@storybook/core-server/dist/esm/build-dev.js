function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

import "core-js/modules/es.promise.js";
import "core-js/modules/es.symbol.description.js";
import { logger, instance as npmLog } from '@storybook/node-logger';
import prompts from 'prompts';
import { resolvePathInStorybookCache, loadAllPresets, cache } from '@storybook/core-common';
import { telemetry } from '@storybook/telemetry';
import dedent from 'ts-dedent';
import global from 'global';
import path from 'path';
import { storybookDevServer } from './dev-server';
import { getDevCli } from './cli';
import { getReleaseNotesData, getReleaseNotesFailedState } from './utils/release-notes';
import { outputStats } from './utils/output-stats';
import { outputStartupInformation } from './utils/output-startup-information';
import { updateCheck } from './utils/update-check';
import { getServerPort, getServerChannelUrl } from './utils/server-address';
import { getPreviewBuilder } from './utils/get-preview-builder';
import { getManagerBuilder } from './utils/get-manager-builder';
export async function buildDevStandalone(options) {
  var packageJson = options.packageJson,
      versionUpdates = options.versionUpdates,
      releaseNotes = options.releaseNotes;
  var version = packageJson.version,
      _packageJson$name = packageJson.name,
      name = _packageJson$name === void 0 ? '' : _packageJson$name; // updateInfo and releaseNotesData are cached, so this is typically pretty fast

  var _await$Promise$all = await Promise.all([getServerPort(options.port), versionUpdates ? updateCheck(version) : Promise.resolve({
    success: false,
    data: {},
    time: Date.now()
  }), releaseNotes ? getReleaseNotesData(version, cache) : Promise.resolve(getReleaseNotesFailedState(version))]),
      _await$Promise$all2 = _slicedToArray(_await$Promise$all, 3),
      port = _await$Promise$all2[0],
      versionCheck = _await$Promise$all2[1],
      releaseNotesData = _await$Promise$all2[2];

  if (!options.ci && !options.smokeTest && options.port != null && port !== options.port) {
    var _await$prompts = await prompts({
      type: 'confirm',
      initial: true,
      name: 'shouldChangePort',
      message: `Port ${options.port} is not available. Would you like to run Storybook on port ${port} instead?`
    }),
        shouldChangePort = _await$prompts.shouldChangePort;

    if (!shouldChangePort) process.exit(1);
  }
  /* eslint-disable no-param-reassign */


  options.port = port;
  options.versionCheck = versionCheck;
  options.releaseNotesData = releaseNotesData;
  options.configType = 'DEVELOPMENT';
  options.configDir = path.resolve(options.configDir);
  options.outputDir = options.smokeTest ? resolvePathInStorybookCache('public') : path.resolve(options.outputDir || resolvePathInStorybookCache('public'));
  options.serverChannelUrl = getServerChannelUrl(port, options);
  /* eslint-enable no-param-reassign */

  var previewBuilder = await getPreviewBuilder(options.configDir);
  var managerBuilder = await getManagerBuilder(options.configDir);
  var presets = loadAllPresets(_objectSpread({
    corePresets: [require.resolve('./presets/common-preset'), ...managerBuilder.corePresets, ...previewBuilder.corePresets, require.resolve('./presets/babel-cache-preset')],
    overridePresets: previewBuilder.overridePresets
  }, options));
  var features = await presets.apply('features');
  global.FEATURES = features;

  var fullOptions = _objectSpread(_objectSpread({}, options), {}, {
    presets: presets,
    features: features
  });

  var _await$storybookDevSe = await storybookDevServer(fullOptions),
      address = _await$storybookDevSe.address,
      networkAddress = _await$storybookDevSe.networkAddress,
      managerResult = _await$storybookDevSe.managerResult,
      previewResult = _await$storybookDevSe.previewResult;

  var previewTotalTime = previewResult && previewResult.totalTime;
  var managerTotalTime = managerResult && managerResult.totalTime;
  var previewStats = previewResult && previewResult.stats;
  var managerStats = managerResult && managerResult.stats;

  if (options.webpackStatsJson) {
    var target = options.webpackStatsJson === true ? options.outputDir : options.webpackStatsJson;
    await outputStats(target, previewStats, managerStats);
  }

  if (options.smokeTest) {
    // @ts-ignore
    var managerWarnings = managerStats && managerStats.toJson().warnings || [];
    if (managerWarnings.length > 0) logger.warn(`manager: ${JSON.stringify(managerWarnings, null, 2)}`); // I'm a little reticent to import webpack types in this file :shrug:
    // @ts-ignore

    var previewWarnings = previewStats && previewStats.toJson().warnings || [];
    if (previewWarnings.length > 0) logger.warn(`preview: ${JSON.stringify(previewWarnings, null, 2)}`);
    process.exit(managerWarnings.length > 0 || previewWarnings.length > 0 && !options.ignorePreview ? 1 : 0);
    return;
  } // Get package name and capitalize it e.g. @storybook/react -> React


  var packageName = name.split('@storybook/').length > 1 ? name.split('@storybook/')[1] : name;
  var frameworkName = packageName.charAt(0).toUpperCase() + packageName.slice(1);
  outputStartupInformation({
    updateInfo: versionCheck,
    version: version,
    name: frameworkName,
    address: address,
    networkAddress: networkAddress,
    managerTotalTime: managerTotalTime,
    previewTotalTime: previewTotalTime
  });
}
export async function buildDev(loadOptions) {
  var cliOptions = await getDevCli(loadOptions.packageJson);

  var options = _objectSpread(_objectSpread(_objectSpread({}, cliOptions), loadOptions), {}, {
    configDir: loadOptions.configDir || cliOptions.configDir || './.storybook',
    configType: 'DEVELOPMENT',
    ignorePreview: !!cliOptions.previewUrl && !cliOptions.forceBuildPreview,
    docsMode: !!cliOptions.docs,
    cache: cache
  });

  try {
    await buildDevStandalone(options);
  } catch (error) {
    var _error$compilation;

    // this is a weird bugfix, somehow 'node-pre-gyp' is polluting the npmLog header
    npmLog.heading = '';

    if (error instanceof Error) {
      if (error.error) {
        logger.error(error.error);
      } else if (error.stats && error.stats.compilation.errors) {
        error.stats.compilation.errors.forEach(function (e) {
          return logger.plain(e);
        });
      } else {
        logger.error(error);
      }
    } else if ((_error$compilation = error.compilation) !== null && _error$compilation !== void 0 && _error$compilation.errors) {
      error.compilation.errors.forEach(function (e) {
        return logger.plain(e);
      });
    }

    logger.line();
    logger.warn(error.close ? dedent`
          FATAL broken build!, will close the process,
          Fix the error below and restart storybook.
        ` : dedent`
          Broken build, fix the error above.
          You may need to refresh the browser.
        `);
    logger.line();
    var presets = loadAllPresets(_objectSpread({
      corePresets: [require.resolve('./presets/common-preset')],
      overridePresets: []
    }, options));
    var core = await presets.apply('core');

    if (!(core !== null && core !== void 0 && core.disableTelemetry)) {
      var enableCrashReports;

      if (core.enableCrashReports !== undefined) {
        enableCrashReports = core.enableCrashReports;
      } else {
        var valueFromCache = await cache.get('enableCrashreports');

        if (valueFromCache !== undefined) {
          enableCrashReports = valueFromCache;
        } else {
          var valueFromPrompt = await promptCrashReports(options);

          if (valueFromPrompt !== undefined) {
            enableCrashReports = valueFromPrompt;
          }
        }
      }

      await telemetry('error-dev', {
        error: error
      }, {
        immediate: true,
        configDir: options.configDir,
        enableCrashReports: enableCrashReports
      });
    }

    process.exit(1);
  }
}

var promptCrashReports = async function ({
  packageJson: packageJson
}) {
  if (process.env.CI) {
    return undefined;
  }

  var _await$prompts2 = await prompts({
    type: 'confirm',
    name: 'enableCrashReports',
    message: `Would you like to send crash reports to Storybook?`,
    initial: true
  }),
      enableCrashReports = _await$prompts2.enableCrashReports;

  await cache.set('enableCrashreports', enableCrashReports);
  return enableCrashReports;
};
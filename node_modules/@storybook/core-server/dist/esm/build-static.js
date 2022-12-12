import "core-js/modules/es.symbol.description.js";
var _excluded = ["packageJson"];

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

import "core-js/modules/es.promise.js";
import chalk from 'chalk';
import cpy from 'cpy';
import fs from 'fs-extra';
import path from 'path';
import dedent from 'ts-dedent';
import global from 'global';
import { logger } from '@storybook/node-logger';
import { telemetry } from '@storybook/telemetry';
import { normalizeStories, loadAllPresets, cache, logConfig } from '@storybook/core-common';
import { getProdCli } from './cli';
import { outputStats } from './utils/output-stats';
import { copyAllStaticFiles, copyAllStaticFilesRelativeToMain } from './utils/copy-all-static-files';
import { getPreviewBuilder } from './utils/get-preview-builder';
import { getManagerBuilder } from './utils/get-manager-builder';
import { extractStoriesJson } from './utils/stories-json';
import { extractStorybookMetadata } from './utils/metadata';
import { StoryIndexGenerator } from './utils/StoryIndexGenerator';
export async function buildStaticStandalone(options) {
  var _options$staticDir, _core$builder;

  /* eslint-disable no-param-reassign */
  options.configType = 'PRODUCTION';

  if (options.outputDir === '') {
    throw new Error("Won't remove current directory. Check your outputDir!");
  }

  if ((_options$staticDir = options.staticDir) !== null && _options$staticDir !== void 0 && _options$staticDir.includes('/')) {
    throw new Error("Won't copy root directory. Check your staticDirs!");
  }

  options.outputDir = path.isAbsolute(options.outputDir) ? options.outputDir : path.join(process.cwd(), options.outputDir);
  options.configDir = path.resolve(options.configDir);
  /* eslint-enable no-param-reassign */

  var defaultFavIcon = require.resolve('@storybook/core-server/public/favicon.ico');

  logger.info(chalk`=> Cleaning outputDir: {cyan ${options.outputDir}}`);

  if (options.outputDir === '/') {
    throw new Error("Won't remove directory '/'. Check your outputDir!");
  }

  await fs.emptyDir(options.outputDir);
  await cpy(defaultFavIcon, options.outputDir);
  var previewBuilder = await getPreviewBuilder(options.configDir);
  var managerBuilder = await getManagerBuilder(options.configDir);
  var presets = loadAllPresets(_objectSpread({
    corePresets: [require.resolve('./presets/common-preset'), ...managerBuilder.corePresets, ...previewBuilder.corePresets, require.resolve('./presets/babel-cache-preset')],
    overridePresets: previewBuilder.overridePresets
  }, options));
  var staticDirs = await presets.apply('staticDirs');

  if (staticDirs && options.staticDir) {
    throw new Error(dedent`
      Conflict when trying to read staticDirs:
      * Storybook's configuration option: 'staticDirs'
      * Storybook's CLI flag: '--staticDir' or '-s'
      
      Choose one of them, but not both.
    `);
  }

  if (staticDirs) {
    await copyAllStaticFilesRelativeToMain(staticDirs, options.outputDir, options.configDir);
  }

  if (options.staticDir) {
    await copyAllStaticFiles(options.staticDir, options.outputDir);
  }

  var features = await presets.apply('features');
  global.FEATURES = features;
  var extractTasks = [];
  var initializedStoryIndexGenerator = Promise.resolve(undefined);

  if (features !== null && features !== void 0 && features.buildStoriesJson || features !== null && features !== void 0 && features.storyStoreV7) {
    var workingDir = process.cwd();
    var directories = {
      configDir: options.configDir,
      workingDir: workingDir
    };
    var normalizedStories = normalizeStories(await presets.apply('stories'), directories);
    var generator = new StoryIndexGenerator(normalizedStories, _objectSpread(_objectSpread({}, directories), {}, {
      storiesV2Compatibility: !(features !== null && features !== void 0 && features.breakingChangesV7) && !(features !== null && features !== void 0 && features.storyStoreV7),
      storyStoreV7: features === null || features === void 0 ? void 0 : features.storyStoreV7
    }));
    initializedStoryIndexGenerator = generator.initialize().then(function () {
      return generator;
    });
    extractTasks.push(extractStoriesJson(path.join(options.outputDir, 'stories.json'), initializedStoryIndexGenerator));
  }

  var core = await presets.apply('core');

  if (!(core !== null && core !== void 0 && core.disableTelemetry)) {
    initializedStoryIndexGenerator.then(async function (generator) {
      if (!generator) {
        return;
      }

      var storyIndex = await generator.getIndex();
      var payload = storyIndex ? {
        storyIndex: {
          storyCount: Object.keys(storyIndex.stories).length,
          version: storyIndex.v
        }
      } : undefined;
      telemetry('build', payload, {
        configDir: options.configDir
      });
    });
  }

  if (!(core !== null && core !== void 0 && core.disableProjectJson)) {
    extractTasks.push(extractStorybookMetadata(path.join(options.outputDir, 'project.json'), options.configDir));
  }

  var fullOptions = _objectSpread(_objectSpread({}, options), {}, {
    presets: presets,
    features: features
  });

  if (options.debugWebpack) {
    logConfig('Preview webpack config', await previewBuilder.getConfig(fullOptions));
    logConfig('Manager webpack config', await managerBuilder.getConfig(fullOptions));
  }

  var builderName = typeof (core === null || core === void 0 ? void 0 : core.builder) === 'string' ? core.builder : core === null || core === void 0 ? void 0 : (_core$builder = core.builder) === null || _core$builder === void 0 ? void 0 : _core$builder.name;

  var _ref = builderName === 'webpack5' ? // eslint-disable-next-line import/no-extraneous-dependencies
  await import('@storybook/manager-webpack5/prebuilt-manager') : await import('@storybook/manager-webpack4/prebuilt-manager'),
      getPrebuiltDir = _ref.getPrebuiltDir;

  var prebuiltDir = await getPrebuiltDir(fullOptions);
  var startTime = process.hrtime(); // When using the prebuilt manager, we straight up copy it into the outputDir instead of building it

  var manager = prebuiltDir ? cpy('**', options.outputDir, {
    cwd: prebuiltDir,
    parents: true
  }).then(function () {}) : managerBuilder.build({
    startTime: startTime,
    options: fullOptions
  });

  if (options.ignorePreview) {
    logger.info(`=> Not building preview`);
  }

  var preview = options.ignorePreview ? Promise.resolve() : previewBuilder.build({
    startTime: startTime,
    options: fullOptions
  });

  var _await$Promise$all = await Promise.all([manager.catch(async function (err) {
    await previewBuilder.bail();
    throw err;
  }), preview.catch(async function (err) {
    await managerBuilder.bail();
    throw err;
  }), ...extractTasks]),
      _await$Promise$all2 = _slicedToArray(_await$Promise$all, 2),
      managerStats = _await$Promise$all2[0],
      previewStats = _await$Promise$all2[1];

  if (options.webpackStatsJson) {
    var target = options.webpackStatsJson === true ? options.outputDir : options.webpackStatsJson;
    await outputStats(target, previewStats, managerStats);
  }

  logger.info(`=> Output directory: ${options.outputDir}`);
}
export async function buildStatic(_ref2) {
  var packageJson = _ref2.packageJson,
      loadOptions = _objectWithoutProperties(_ref2, _excluded);

  var cliOptions = getProdCli(packageJson);

  var options = _objectSpread(_objectSpread(_objectSpread({}, cliOptions), loadOptions), {}, {
    packageJson: packageJson,
    configDir: loadOptions.configDir || cliOptions.configDir || './.storybook',
    outputDir: loadOptions.outputDir || cliOptions.outputDir || './storybook-static',
    ignorePreview: (!!loadOptions.ignorePreview || !!cliOptions.previewUrl) && !cliOptions.forceBuildPreview,
    docsMode: !!cliOptions.docs,
    configType: 'PRODUCTION',
    cache: cache
  });

  try {
    await buildStaticStandalone(options);
  } catch (error) {
    logger.error(error);
    var presets = loadAllPresets(_objectSpread({
      corePresets: [require.resolve('./presets/common-preset')],
      overridePresets: []
    }, options));
    var core = await presets.apply('core');

    if (!(core !== null && core !== void 0 && core.disableTelemetry)) {
      await telemetry('error-build', {
        error: error
      }, {
        immediate: true,
        configDir: options.configDir,
        enableCrashReports: options.enableCrashReports
      });
    }

    process.exit(1);
  }
}
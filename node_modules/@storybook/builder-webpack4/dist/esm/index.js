function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

import "core-js/modules/es.promise.js";
import webpackReal, { ProgressPlugin } from 'webpack'; // @ts-ignore

import webpackDevMiddleware from 'webpack-dev-middleware';
import webpackHotMiddleware from 'webpack-hot-middleware';
import { logger } from '@storybook/node-logger';
import { useProgressReporting, checkWebpackVersion } from '@storybook/core-common';
var compilation;
var reject;
export var executor = {
  get: async function (options) {
    var _await$options$preset;

    var version = (await options.presets.apply('webpackVersion')) || '4';
    var webpackInstance = ((_await$options$preset = await options.presets.apply('webpackInstance')) === null || _await$options$preset === void 0 ? void 0 : _await$options$preset.default) || webpackReal;
    checkWebpackVersion({
      version: version
    }, '4', 'builder-webpack4');
    return webpackInstance;
  }
};
export var getConfig = async function (options) {
  var presets = options.presets;
  var typescriptOptions = await presets.apply('typescript', {}, options);
  var babelOptions = await presets.apply('babel', {}, _objectSpread(_objectSpread({}, options), {}, {
    typescriptOptions: typescriptOptions
  }));
  var frameworkOptions = await presets.apply(`${options.framework}Options`, {}, options);
  return presets.apply('webpack', {}, _objectSpread(_objectSpread({}, options), {}, {
    babelOptions: babelOptions,
    typescriptOptions: typescriptOptions,
    [`${options.framework}Options`]: frameworkOptions
  }));
};
export var makeStatsFromError = function (err) {
  return {
    hasErrors: function () {
      return true;
    },
    hasWarnings: function () {
      return false;
    },
    toJson: function () {
      return {
        warnings: [],
        errors: [err]
      };
    }
  };
};
var asyncIterator;
export var bail = async function () {
  if (asyncIterator) {
    try {
      // we tell the builder (that started) to stop ASAP and wait
      await asyncIterator.throw(new Error());
    } catch (e) {//
    }
  }

  if (reject) {
    reject();
  } // we wait for the compiler to finish it's work, so it's command-line output doesn't interfere


  return new Promise(function (res, rej) {
    if (process && compilation) {
      try {
        compilation.close(function () {
          return res();
        });
        logger.warn('Force closed preview build');
      } catch (err) {
        logger.warn('Unable to close preview build!');
        res();
      }
    } else {
      res();
    }
  });
};
/**
 * This function is a generator so that we can abort it mid process
 * in case of failure coming from other processes e.g. manager builder
 *
 * I am sorry for making you read about generators today :')
 */

var starter = async function* starterGeneratorFn({
  startTime: startTime,
  options: options,
  router: router
}) {
  var _config$output;

  var webpackInstance = await executor.get(options);
  yield;
  var config = await getConfig(options);
  yield;
  var compiler = webpackInstance(config);

  if (!compiler) {
    var _err = `${config.name}: missing webpack compiler at runtime!`;
    logger.error(_err);
    return {
      bail: bail,
      totalTime: process.hrtime(startTime),
      stats: makeStatsFromError(_err)
    };
  }

  var _await$useProgressRep = await useProgressReporting(router, startTime, options),
      handler = _await$useProgressRep.handler,
      modulesCount = _await$useProgressRep.modulesCount;

  yield;
  new ProgressPlugin({
    handler: handler,
    modulesCount: modulesCount
  }).apply(compiler);
  var middlewareOptions = {
    publicPath: (_config$output = config.output) === null || _config$output === void 0 ? void 0 : _config$output.publicPath,
    writeToDisk: true,
    logLevel: 'error',
    watchOptions: config.watchOptions || {}
  };
  compilation = webpackDevMiddleware(compiler, middlewareOptions);
  router.use(compilation);
  router.use(webpackHotMiddleware(compiler));
  var waitUntilValid = compilation.waitUntilValid.bind(compilation);
  var stats = await new Promise(function (ready, stop) {
    waitUntilValid(ready);
    reject = stop;
  });
  yield;

  if (!stats) {
    throw new Error('no stats after building preview');
  }

  if (stats.hasErrors()) {
    throw stats;
  }

  return {
    bail: bail,
    stats: stats,
    totalTime: process.hrtime(startTime)
  };
};
/**
 * This function is a generator so that we can abort it mid process
 * in case of failure coming from other processes e.g. manager builder
 *
 * I am sorry for making you read about generators today :')
 */


var builder = async function* builderGeneratorFn({
  startTime: startTime,
  options: options
}) {
  var webpackInstance = await executor.get(options);
  yield;
  logger.info('=> Compiling preview..');
  var config = await getConfig(options);
  yield;
  var compiler = webpackInstance(config);

  if (!compiler) {
    var _err2 = `${config.name}: missing webpack compiler at runtime!`;
    logger.error(_err2);
    return Promise.resolve(makeStatsFromError(_err2));
  }

  yield;
  return new Promise(function (succeed, fail) {
    compiler.run(function (error, stats) {
      if (error || !stats || stats.hasErrors()) {
        logger.error('=> Failed to build the preview');
        process.exitCode = 1;

        if (error) {
          logger.error(error.message);
          return fail(error);
        }

        if (stats && (stats.hasErrors() || stats.hasWarnings())) {
          var _stats$toJson = stats.toJson(typeof config.stats === 'string' ? config.stats : _objectSpread({
            warnings: true,
            errors: true
          }, config.stats)),
              _stats$toJson$warning = _stats$toJson.warnings,
              warnings = _stats$toJson$warning === void 0 ? [] : _stats$toJson$warning,
              _stats$toJson$errors = _stats$toJson.errors,
              errors = _stats$toJson$errors === void 0 ? [] : _stats$toJson$errors;

          errors.forEach(function (e) {
            return logger.error(e);
          });
          warnings.forEach(function (e) {
            return logger.error(e);
          });
          return options.debugWebpack ? fail(stats) : fail(new Error('=> Webpack failed, learn more with --debug-webpack'));
        }
      }

      logger.trace({
        message: '=> Preview built',
        time: process.hrtime(startTime)
      });

      if (stats) {
        stats.toJson(config.stats).warnings.forEach(function (e) {
          return logger.warn(e);
        });
      }

      return succeed(stats);
    });
  });
};

export var start = async function (options) {
  asyncIterator = starter(options);
  var result;

  do {
    // eslint-disable-next-line no-await-in-loop
    result = await asyncIterator.next();
  } while (!result.done);

  return result.value;
};
export var build = async function (options) {
  asyncIterator = builder(options);
  var result;

  do {
    // eslint-disable-next-line no-await-in-loop
    result = await asyncIterator.next();
  } while (!result.done);

  return result.value;
};
export var corePresets = [require.resolve('./presets/preview-preset.js')];
export var overridePresets = [require.resolve('./presets/custom-webpack-preset.js')];
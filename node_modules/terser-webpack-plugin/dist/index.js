"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _path = _interopRequireDefault(require("path"));

var _os = _interopRequireDefault(require("os"));

var _sourceMap = require("source-map");

var _webpack = _interopRequireWildcard(require("webpack"));

var _RequestShortener = _interopRequireDefault(require("webpack/lib/RequestShortener"));

var _schemaUtils = require("schema-utils");

var _serializeJavascript = _interopRequireDefault(require("serialize-javascript"));

var _package = _interopRequireDefault(require("terser/package.json"));

var _pLimit = _interopRequireDefault(require("p-limit"));

var _jestWorker = _interopRequireDefault(require("jest-worker"));

var _options = _interopRequireDefault(require("./options.json"));

var _minify = require("./minify");

function _getRequireWildcardCache() { if (typeof WeakMap !== "function") return null; var cache = new WeakMap(); _getRequireWildcardCache = function () { return cache; }; return cache; }

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } if (obj === null || typeof obj !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// webpack 5 exposes the sources property to ensure the right version of webpack-sources is used
const {
  SourceMapSource,
  RawSource,
  ConcatSource
} = // eslint-disable-next-line global-require
_webpack.default.sources || require('webpack-sources');

class TerserPlugin {
  constructor(options = {}) {
    (0, _schemaUtils.validate)(_options.default, options, {
      name: 'Terser Plugin',
      baseDataPath: 'options'
    });
    const {
      minify,
      terserOptions = {},
      test = /\.[cm]?js(\?.*)?$/i,
      extractComments = true,
      sourceMap,
      cache = true,
      cacheKeys = defaultCacheKeys => defaultCacheKeys,
      parallel = true,
      include,
      exclude
    } = options;
    this.options = {
      test,
      extractComments,
      sourceMap,
      cache,
      cacheKeys,
      parallel,
      include,
      exclude,
      minify,
      terserOptions
    };
  }

  static isSourceMap(input) {
    // All required options for `new SourceMapConsumer(...options)`
    // https://github.com/mozilla/source-map#new-sourcemapconsumerrawsourcemap
    return Boolean(input && input.version && input.sources && Array.isArray(input.sources) && typeof input.mappings === 'string');
  }

  static buildError(error, file, sourceMap, requestShortener) {
    if (error.line) {
      const original = sourceMap && sourceMap.originalPositionFor({
        line: error.line,
        column: error.col
      });

      if (original && original.source && requestShortener) {
        return new Error(`${file} from Terser\n${error.message} [${requestShortener.shorten(original.source)}:${original.line},${original.column}][${file}:${error.line},${error.col}]${error.stack ? `\n${error.stack.split('\n').slice(1).join('\n')}` : ''}`);
      }

      return new Error(`${file} from Terser\n${error.message} [${file}:${error.line},${error.col}]${error.stack ? `\n${error.stack.split('\n').slice(1).join('\n')}` : ''}`);
    }

    if (error.stack) {
      return new Error(`${file} from Terser\n${error.stack}`);
    }

    return new Error(`${file} from Terser\n${error.message}`);
  }

  static isWebpack4() {
    return _webpack.version[0] === '4';
  }

  static getAvailableNumberOfCores(parallel) {
    // In some cases cpus() returns undefined
    // https://github.com/nodejs/node/issues/19022
    const cpus = _os.default.cpus() || {
      length: 1
    };
    return parallel === true ? cpus.length - 1 : Math.min(Number(parallel) || 0, cpus.length - 1);
  } // eslint-disable-next-line consistent-return


  static getAsset(compilation, name) {
    // New API
    if (compilation.getAsset) {
      return compilation.getAsset(name);
    }
    /* istanbul ignore next */


    if (compilation.assets[name]) {
      return {
        name,
        source: compilation.assets[name],
        info: {}
      };
    }
  }

  static emitAsset(compilation, name, source, assetInfo) {
    // New API
    if (compilation.emitAsset) {
      compilation.emitAsset(name, source, assetInfo);
    } // eslint-disable-next-line no-param-reassign


    compilation.assets[name] = source;
  }

  static updateAsset(compilation, name, newSource, assetInfo) {
    // New API
    if (compilation.updateAsset) {
      compilation.updateAsset(name, newSource, assetInfo);
    } // eslint-disable-next-line no-param-reassign


    compilation.assets[name] = newSource;
  }

  async optimize(compiler, compilation, assets, CacheEngine, weakCache) {
    let assetNames;

    if (TerserPlugin.isWebpack4()) {
      assetNames = [].concat(Array.from(compilation.additionalChunkAssets || [])).concat( // In webpack@4 it is `chunks`
      Array.from(assets).reduce((acc, chunk) => acc.concat(Array.from(chunk.files || [])), [])).concat(Object.keys(compilation.assets)).filter((assetName, index, existingAssets) => existingAssets.indexOf(assetName) === index).filter(assetName => _webpack.ModuleFilenameHelpers.matchObject.bind( // eslint-disable-next-line no-undefined
      undefined, this.options)(assetName));
    } else {
      assetNames = Object.keys(assets).filter(assetName => _webpack.ModuleFilenameHelpers.matchObject.bind( // eslint-disable-next-line no-undefined
      undefined, this.options)(assetName));
    }

    if (assetNames.length === 0) {
      return;
    }

    const availableNumberOfCores = TerserPlugin.getAvailableNumberOfCores(this.options.parallel);
    let concurrency = Infinity;
    let worker;

    if (availableNumberOfCores > 0) {
      // Do not create unnecessary workers when the number of files is less than the available cores, it saves memory
      const numWorkers = Math.min(assetNames.length, availableNumberOfCores);
      concurrency = numWorkers;
      worker = new _jestWorker.default(require.resolve('./minify'), {
        numWorkers
      }); // https://github.com/facebook/jest/issues/8872#issuecomment-524822081

      const workerStdout = worker.getStdout();

      if (workerStdout) {
        workerStdout.on('data', chunk => {
          return process.stdout.write(chunk);
        });
      }

      const workerStderr = worker.getStderr();

      if (workerStderr) {
        workerStderr.on('data', chunk => {
          return process.stderr.write(chunk);
        });
      }
    }

    const limit = (0, _pLimit.default)(concurrency);
    const cache = new CacheEngine(compilation, {
      cache: this.options.cache
    }, weakCache);
    const allExtractedComments = new Map();
    const scheduledTasks = [];

    for (const name of assetNames) {
      scheduledTasks.push(limit(async () => {
        const {
          info,
          source: inputSource
        } = TerserPlugin.getAsset(compilation, name); // Skip double minimize assets from child compilation

        if (info.minimized) {
          return;
        }

        let input;
        let inputSourceMap; // TODO refactor after drop webpack@4, webpack@5 always has `sourceAndMap` on sources

        if (this.options.sourceMap && inputSource.sourceAndMap) {
          const {
            source,
            map
          } = inputSource.sourceAndMap();
          input = source;

          if (map) {
            if (TerserPlugin.isSourceMap(map)) {
              inputSourceMap = map;
            } else {
              inputSourceMap = map;
              compilation.warnings.push(new Error(`${name} contains invalid source map`));
            }
          }
        } else {
          input = inputSource.source();
          inputSourceMap = null;
        }

        if (Buffer.isBuffer(input)) {
          input = input.toString();
        }

        const cacheData = {
          name,
          inputSource
        };

        if (TerserPlugin.isWebpack4()) {
          if (this.options.cache) {
            const {
              outputOptions: {
                hashSalt,
                hashDigest,
                hashDigestLength,
                hashFunction
              }
            } = compilation;

            const hash = _webpack.util.createHash(hashFunction);

            if (hashSalt) {
              hash.update(hashSalt);
            }

            hash.update(input);
            const digest = hash.digest(hashDigest);
            cacheData.input = input;
            cacheData.inputSourceMap = inputSourceMap;
            cacheData.cacheKeys = this.options.cacheKeys({
              terser: _package.default.version,
              // eslint-disable-next-line global-require
              'terser-webpack-plugin': require('../package.json').version,
              'terser-webpack-plugin-options': this.options,
              name,
              contentHash: digest.substr(0, hashDigestLength)
            }, name);
          }
        }

        let output = await cache.get(cacheData, {
          RawSource,
          ConcatSource,
          SourceMapSource
        });

        if (!output) {
          const minimizerOptions = {
            name,
            input,
            inputSourceMap,
            minify: this.options.minify,
            minimizerOptions: this.options.terserOptions,
            extractComments: this.options.extractComments
          };

          if (/\.mjs(\?.*)?$/i.test(name)) {
            this.options.terserOptions.module = true;
          }

          try {
            output = await (worker ? worker.transform((0, _serializeJavascript.default)(minimizerOptions)) : (0, _minify.minify)(minimizerOptions));
          } catch (error) {
            compilation.errors.push(TerserPlugin.buildError(error, name, inputSourceMap && TerserPlugin.isSourceMap(inputSourceMap) ? new _sourceMap.SourceMapConsumer(inputSourceMap) : null, new _RequestShortener.default(compiler.context)));
            return;
          }

          let shebang;

          if (this.options.extractComments.banner !== false && output.extractedComments && output.extractedComments.length > 0 && output.code.startsWith('#!')) {
            const firstNewlinePosition = output.code.indexOf('\n');
            shebang = output.code.substring(0, firstNewlinePosition);
            output.code = output.code.substring(firstNewlinePosition + 1);
          }

          if (output.map) {
            output.source = new SourceMapSource(output.code, name, output.map, input, inputSourceMap, true);
          } else {
            output.source = new RawSource(output.code);
          }

          let commentsFilename;

          if (output.extractedComments && output.extractedComments.length > 0) {
            commentsFilename = this.options.extractComments.filename || '[file].LICENSE.txt[query]';
            let query = '';
            let filename = name;
            const querySplit = filename.indexOf('?');

            if (querySplit >= 0) {
              query = filename.substr(querySplit);
              filename = filename.substr(0, querySplit);
            }

            const lastSlashIndex = filename.lastIndexOf('/');
            const basename = lastSlashIndex === -1 ? filename : filename.substr(lastSlashIndex + 1);
            const data = {
              filename,
              basename,
              query
            };
            commentsFilename = compilation.getPath(commentsFilename, data);
            output.commentsFilename = commentsFilename;
            let banner; // Add a banner to the original file

            if (this.options.extractComments.banner !== false) {
              banner = this.options.extractComments.banner || `For license information please see ${_path.default.relative(_path.default.dirname(name), commentsFilename).replace(/\\/g, '/')}`;

              if (typeof banner === 'function') {
                banner = banner(commentsFilename);
              }

              if (banner) {
                output.source = new ConcatSource(shebang ? `${shebang}\n` : '', `/*! ${banner} */\n`, output.source);
                output.banner = banner;
                output.shebang = shebang;
              }
            }

            const extractedCommentsString = output.extractedComments.sort().join('\n\n');
            output.extractedCommentsSource = new RawSource(`${extractedCommentsString}\n`);
          }

          await cache.store({ ...output,
            ...cacheData
          });
        } // TODO `...` required only for webpack@4


        const newInfo = { ...info,
          minimized: true
        };
        const {
          source,
          extractedCommentsSource
        } = output; // Write extracted comments to commentsFilename

        if (extractedCommentsSource) {
          const {
            commentsFilename
          } = output; // TODO `...` required only for webpack@4

          newInfo.related = {
            license: commentsFilename,
            ...info.related
          };
          allExtractedComments.set(name, {
            extractedCommentsSource,
            commentsFilename
          });
        }

        TerserPlugin.updateAsset(compilation, name, source, newInfo);
      }));
    }

    await Promise.all(scheduledTasks);

    if (worker) {
      await worker.end();
    }

    await Array.from(allExtractedComments).sort().reduce(async (previousPromise, [from, value]) => {
      const previous = await previousPromise;
      const {
        commentsFilename,
        extractedCommentsSource
      } = value;

      if (previous && previous.commentsFilename === commentsFilename) {
        const {
          from: previousFrom,
          source: prevSource
        } = previous;
        const mergedName = `${previousFrom}|${from}`;
        const cacheData = {
          target: 'comments'
        };

        if (TerserPlugin.isWebpack4()) {
          const {
            outputOptions: {
              hashSalt,
              hashDigest,
              hashDigestLength,
              hashFunction
            }
          } = compilation;

          const previousHash = _webpack.util.createHash(hashFunction);

          const hash = _webpack.util.createHash(hashFunction);

          if (hashSalt) {
            previousHash.update(hashSalt);
            hash.update(hashSalt);
          }

          previousHash.update(prevSource.source());
          hash.update(extractedCommentsSource.source());
          const previousDigest = previousHash.digest(hashDigest);
          const digest = hash.digest(hashDigest);
          cacheData.cacheKeys = {
            mergedName,
            previousContentHash: previousDigest.substr(0, hashDigestLength),
            contentHash: digest.substr(0, hashDigestLength)
          };
          cacheData.inputSource = extractedCommentsSource;
        } else {
          const mergedInputSource = [prevSource, extractedCommentsSource];
          cacheData.name = `${commentsFilename}|${mergedName}`;
          cacheData.inputSource = mergedInputSource;
        }

        let output = await cache.get(cacheData, {
          ConcatSource
        });

        if (!output) {
          output = new ConcatSource(Array.from(new Set([...prevSource.source().split('\n\n'), ...extractedCommentsSource.source().split('\n\n')])).join('\n\n'));
          await cache.store({ ...cacheData,
            output
          });
        }

        TerserPlugin.updateAsset(compilation, commentsFilename, output);
        return {
          commentsFilename,
          from: mergedName,
          source: output
        };
      }

      const existingAsset = TerserPlugin.getAsset(compilation, commentsFilename);

      if (existingAsset) {
        return {
          commentsFilename,
          from: commentsFilename,
          source: existingAsset.source
        };
      }

      TerserPlugin.emitAsset(compilation, commentsFilename, extractedCommentsSource);
      return {
        commentsFilename,
        from,
        source: extractedCommentsSource
      };
    }, Promise.resolve());
  }

  static getEcmaVersion(environment) {
    // ES 6th
    if (environment.arrowFunction || environment.const || environment.destructuring || environment.forOf || environment.module) {
      return 2015;
    } // ES 11th


    if (environment.bigIntLiteral || environment.dynamicImport) {
      return 2020;
    }

    return 5;
  }

  apply(compiler) {
    const {
      devtool,
      output,
      plugins
    } = compiler.options;
    this.options.sourceMap = typeof this.options.sourceMap === 'undefined' ? devtool && !devtool.includes('eval') && !devtool.includes('cheap') && (devtool.includes('source-map') || // Todo remove when `webpack@4` support will be dropped
    devtool.includes('sourcemap')) || plugins && plugins.some(plugin => plugin instanceof _webpack.SourceMapDevToolPlugin && plugin.options && plugin.options.columns) : Boolean(this.options.sourceMap);

    if (typeof this.options.terserOptions.module === 'undefined' && typeof output.module !== 'undefined') {
      this.options.terserOptions.module = output.module;
    }

    if (typeof this.options.terserOptions.ecma === 'undefined') {
      this.options.terserOptions.ecma = TerserPlugin.getEcmaVersion(output.environment || {});
    }

    const pluginName = this.constructor.name;
    const weakCache = TerserPlugin.isWebpack4() && (this.options.cache === true || typeof this.options.cache === 'string') ? new WeakMap() : // eslint-disable-next-line no-undefined
    undefined;
    compiler.hooks.compilation.tap(pluginName, compilation => {
      if (this.options.sourceMap) {
        compilation.hooks.buildModule.tap(pluginName, moduleArg => {
          // to get detailed location info about errors
          // eslint-disable-next-line no-param-reassign
          moduleArg.useSourceMap = true;
        });
      }

      if (TerserPlugin.isWebpack4()) {
        // eslint-disable-next-line global-require
        const CacheEngine = require('./Webpack4Cache').default;

        const {
          mainTemplate,
          chunkTemplate
        } = compilation;
        const data = (0, _serializeJavascript.default)({
          terser: _package.default.version,
          terserOptions: this.options.terserOptions
        }); // Regenerate `contenthash` for minified assets

        for (const template of [mainTemplate, chunkTemplate]) {
          template.hooks.hashForChunk.tap(pluginName, hash => {
            hash.update('TerserPlugin');
            hash.update(data);
          });
        }

        compilation.hooks.optimizeChunkAssets.tapPromise(pluginName, assets => this.optimize(compiler, compilation, assets, CacheEngine, weakCache));
      } else {
        // eslint-disable-next-line global-require
        const CacheEngine = require('./Webpack5Cache').default; // eslint-disable-next-line global-require


        const Compilation = require('webpack/lib/Compilation');

        const hooks = _webpack.javascript.JavascriptModulesPlugin.getCompilationHooks(compilation);

        const data = (0, _serializeJavascript.default)({
          terser: _package.default.version,
          terserOptions: this.options.terserOptions
        });
        hooks.chunkHash.tap(pluginName, (chunk, hash) => {
          hash.update('TerserPlugin');
          hash.update(data);
        });
        compilation.hooks.processAssets.tapPromise({
          name: pluginName,
          stage: Compilation.PROCESS_ASSETS_STAGE_OPTIMIZE_SIZE
        }, assets => this.optimize(compiler, compilation, assets, CacheEngine));
        compilation.hooks.statsPrinter.tap(pluginName, stats => {
          stats.hooks.print.for('asset.info.minimized').tap('terser-webpack-plugin', (minimized, {
            green,
            formatFlag
          }) => // eslint-disable-next-line no-undefined
          minimized ? green(formatFlag('minimized')) : undefined);
        });
      }
    });
  }

}

var _default = TerserPlugin;
exports.default = _default;
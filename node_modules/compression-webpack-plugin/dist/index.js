"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _crypto = _interopRequireDefault(require("crypto"));

var _url = _interopRequireDefault(require("url"));

var _path = _interopRequireDefault(require("path"));

var _RawSource = _interopRequireDefault(require("webpack-sources/lib/RawSource"));

var _webpack = require("webpack");

var _schemaUtils = _interopRequireDefault(require("schema-utils"));

var _package = _interopRequireDefault(require("../package.json"));

var _options = _interopRequireDefault(require("./options.json"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/*
MIT License http://www.opensource.org/licenses/mit-license.php
Author Tobias Koppers @sokra
*/
class CompressionPlugin {
  constructor(options = {}) {
    (0, _schemaUtils.default)(_options.default, options, {
      name: 'Compression Plugin',
      baseDataPath: 'options'
    });
    const {
      test,
      include,
      exclude,
      cache = true,
      algorithm = 'gzip',
      compressionOptions = {},
      filename = '[path].gz[query]',
      threshold = 0,
      minRatio = 0.8,
      deleteOriginalAssets = false
    } = options;
    this.options = {
      test,
      include,
      exclude,
      cache,
      algorithm,
      compressionOptions,
      filename,
      threshold,
      minRatio,
      deleteOriginalAssets
    };
    this.algorithm = this.options.algorithm;
    this.compressionOptions = this.options.compressionOptions;

    if (typeof this.algorithm === 'string') {
      // eslint-disable-next-line global-require
      const zlib = require('zlib');

      this.algorithm = zlib[this.algorithm];

      if (!this.algorithm) {
        throw new Error(`Algorithm "${this.options.algorithm}" is not found in zlib`);
      }

      const defaultCompressionOptions = {
        level: 9
      }; // TODO change this behaviour in the next major release

      this.compressionOptions = { ...defaultCompressionOptions,
        ...this.compressionOptions
      };
    }
  }

  *taskGenerator(compiler, compilation, assetsCache, assetName) {
    const assetSource = compilation.assets[assetName];
    let input = assetSource.source();

    if (!Buffer.isBuffer(input)) {
      input = Buffer.from(input);
    } // Do not emit cached assets in watch mode


    if (assetsCache.get(assetSource)) {
      yield false;
    }

    const originalSize = input.length;

    if (originalSize < this.options.threshold) {
      yield false;
    }

    const callback = taskResult => {
      if (taskResult.error) {
        compilation.errors.push(taskResult.error);
        return;
      }

      const {
        output
      } = taskResult;

      if (output.length / originalSize > this.options.minRatio) {
        return;
      }

      const parse = _url.default.parse(assetName);

      const {
        pathname
      } = parse;

      const {
        dir,
        name,
        ext
      } = _path.default.parse(pathname);

      const info = {
        file: assetName,
        path: pathname,
        dir: dir ? `${dir}/` : '',
        name,
        ext,
        query: parse.query ? `?${parse.query}` : ''
      };
      const newAssetName = typeof this.options.filename === 'function' ? this.options.filename(info) : this.options.filename.replace(/\[(file|path|query|dir|name|ext)]/g, (p0, p1) => info[p1]);
      const compressedSource = new _RawSource.default(output); // eslint-disable-next-line no-param-reassign

      compilation.assets[newAssetName] = compressedSource;
      assetsCache.set(assetSource, compressedSource);

      if (this.options.deleteOriginalAssets) {
        // eslint-disable-next-line no-param-reassign
        delete compilation.assets[assetName];
      }
    };

    const task = {
      input,
      filename: assetName,
      // Invalidate cache after upgrade `zlib` module (built-in in `nodejs`)
      cacheKeys: {
        node: process.version
      },
      callback
    };

    if (CompressionPlugin.isWebpack4()) {
      task.cacheKeys = {
        filename: assetName,
        'compression-webpack-plugin': _package.default.version,
        'compression-webpack-plugin-options': this.options,
        contentHash: _crypto.default.createHash('md4').update(input).digest('hex'),
        ...task.cacheKeys
      };
    } else {
      task.assetSource = assetSource;
    }

    yield task;
  }

  compress(input) {
    return new Promise((resolve, reject) => {
      const {
        algorithm,
        compressionOptions
      } = this;
      algorithm(input, compressionOptions, (error, result) => {
        if (error) {
          return reject(error);
        }

        return resolve(result);
      });
    });
  }

  async runTasks(assetNames, getTaskForAsset, cache) {
    const scheduledTasks = [];

    for (const assetName of assetNames) {
      const enqueue = async task => {
        let taskResult;

        try {
          const output = await this.compress(task.input);
          taskResult = {
            output
          };
        } catch (error) {
          taskResult = {
            error
          };
        }

        if (cache.isEnabled() && !taskResult.error) {
          await cache.store(task, taskResult);
        }

        task.callback(taskResult);
        return taskResult;
      };

      scheduledTasks.push((async () => {
        const task = getTaskForAsset(assetName).next().value;

        if (!task) {
          return Promise.resolve();
        }

        if (cache.isEnabled()) {
          let taskResult;

          try {
            taskResult = await cache.get(task);
          } catch (ignoreError) {
            return enqueue(task);
          }

          task.callback(taskResult);
          return Promise.resolve();
        }

        return enqueue(task);
      })());
    }

    return Promise.all(scheduledTasks);
  }

  static isWebpack4() {
    return _webpack.version[0] === '4';
  }

  apply(compiler) {
    const matchObject = _webpack.ModuleFilenameHelpers.matchObject.bind( // eslint-disable-next-line no-undefined
    undefined, this.options);

    const assetsCache = new WeakMap();
    compiler.hooks.emit.tapPromise({
      name: 'CompressionPlugin'
    }, async compilation => {
      const {
        assets
      } = compilation;
      const assetNames = Object.keys(assets).filter(assetName => matchObject(assetName));

      if (assetNames.length === 0) {
        return Promise.resolve();
      }

      const getTaskForAsset = this.taskGenerator.bind(this, compiler, compilation, assetsCache);
      const CacheEngine = CompressionPlugin.isWebpack4() ? // eslint-disable-next-line global-require
      require('./Webpack4Cache').default : // eslint-disable-next-line global-require
      require('./Webpack5Cache').default;
      const cache = new CacheEngine(compilation, {
        cache: this.options.cache
      });
      await this.runTasks(assetNames, getTaskForAsset, cache);
      return Promise.resolve();
    });
  }

}

var _default = CompressionPlugin;
exports.default = _default;
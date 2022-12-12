'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.createTranspilingRequire = createTranspilingRequire;
exports.default = void 0;

function _crypto() {
  const data = require('crypto');

  _crypto = function () {
    return data;
  };

  return data;
}

function path() {
  const data = _interopRequireWildcard(require('path'));

  path = function () {
    return data;
  };

  return data;
}

function _core() {
  const data = require('@babel/core');

  _core = function () {
    return data;
  };

  return data;
}

function _babelPluginIstanbul() {
  const data = _interopRequireDefault(require('babel-plugin-istanbul'));

  _babelPluginIstanbul = function () {
    return data;
  };

  return data;
}

function _convertSourceMap() {
  const data = require('convert-source-map');

  _convertSourceMap = function () {
    return data;
  };

  return data;
}

function _fastJsonStableStringify() {
  const data = _interopRequireDefault(require('fast-json-stable-stringify'));

  _fastJsonStableStringify = function () {
    return data;
  };

  return data;
}

function fs() {
  const data = _interopRequireWildcard(require('graceful-fs'));

  fs = function () {
    return data;
  };

  return data;
}

function _pirates() {
  const data = require('pirates');

  _pirates = function () {
    return data;
  };

  return data;
}

function _slash() {
  const data = _interopRequireDefault(require('slash'));

  _slash = function () {
    return data;
  };

  return data;
}

function _writeFileAtomic() {
  const data = require('write-file-atomic');

  _writeFileAtomic = function () {
    return data;
  };

  return data;
}

function _jestHasteMap() {
  const data = _interopRequireDefault(require('jest-haste-map'));

  _jestHasteMap = function () {
    return data;
  };

  return data;
}

function _jestUtil() {
  const data = require('jest-util');

  _jestUtil = function () {
    return data;
  };

  return data;
}

var _enhanceUnexpectedTokenMessage = _interopRequireDefault(
  require('./enhanceUnexpectedTokenMessage')
);

var _shouldInstrument = _interopRequireDefault(require('./shouldInstrument'));

function _interopRequireDefault(obj) {
  return obj && obj.__esModule ? obj : {default: obj};
}

function _getRequireWildcardCache() {
  if (typeof WeakMap !== 'function') return null;
  var cache = new WeakMap();
  _getRequireWildcardCache = function () {
    return cache;
  };
  return cache;
}

function _interopRequireWildcard(obj) {
  if (obj && obj.__esModule) {
    return obj;
  }
  if (obj === null || (typeof obj !== 'object' && typeof obj !== 'function')) {
    return {default: obj};
  }
  var cache = _getRequireWildcardCache();
  if (cache && cache.has(obj)) {
    return cache.get(obj);
  }
  var newObj = {};
  var hasPropertyDescriptor =
    Object.defineProperty && Object.getOwnPropertyDescriptor;
  for (var key in obj) {
    if (Object.prototype.hasOwnProperty.call(obj, key)) {
      var desc = hasPropertyDescriptor
        ? Object.getOwnPropertyDescriptor(obj, key)
        : null;
      if (desc && (desc.get || desc.set)) {
        Object.defineProperty(newObj, key, desc);
      } else {
        newObj[key] = obj[key];
      }
    }
  }
  newObj.default = obj;
  if (cache) {
    cache.set(obj, newObj);
  }
  return newObj;
}

function _defineProperty(obj, key, value) {
  if (key in obj) {
    Object.defineProperty(obj, key, {
      value: value,
      enumerable: true,
      configurable: true,
      writable: true
    });
  } else {
    obj[key] = value;
  }
  return obj;
}

// Use `require` to avoid TS rootDir
const {version: VERSION} = require('../package.json');

// This data structure is used to avoid recalculating some data every time that
// we need to transform a file. Since ScriptTransformer is instantiated for each
// file we need to keep this object in the local scope of this module.
const projectCaches = new Map(); // To reset the cache for specific changesets (rather than package version).

const CACHE_VERSION = '1';

async function waitForPromiseWithCleanup(promise, cleanup) {
  try {
    await promise;
  } finally {
    cleanup();
  }
}

class ScriptTransformer {
  constructor(config) {
    _defineProperty(this, '_cache', void 0);

    _defineProperty(this, '_config', void 0);

    _defineProperty(this, '_transformCache', void 0);

    _defineProperty(this, '_transformConfigCache', void 0);

    this._config = config;
    this._transformCache = new Map();
    this._transformConfigCache = new Map();
    const configString = (0, _fastJsonStableStringify().default)(this._config);
    let projectCache = projectCaches.get(configString);

    if (!projectCache) {
      projectCache = {
        configString,
        ignorePatternsRegExp: calcIgnorePatternRegExp(this._config),
        transformRegExp: calcTransformRegExp(this._config),
        transformedFiles: new Map()
      };
      projectCaches.set(configString, projectCache);
    }

    this._cache = projectCache;
  }

  _getCacheKey(
    fileData,
    filename,
    instrument,
    supportsDynamicImport,
    supportsStaticESM
  ) {
    const configString = this._cache.configString;

    const transformer = this._getTransformer(filename);

    if (transformer && typeof transformer.getCacheKey === 'function') {
      return (0, _crypto().createHash)('md5')
        .update(
          transformer.getCacheKey(fileData, filename, configString, {
            config: this._config,
            instrument,
            rootDir: this._config.rootDir,
            supportsDynamicImport,
            supportsStaticESM
          })
        )
        .update(CACHE_VERSION)
        .digest('hex');
    } else {
      return (0, _crypto().createHash)('md5')
        .update(fileData)
        .update(configString)
        .update(instrument ? 'instrument' : '')
        .update(filename)
        .update(CACHE_VERSION)
        .digest('hex');
    }
  }

  _getFileCachePath(
    filename,
    content,
    instrument,
    supportsDynamicImport,
    supportsStaticESM
  ) {
    const baseCacheDir = _jestHasteMap().default.getCacheFilePath(
      this._config.cacheDirectory,
      'jest-transform-cache-' + this._config.name,
      VERSION
    );

    const cacheKey = this._getCacheKey(
      content,
      filename,
      instrument,
      supportsDynamicImport,
      supportsStaticESM
    ); // Create sub folders based on the cacheKey to avoid creating one
    // directory with many files.

    const cacheDir = path().join(baseCacheDir, cacheKey[0] + cacheKey[1]);
    const cacheFilenamePrefix = path()
      .basename(filename, path().extname(filename))
      .replace(/\W/g, '');
    const cachePath = (0, _slash().default)(
      path().join(cacheDir, cacheFilenamePrefix + '_' + cacheKey)
    );
    (0, _jestUtil().createDirectory)(cacheDir);
    return cachePath;
  }

  _getTransformPath(filename) {
    const transformRegExp = this._cache.transformRegExp;

    if (!transformRegExp) {
      return undefined;
    }

    for (let i = 0; i < transformRegExp.length; i++) {
      if (transformRegExp[i][0].test(filename)) {
        const transformPath = transformRegExp[i][1];

        this._transformConfigCache.set(transformPath, transformRegExp[i][2]);

        return transformPath;
      }
    }

    return undefined;
  }

  _getTransformer(filename) {
    if (!this._config.transform || !this._config.transform.length) {
      return null;
    }

    const transformPath = this._getTransformPath(filename);

    if (!transformPath) {
      return null;
    }

    const transformer = this._transformCache.get(transformPath);

    if (transformer) {
      return transformer;
    }

    let transform = require(transformPath);

    if (!transform) {
      throw new TypeError('Jest: a transform must export something.');
    }

    const transformerConfig = this._transformConfigCache.get(transformPath);

    if (typeof transform.createTransformer === 'function') {
      transform = transform.createTransformer(transformerConfig);
    }

    if (typeof transform.process !== 'function') {
      throw new TypeError(
        'Jest: a transform must export a `process` function.'
      );
    }

    this._transformCache.set(transformPath, transform);

    return transform;
  }

  _instrumentFile(
    filename,
    input,
    supportsDynamicImport,
    supportsStaticESM,
    canMapToInput
  ) {
    const inputCode = typeof input === 'string' ? input : input.code;
    const inputMap = typeof input === 'string' ? null : input.map;
    const result = (0, _core().transformSync)(inputCode, {
      auxiliaryCommentBefore: ' istanbul ignore next ',
      babelrc: false,
      caller: {
        name: '@jest/transform',
        supportsDynamicImport,
        supportsStaticESM
      },
      configFile: false,
      filename,
      plugins: [
        [
          _babelPluginIstanbul().default,
          {
            compact: false,
            // files outside `cwd` will not be instrumented
            cwd: this._config.rootDir,
            exclude: [],
            extension: false,
            inputSourceMap: inputMap,
            useInlineSourceMaps: false
          }
        ]
      ],
      sourceMaps: canMapToInput ? 'both' : false
    });

    if (result && result.code) {
      return result;
    }

    return input;
  } // We don't want to expose transformers to the outside - this function is just
  // to warm up `this._transformCache`

  preloadTransformer(filepath) {
    this._getTransformer(filepath);
  } // TODO: replace third argument with TransformOptions in Jest 26

  transformSource(
    filepath,
    content,
    instrument,
    supportsDynamicImport = false,
    supportsStaticESM = false
  ) {
    const filename = (0, _jestUtil().tryRealpath)(filepath);

    const transform = this._getTransformer(filename);

    const cacheFilePath = this._getFileCachePath(
      filename,
      content,
      instrument,
      supportsDynamicImport,
      supportsStaticESM
    );

    let sourceMapPath = cacheFilePath + '.map'; // Ignore cache if `config.cache` is set (--no-cache)

    let code = this._config.cache ? readCodeCacheFile(cacheFilePath) : null;
    const shouldCallTransform = transform && this.shouldTransform(filename); // That means that the transform has a custom instrumentation
    // logic and will handle it based on `config.collectCoverage` option

    const transformWillInstrument =
      shouldCallTransform && transform && transform.canInstrument;

    if (code) {
      // This is broken: we return the code, and a path for the source map
      // directly from the cache. But, nothing ensures the source map actually
      // matches that source code. They could have gotten out-of-sync in case
      // two separate processes write concurrently to the same cache files.
      return {
        code,
        originalCode: content,
        sourceMapPath
      };
    }

    let transformed = {
      code: content,
      map: null
    };

    if (transform && shouldCallTransform) {
      const processed = transform.process(content, filename, this._config, {
        instrument,
        supportsDynamicImport,
        supportsStaticESM
      });

      if (typeof processed === 'string') {
        transformed.code = processed;
      } else if (processed != null && typeof processed.code === 'string') {
        transformed = processed;
      } else {
        throw new TypeError(
          "Jest: a transform's `process` function must return a string, " +
            'or an object with `code` key containing this string.'
        );
      }
    }

    if (!transformed.map) {
      try {
        //Could be a potential freeze here.
        //See: https://github.com/facebook/jest/pull/5177#discussion_r158883570
        const inlineSourceMap = (0, _convertSourceMap().fromSource)(
          transformed.code
        );

        if (inlineSourceMap) {
          transformed.map = inlineSourceMap.toObject();
        }
      } catch {
        const transformPath = this._getTransformPath(filename);

        console.warn(
          `jest-transform: The source map produced for the file ${filename} ` +
            `by ${transformPath} was invalid. Proceeding without source ` +
            'mapping for that file.'
        );
      }
    } // Apply instrumentation to the code if necessary, keeping the instrumented code and new map

    let map = transformed.map;

    if (!transformWillInstrument && instrument) {
      /**
       * We can map the original source code to the instrumented code ONLY if
       * - the process of transforming the code produced a source map e.g. ts-jest
       * - we did not transform the source code
       *
       * Otherwise we cannot make any statements about how the instrumented code corresponds to the original code,
       * and we should NOT emit any source maps
       *
       */
      const shouldEmitSourceMaps =
        (transform != null && map != null) || transform == null;

      const instrumented = this._instrumentFile(
        filename,
        transformed,
        supportsDynamicImport,
        supportsStaticESM,
        shouldEmitSourceMaps
      );

      code =
        typeof instrumented === 'string' ? instrumented : instrumented.code;
      map = typeof instrumented === 'string' ? null : instrumented.map;
    } else {
      code = transformed.code;
    }

    if (map) {
      const sourceMapContent =
        typeof map === 'string' ? map : JSON.stringify(map);
      writeCacheFile(sourceMapPath, sourceMapContent);
    } else {
      sourceMapPath = null;
    }

    writeCodeCacheFile(cacheFilePath, code);
    return {
      code,
      originalCode: content,
      sourceMapPath
    };
  }

  _transformAndBuildScript(filename, options, instrument, fileSource) {
    const {
      isCoreModule,
      isInternalModule,
      supportsDynamicImport,
      supportsStaticESM
    } = options;
    const content = stripShebang(
      fileSource || fs().readFileSync(filename, 'utf8')
    );
    let code = content;
    let sourceMapPath = null;
    const willTransform =
      !isInternalModule &&
      !isCoreModule &&
      (this.shouldTransform(filename) || instrument);

    try {
      if (willTransform) {
        const transformedSource = this.transformSource(
          filename,
          content,
          instrument,
          supportsDynamicImport,
          supportsStaticESM
        );
        code = transformedSource.code;
        sourceMapPath = transformedSource.sourceMapPath;
      }

      return {
        code,
        originalCode: content,
        sourceMapPath
      };
    } catch (e) {
      throw (0, _enhanceUnexpectedTokenMessage.default)(e);
    }
  }

  transform(filename, options, fileSource) {
    let scriptCacheKey = undefined;
    let instrument = false;

    if (!options.isCoreModule) {
      instrument =
        options.coverageProvider === 'babel' &&
        (0, _shouldInstrument.default)(filename, options, this._config);
      scriptCacheKey = getScriptCacheKey(filename, instrument);

      const result = this._cache.transformedFiles.get(scriptCacheKey);

      if (result) {
        return result;
      }
    }

    const result = this._transformAndBuildScript(
      filename,
      options,
      instrument,
      fileSource
    );

    if (scriptCacheKey) {
      this._cache.transformedFiles.set(scriptCacheKey, result);
    }

    return result;
  }

  transformJson(filename, options, fileSource) {
    const {
      isCoreModule,
      isInternalModule,
      supportsDynamicImport,
      supportsStaticESM
    } = options;
    const willTransform =
      !isInternalModule && !isCoreModule && this.shouldTransform(filename);

    if (willTransform) {
      const {code: transformedJsonSource} = this.transformSource(
        filename,
        fileSource,
        false,
        supportsDynamicImport,
        supportsStaticESM
      );
      return transformedJsonSource;
    }

    return fileSource;
  }

  requireAndTranspileModule(moduleName, callback) {
    // Load the transformer to avoid a cycle where we need to load a
    // transformer in order to transform it in the require hooks
    this.preloadTransformer(moduleName);
    let transforming = false;
    const revertHook = (0, _pirates().addHook)(
      (code, filename) => {
        try {
          transforming = true;
          return (
            // we might wanna do `supportsDynamicImport` at some point
            this.transformSource(filename, code, false, false, false).code ||
            code
          );
        } finally {
          transforming = false;
        }
      },
      {
        exts: this._config.moduleFileExtensions.map(ext => `.${ext}`),
        ignoreNodeModules: false,
        matcher: filename => {
          if (transforming) {
            // Don't transform any dependency required by the transformer itself
            return false;
          }

          return this.shouldTransform(filename);
        }
      }
    );

    const module = require(moduleName);

    if (!callback) {
      revertHook();
      return module;
    }

    try {
      const cbResult = callback(module);

      if ((0, _jestUtil().isPromise)(cbResult)) {
        return waitForPromiseWithCleanup(cbResult, revertHook).then(
          () => module
        );
      }
    } finally {
      revertHook();
    }

    return module;
  }
  /**
   * @deprecated use `this.shouldTransform` instead
   */
  // @ts-expect-error: Unused and private - remove in Jest 25

  _shouldTransform(filename) {
    return this.shouldTransform(filename);
  }

  shouldTransform(filename) {
    const ignoreRegexp = this._cache.ignorePatternsRegExp;
    const isIgnored = ignoreRegexp ? ignoreRegexp.test(filename) : false;
    return (
      !!this._config.transform && !!this._config.transform.length && !isIgnored
    );
  }
} // TODO: do we need to define the generics twice?

exports.default = ScriptTransformer;

function createTranspilingRequire(config) {
  const transformer = new ScriptTransformer(config);
  return function requireAndTranspileModule(
    resolverPath,
    applyInteropRequireDefault = false
  ) {
    const transpiledModule = transformer.requireAndTranspileModule(
      resolverPath
    );
    return applyInteropRequireDefault
      ? (0, _jestUtil().interopRequireDefault)(transpiledModule).default
      : transpiledModule;
  };
}

const removeFile = path => {
  try {
    fs().unlinkSync(path);
  } catch {}
};

const stripShebang = content => {
  // If the file data starts with a shebang remove it. Leaves the empty line
  // to keep stack trace line numbers correct.
  if (content.startsWith('#!')) {
    return content.replace(/^#!.*/, '');
  } else {
    return content;
  }
};
/**
 * This is like `writeCacheFile` but with an additional sanity checksum. We
 * cannot use the same technique for source maps because we expose source map
 * cache file paths directly to callsites, with the expectation they can read
 * it right away. This is not a great system, because source map cache file
 * could get corrupted, out-of-sync, etc.
 */

function writeCodeCacheFile(cachePath, code) {
  const checksum = (0, _crypto().createHash)('md5').update(code).digest('hex');
  writeCacheFile(cachePath, checksum + '\n' + code);
}
/**
 * Read counterpart of `writeCodeCacheFile`. We verify that the content of the
 * file matches the checksum, in case some kind of corruption happened. This
 * could happen if an older version of `jest-runtime` writes non-atomically to
 * the same cache, for example.
 */

function readCodeCacheFile(cachePath) {
  const content = readCacheFile(cachePath);

  if (content == null) {
    return null;
  }

  const code = content.substr(33);
  const checksum = (0, _crypto().createHash)('md5').update(code).digest('hex');

  if (checksum === content.substr(0, 32)) {
    return code;
  }

  return null;
}
/**
 * Writing to the cache atomically relies on 'rename' being atomic on most
 * file systems. Doing atomic write reduces the risk of corruption by avoiding
 * two processes to write to the same file at the same time. It also reduces
 * the risk of reading a file that's being overwritten at the same time.
 */

const writeCacheFile = (cachePath, fileData) => {
  try {
    (0, _writeFileAtomic().sync)(cachePath, fileData, {
      encoding: 'utf8',
      fsync: false
    });
  } catch (e) {
    if (cacheWriteErrorSafeToIgnore(e, cachePath)) {
      return;
    }

    e.message =
      'jest: failed to cache transform results in: ' +
      cachePath +
      '\nFailure message: ' +
      e.message;
    removeFile(cachePath);
    throw e;
  }
};
/**
 * On Windows, renames are not atomic, leading to EPERM exceptions when two
 * processes attempt to rename to the same target file at the same time.
 * If the target file exists we can be reasonably sure another process has
 * legitimately won a cache write race and ignore the error.
 */

const cacheWriteErrorSafeToIgnore = (e, cachePath) =>
  process.platform === 'win32' &&
  e.code === 'EPERM' &&
  fs().existsSync(cachePath);

const readCacheFile = cachePath => {
  if (!fs().existsSync(cachePath)) {
    return null;
  }

  let fileData;

  try {
    fileData = fs().readFileSync(cachePath, 'utf8');
  } catch (e) {
    e.message =
      'jest: failed to read cache file: ' +
      cachePath +
      '\nFailure message: ' +
      e.message;
    removeFile(cachePath);
    throw e;
  }

  if (fileData == null) {
    // We must have somehow created the file but failed to write to it,
    // let's delete it and retry.
    removeFile(cachePath);
  }

  return fileData;
};

const getScriptCacheKey = (filename, instrument) => {
  const mtime = fs().statSync(filename).mtime;
  return filename + '_' + mtime.getTime() + (instrument ? '_instrumented' : '');
};

const calcIgnorePatternRegExp = config => {
  if (
    !config.transformIgnorePatterns ||
    config.transformIgnorePatterns.length === 0
  ) {
    return undefined;
  }

  return new RegExp(config.transformIgnorePatterns.join('|'));
};

const calcTransformRegExp = config => {
  if (!config.transform.length) {
    return undefined;
  }

  const transformRegexp = [];

  for (let i = 0; i < config.transform.length; i++) {
    transformRegexp.push([
      new RegExp(config.transform[i][0]),
      config.transform[i][1],
      config.transform[i][2]
    ]);
  }

  return transformRegexp;
};

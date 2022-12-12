'use strict';

function nativeModule() {
  const data = _interopRequireWildcard(require('module'));

  nativeModule = function () {
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

function _url() {
  const data = require('url');

  _url = function () {
    return data;
  };

  return data;
}

function _vm() {
  const data = require('vm');

  _vm = function () {
    return data;
  };

  return data;
}

function _cjsModuleLexer() {
  const data = require('cjs-module-lexer');

  _cjsModuleLexer = function () {
    return data;
  };

  return data;
}

function _collectV8Coverage() {
  const data = require('collect-v8-coverage');

  _collectV8Coverage = function () {
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

function _stripBom() {
  const data = _interopRequireDefault(require('strip-bom'));

  _stripBom = function () {
    return data;
  };

  return data;
}

function _fakeTimers() {
  const data = require('@jest/fake-timers');

  _fakeTimers = function () {
    return data;
  };

  return data;
}

function _transform() {
  const data = require('@jest/transform');

  _transform = function () {
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

function _jestMessageUtil() {
  const data = require('jest-message-util');

  _jestMessageUtil = function () {
    return data;
  };

  return data;
}

function _jestMock() {
  const data = _interopRequireDefault(require('jest-mock'));

  _jestMock = function () {
    return data;
  };

  return data;
}

function _jestRegexUtil() {
  const data = require('jest-regex-util');

  _jestRegexUtil = function () {
    return data;
  };

  return data;
}

function _jestResolve() {
  const data = _interopRequireDefault(require('jest-resolve'));

  _jestResolve = function () {
    return data;
  };

  return data;
}

function _jestSnapshot() {
  const data = _interopRequireDefault(require('jest-snapshot'));

  _jestSnapshot = function () {
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

var _cli = require('./cli');

var _args = require('./cli/args');

var _helpers = require('./helpers');

var _Object$fromEntries;

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

const esmIsAvailable = typeof _vm().SourceTextModule === 'function';
const defaultTransformOptions = {
  isInternalModule: false,
  supportsDynamicImport: esmIsAvailable,
  supportsExportNamespaceFrom: false,
  supportsStaticESM: false,
  supportsTopLevelAwait: false
};
const OUTSIDE_JEST_VM_RESOLVE_OPTION = Symbol.for(
  'OUTSIDE_JEST_VM_RESOLVE_OPTION'
);
const fromEntries =
  (_Object$fromEntries = Object.fromEntries) !== null &&
  _Object$fromEntries !== void 0
    ? _Object$fromEntries
    : function fromEntries(iterable) {
        return [...iterable].reduce((obj, [key, val]) => {
          obj[key] = val;
          return obj;
        }, {});
      };
const testTimeoutSymbol = Symbol.for('TEST_TIMEOUT_SYMBOL');
const retryTimesSymbol = Symbol.for('RETRY_TIMES');
const NODE_MODULES = path().sep + 'node_modules' + path().sep;

const getModuleNameMapper = config => {
  if (
    Array.isArray(config.moduleNameMapper) &&
    config.moduleNameMapper.length
  ) {
    return config.moduleNameMapper.map(([regex, moduleName]) => ({
      moduleName,
      regex: new RegExp(regex)
    }));
  }

  return null;
};

const unmockRegExpCache = new WeakMap();
const EVAL_RESULT_VARIABLE = 'Object.<anonymous>';
const runtimeSupportsVmModules = typeof _vm().SyntheticModule === 'function';

const supportsTopLevelAwait =
  runtimeSupportsVmModules &&
  (() => {
    try {
      // eslint-disable-next-line no-new
      new (_vm().SourceTextModule)('await Promise.resolve()');
      return true;
    } catch {
      return false;
    }
  })();

class Runtime {
  constructor(
    config,
    environment,
    resolver,
    cacheFS = {},
    coverageOptions, // TODO: Make mandatory in Jest 27
    testPath
  ) {
    _defineProperty(this, '_cacheFS', void 0);

    _defineProperty(this, '_config', void 0);

    _defineProperty(this, '_coverageOptions', void 0);

    _defineProperty(this, '_currentlyExecutingModulePath', void 0);

    _defineProperty(this, '_environment', void 0);

    _defineProperty(this, '_explicitShouldMock', void 0);

    _defineProperty(this, '_fakeTimersImplementation', void 0);

    _defineProperty(this, '_internalModuleRegistry', void 0);

    _defineProperty(this, '_isCurrentlyExecutingManualMock', void 0);

    _defineProperty(this, '_mainModule', void 0);

    _defineProperty(this, '_mockFactories', void 0);

    _defineProperty(this, '_mockMetaDataCache', void 0);

    _defineProperty(this, '_mockRegistry', void 0);

    _defineProperty(this, '_isolatedMockRegistry', void 0);

    _defineProperty(this, '_moduleMocker', void 0);

    _defineProperty(this, '_isolatedModuleRegistry', void 0);

    _defineProperty(this, '_moduleRegistry', void 0);

    _defineProperty(this, '_esmoduleRegistry', void 0);

    _defineProperty(this, '_testPath', void 0);

    _defineProperty(this, '_resolver', void 0);

    _defineProperty(this, '_shouldAutoMock', void 0);

    _defineProperty(this, '_shouldMockModuleCache', void 0);

    _defineProperty(this, '_shouldUnmockTransitiveDependenciesCache', void 0);

    _defineProperty(this, '_sourceMapRegistry', void 0);

    _defineProperty(this, '_scriptTransformer', void 0);

    _defineProperty(this, '_fileTransforms', void 0);

    _defineProperty(this, '_v8CoverageInstrumenter', void 0);

    _defineProperty(this, '_v8CoverageResult', void 0);

    _defineProperty(this, '_transitiveShouldMock', void 0);

    _defineProperty(this, '_unmockList', void 0);

    _defineProperty(this, '_virtualMocks', void 0);

    _defineProperty(this, '_moduleImplementation', void 0);

    _defineProperty(this, 'jestObjectCaches', void 0);

    _defineProperty(this, 'jestGlobals', void 0);

    _defineProperty(
      this,
      'unstable_shouldLoadAsEsm',
      _jestResolve().default.unstable_shouldLoadAsEsm
    );

    this._cacheFS = new Map(Object.entries(cacheFS));
    this._config = config;
    this._coverageOptions = coverageOptions || {
      changedFiles: undefined,
      collectCoverage: false,
      collectCoverageFrom: [],
      collectCoverageOnlyFrom: undefined,
      coverageProvider: 'babel',
      sourcesRelatedToTestsInChangedFiles: undefined
    };
    this._currentlyExecutingModulePath = '';
    this._environment = environment;
    this._explicitShouldMock = new Map();
    this._internalModuleRegistry = new Map();
    this._isCurrentlyExecutingManualMock = null;
    this._mainModule = null;
    this._mockFactories = new Map();
    this._mockRegistry = new Map(); // during setup, this cannot be null (and it's fine to explode if it is)

    this._moduleMocker = this._environment.moduleMocker;
    this._isolatedModuleRegistry = null;
    this._isolatedMockRegistry = null;
    this._moduleRegistry = new Map();
    this._esmoduleRegistry = new Map();
    this._testPath = testPath;
    this._resolver = resolver;
    this._scriptTransformer = new (_transform().ScriptTransformer)(config);
    this._shouldAutoMock = config.automock;
    this._sourceMapRegistry = new Map();
    this._fileTransforms = new Map();
    this._virtualMocks = new Map();
    this.jestObjectCaches = new Map();
    this._mockMetaDataCache = new Map();
    this._shouldMockModuleCache = new Map();
    this._shouldUnmockTransitiveDependenciesCache = new Map();
    this._transitiveShouldMock = new Map();
    this._fakeTimersImplementation =
      config.timers === 'modern'
        ? this._environment.fakeTimersModern
        : this._environment.fakeTimers;
    this._unmockList = unmockRegExpCache.get(config);

    if (!this._unmockList && config.unmockedModulePathPatterns) {
      this._unmockList = new RegExp(
        config.unmockedModulePathPatterns.join('|')
      );
      unmockRegExpCache.set(config, this._unmockList);
    }

    if (config.automock) {
      const virtualMocks = fromEntries(this._virtualMocks);
      config.setupFiles.forEach(filePath => {
        if (filePath && filePath.includes(NODE_MODULES)) {
          const moduleID = this._resolver.getModuleID(virtualMocks, filePath);

          this._transitiveShouldMock.set(moduleID, false);
        }
      });
    }

    this.resetModules();
  }

  static createContext(config, options) {
    (0, _jestUtil().createDirectory)(config.cacheDirectory);
    const instance = Runtime.createHasteMap(config, {
      console: options.console,
      maxWorkers: options.maxWorkers,
      resetCache: !config.cache,
      watch: options.watch,
      watchman: options.watchman
    });
    return instance.build().then(
      hasteMap => ({
        config,
        hasteFS: hasteMap.hasteFS,
        moduleMap: hasteMap.moduleMap,
        resolver: Runtime.createResolver(config, hasteMap.moduleMap)
      }),
      error => {
        throw error;
      }
    );
  }

  static createHasteMap(config, options) {
    const ignorePatternParts = [
      ...config.modulePathIgnorePatterns,
      ...(options && options.watch ? config.watchPathIgnorePatterns : []),
      config.cacheDirectory.startsWith(config.rootDir + path().sep) &&
        config.cacheDirectory
    ].filter(Boolean);
    const ignorePattern =
      ignorePatternParts.length > 0
        ? new RegExp(ignorePatternParts.join('|'))
        : undefined;
    return new (_jestHasteMap().default)({
      cacheDirectory: config.cacheDirectory,
      computeSha1: config.haste.computeSha1,
      console: options && options.console,
      dependencyExtractor: config.dependencyExtractor,
      extensions: [_jestSnapshot().default.EXTENSION].concat(
        config.moduleFileExtensions
      ),
      hasteImplModulePath: config.haste.hasteImplModulePath,
      ignorePattern,
      maxWorkers: (options && options.maxWorkers) || 1,
      mocksPattern: (0, _jestRegexUtil().escapePathForRegex)(
        path().sep + '__mocks__' + path().sep
      ),
      name: config.name,
      platforms: config.haste.platforms || ['ios', 'android'],
      resetCache: options && options.resetCache,
      retainAllFiles: false,
      rootDir: config.rootDir,
      roots: config.roots,
      throwOnModuleCollision: config.haste.throwOnModuleCollision,
      useWatchman: options && options.watchman,
      watch: options && options.watch
    });
  }

  static createResolver(config, moduleMap) {
    return new (_jestResolve().default)(moduleMap, {
      defaultPlatform: config.haste.defaultPlatform,
      extensions: config.moduleFileExtensions.map(extension => '.' + extension),
      hasCoreModules: true,
      moduleDirectories: config.moduleDirectories,
      moduleNameMapper: getModuleNameMapper(config),
      modulePaths: config.modulePaths,
      platforms: config.haste.platforms,
      resolver: config.resolver,
      rootDir: config.rootDir
    });
  }

  static runCLI(args, info) {
    return (0, _cli.run)(args, info);
  }

  static getCLIOptions() {
    return _args.options;
  } // unstable as it should be replaced by https://github.com/nodejs/modules/issues/393, and we don't want people to use it

  async loadEsmModule(modulePath, query = '') {
    const cacheKey = modulePath + query;

    if (!this._esmoduleRegistry.has(cacheKey)) {
      invariant(
        typeof this._environment.getVmContext === 'function',
        'ES Modules are only supported if your test environment has the `getVmContext` function'
      );

      const context = this._environment.getVmContext();

      invariant(context);

      if (this._resolver.isCoreModule(modulePath)) {
        const core = await this._importCoreModule(modulePath, context);

        this._esmoduleRegistry.set(cacheKey, core);

        return core;
      }

      const transformedCode = this.transformFile(modulePath, {
        isInternalModule: false,
        supportsDynamicImport: true,
        supportsExportNamespaceFrom: true,
        supportsStaticESM: true,
        supportsTopLevelAwait
      });
      const module = new (_vm().SourceTextModule)(transformedCode, {
        context,
        identifier: modulePath,
        importModuleDynamically: (specifier, referencingModule) =>
          this.linkModules(
            specifier,
            referencingModule.identifier,
            referencingModule.context
          ),

        initializeImportMeta(meta) {
          meta.url = (0, _url().pathToFileURL)(modulePath).href;
        }
      });

      this._esmoduleRegistry.set(
        cacheKey, // we wanna put the linking promise in the cache so modules loaded in
        // parallel can all await it. We then await it synchronously below, so
        // we shouldn't get any unhandled rejections
        module
          .link((specifier, referencingModule) =>
            this.linkModules(
              specifier,
              referencingModule.identifier,
              referencingModule.context
            )
          )
          .then(() => module.evaluate())
          .then(() => module)
      );
    }

    const module = this._esmoduleRegistry.get(cacheKey);

    invariant(module);
    return module;
  }

  linkModules(specifier, referencingIdentifier, context) {
    if (specifier === '@jest/globals') {
      const fromCache = this._esmoduleRegistry.get('@jest/globals');

      if (fromCache) {
        return fromCache;
      }

      const globals = this.getGlobalsForEsm(referencingIdentifier, context);

      this._esmoduleRegistry.set('@jest/globals', globals);

      return globals;
    }

    if (specifier.startsWith('file://')) {
      specifier = (0, _url().fileURLToPath)(specifier);
    }

    const [path, query] = specifier.split('?');

    const resolved = this._resolveModule(referencingIdentifier, path);

    if (
      this._resolver.isCoreModule(resolved) ||
      this.unstable_shouldLoadAsEsm(resolved)
    ) {
      return this.loadEsmModule(resolved, query);
    }

    return this.loadCjsAsEsm(referencingIdentifier, resolved, context);
  }

  async unstable_importModule(from, moduleName) {
    invariant(
      runtimeSupportsVmModules,
      'You need to run with a version of node that supports ES Modules in the VM API.'
    );
    const [path, query] = (moduleName !== null && moduleName !== void 0
      ? moduleName
      : ''
    ).split('?');

    const modulePath = this._resolveModule(from, path);

    return this.loadEsmModule(modulePath, query);
  }

  loadCjsAsEsm(from, modulePath, context) {
    // CJS loaded via `import` should share cache with other CJS: https://github.com/nodejs/modules/issues/503
    const cjs = this.requireModuleOrMock(from, modulePath);

    const transformedCode = this._fileTransforms.get(modulePath);

    let cjsExports = [];

    if (transformedCode) {
      const {exports} = (0, _cjsModuleLexer().parse)(transformedCode.code);
      cjsExports = exports.filter(exportName => {
        // we don't wanna respect any exports _names_ default as a named export
        if (exportName === 'default') {
          return false;
        }

        return Object.hasOwnProperty.call(cjs, exportName);
      });
    }

    const module = new (_vm().SyntheticModule)(
      [...cjsExports, 'default'],
      function () {
        cjsExports.forEach(exportName => {
          // @ts-expect-error
          this.setExport(exportName, cjs[exportName]);
        }); // @ts-expect-error: TS doesn't know what `this` is

        this.setExport('default', cjs);
      },
      {
        context,
        identifier: modulePath
      }
    );
    return evaluateSyntheticModule(module);
  }

  requireModule(from, moduleName, options, isRequireActual) {
    const moduleID = this._resolver.getModuleID(
      fromEntries(this._virtualMocks),
      from,
      moduleName
    );

    let modulePath; // Some old tests rely on this mocking behavior. Ideally we'll change this
    // to be more explicit.

    const moduleResource = moduleName && this._resolver.getModule(moduleName);

    const manualMock =
      moduleName && this._resolver.getMockModule(from, moduleName);

    if (
      !(options === null || options === void 0
        ? void 0
        : options.isInternalModule) &&
      !isRequireActual &&
      !moduleResource &&
      manualMock &&
      manualMock !== this._isCurrentlyExecutingManualMock &&
      this._explicitShouldMock.get(moduleID) !== false
    ) {
      modulePath = manualMock;
    }

    if (moduleName && this._resolver.isCoreModule(moduleName)) {
      return this._requireCoreModule(moduleName);
    }

    if (!modulePath) {
      modulePath = this._resolveModule(from, moduleName);
    }

    let moduleRegistry;

    if (
      options === null || options === void 0 ? void 0 : options.isInternalModule
    ) {
      moduleRegistry = this._internalModuleRegistry;
    } else {
      if (
        this._moduleRegistry.get(modulePath) ||
        !this._isolatedModuleRegistry
      ) {
        moduleRegistry = this._moduleRegistry;
      } else {
        moduleRegistry = this._isolatedModuleRegistry;
      }
    }

    const module = moduleRegistry.get(modulePath);

    if (module) {
      return module.exports;
    } // We must register the pre-allocated module object first so that any
    // circular dependencies that may arise while evaluating the module can
    // be satisfied.

    const localModule = {
      children: [],
      exports: {},
      filename: modulePath,
      id: modulePath,
      loaded: false,
      path: path().dirname(modulePath)
    };
    moduleRegistry.set(modulePath, localModule);

    this._loadModule(
      localModule,
      from,
      moduleName,
      modulePath,
      options,
      moduleRegistry
    );

    return localModule.exports;
  }

  requireInternalModule(from, to) {
    if (to) {
      const outsideJestVmPath = (0, _helpers.decodePossibleOutsideJestVmPath)(
        to
      );

      if (outsideJestVmPath) {
        return require(outsideJestVmPath);
      }
    }

    return this.requireModule(from, to, {
      isInternalModule: true,
      supportsDynamicImport: esmIsAvailable,
      supportsExportNamespaceFrom: false,
      supportsStaticESM: false,
      supportsTopLevelAwait: false
    });
  }

  requireActual(from, moduleName) {
    return this.requireModule(from, moduleName, undefined, true);
  }

  requireMock(from, moduleName) {
    const moduleID = this._resolver.getModuleID(
      fromEntries(this._virtualMocks),
      from,
      moduleName
    );

    if (
      this._isolatedMockRegistry &&
      this._isolatedMockRegistry.get(moduleID)
    ) {
      return this._isolatedMockRegistry.get(moduleID);
    } else if (this._mockRegistry.get(moduleID)) {
      return this._mockRegistry.get(moduleID);
    }

    const mockRegistry = this._isolatedMockRegistry || this._mockRegistry;

    if (this._mockFactories.has(moduleID)) {
      // has check above makes this ok
      const module = this._mockFactories.get(moduleID)();

      mockRegistry.set(moduleID, module);
      return module;
    }

    const manualMockOrStub = this._resolver.getMockModule(from, moduleName);

    let modulePath =
      this._resolver.getMockModule(from, moduleName) ||
      this._resolveModule(from, moduleName);

    let isManualMock =
      manualMockOrStub &&
      !this._resolver.resolveStubModuleName(from, moduleName);

    if (!isManualMock) {
      // If the actual module file has a __mocks__ dir sitting immediately next
      // to it, look to see if there is a manual mock for this file.
      //
      // subDir1/my_module.js
      // subDir1/__mocks__/my_module.js
      // subDir2/my_module.js
      // subDir2/__mocks__/my_module.js
      //
      // Where some other module does a relative require into each of the
      // respective subDir{1,2} directories and expects a manual mock
      // corresponding to that particular my_module.js file.
      const moduleDir = path().dirname(modulePath);
      const moduleFileName = path().basename(modulePath);
      const potentialManualMock = path().join(
        moduleDir,
        '__mocks__',
        moduleFileName
      );

      if (fs().existsSync(potentialManualMock)) {
        isManualMock = true;
        modulePath = potentialManualMock;
      }
    }

    if (isManualMock) {
      const localModule = {
        children: [],
        exports: {},
        filename: modulePath,
        id: modulePath,
        loaded: false,
        path: path().dirname(modulePath)
      };

      this._loadModule(
        localModule,
        from,
        moduleName,
        modulePath,
        undefined,
        mockRegistry
      );

      mockRegistry.set(moduleID, localModule.exports);
    } else {
      // Look for a real module to generate an automock from
      mockRegistry.set(moduleID, this._generateMock(from, moduleName));
    }

    return mockRegistry.get(moduleID);
  }

  _loadModule(
    localModule,
    from,
    moduleName,
    modulePath,
    options,
    moduleRegistry
  ) {
    if (path().extname(modulePath) === '.json') {
      const text = (0, _stripBom().default)(this.readFile(modulePath));

      const transformedFile = this._scriptTransformer.transformJson(
        modulePath,
        this._getFullTransformationOptions(options),
        text
      );

      localModule.exports = this._environment.global.JSON.parse(
        transformedFile
      );
    } else if (path().extname(modulePath) === '.node') {
      localModule.exports = require(modulePath);
    } else {
      // Only include the fromPath if a moduleName is given. Else treat as root.
      const fromPath = moduleName ? from : null;

      this._execModule(localModule, options, moduleRegistry, fromPath);
    }

    localModule.loaded = true;
  }

  _getFullTransformationOptions(options = defaultTransformOptions) {
    return {...options, ...this._coverageOptions};
  }

  requireModuleOrMock(from, moduleName) {
    // this module is unmockable
    if (moduleName === '@jest/globals') {
      // @ts-expect-error: we don't care that it's not assignable to T
      return this.getGlobalsForCjs(from);
    }

    try {
      if (this._shouldMock(from, moduleName)) {
        return this.requireMock(from, moduleName);
      } else {
        return this.requireModule(from, moduleName);
      }
    } catch (e) {
      const moduleNotFound = _jestResolve().default.tryCastModuleNotFoundError(
        e
      );

      if (moduleNotFound) {
        if (
          moduleNotFound.siblingWithSimilarExtensionFound === null ||
          moduleNotFound.siblingWithSimilarExtensionFound === undefined
        ) {
          moduleNotFound.hint = (0, _helpers.findSiblingsWithFileExtension)(
            this._config.moduleFileExtensions,
            from,
            moduleNotFound.moduleName || moduleName
          );
          moduleNotFound.siblingWithSimilarExtensionFound = Boolean(
            moduleNotFound.hint
          );
        }

        moduleNotFound.buildMessage(this._config.rootDir);
        throw moduleNotFound;
      }

      throw e;
    }
  }

  isolateModules(fn) {
    if (this._isolatedModuleRegistry || this._isolatedMockRegistry) {
      throw new Error(
        'isolateModules cannot be nested inside another isolateModules.'
      );
    }

    this._isolatedModuleRegistry = new Map();
    this._isolatedMockRegistry = new Map();

    try {
      fn();
    } finally {
      var _this$_isolatedModule, _this$_isolatedMockRe;

      // might be cleared within the callback
      (_this$_isolatedModule = this._isolatedModuleRegistry) === null ||
      _this$_isolatedModule === void 0
        ? void 0
        : _this$_isolatedModule.clear();
      (_this$_isolatedMockRe = this._isolatedMockRegistry) === null ||
      _this$_isolatedMockRe === void 0
        ? void 0
        : _this$_isolatedMockRe.clear();
      this._isolatedModuleRegistry = null;
      this._isolatedMockRegistry = null;
    }
  }

  resetModules() {
    var _this$_isolatedModule2, _this$_isolatedMockRe2;

    (_this$_isolatedModule2 = this._isolatedModuleRegistry) === null ||
    _this$_isolatedModule2 === void 0
      ? void 0
      : _this$_isolatedModule2.clear();
    (_this$_isolatedMockRe2 = this._isolatedMockRegistry) === null ||
    _this$_isolatedMockRe2 === void 0
      ? void 0
      : _this$_isolatedMockRe2.clear();
    this._isolatedModuleRegistry = null;
    this._isolatedMockRegistry = null;

    this._mockRegistry.clear();

    this._moduleRegistry.clear();

    this._esmoduleRegistry.clear();

    if (this._environment) {
      if (this._environment.global) {
        const envGlobal = this._environment.global;
        Object.keys(envGlobal).forEach(key => {
          const globalMock = envGlobal[key];

          if (
            ((typeof globalMock === 'object' && globalMock !== null) ||
              typeof globalMock === 'function') &&
            globalMock._isMockFunction === true
          ) {
            globalMock.mockClear();
          }
        });
      }

      if (this._environment.fakeTimers) {
        this._environment.fakeTimers.clearAllTimers();
      }
    }
  }

  async collectV8Coverage() {
    this._v8CoverageInstrumenter = new (_collectV8Coverage().CoverageInstrumenter)();
    await this._v8CoverageInstrumenter.startInstrumenting();
  }

  async stopCollectingV8Coverage() {
    if (!this._v8CoverageInstrumenter) {
      throw new Error('You need to call `collectV8Coverage` first.');
    }

    this._v8CoverageResult = await this._v8CoverageInstrumenter.stopInstrumenting();
  }

  getAllCoverageInfoCopy() {
    return (0, _jestUtil().deepCyclicCopy)(
      this._environment.global.__coverage__
    );
  }

  getAllV8CoverageInfoCopy() {
    if (!this._v8CoverageResult) {
      throw new Error('You need to `stopCollectingV8Coverage` first');
    }

    return this._v8CoverageResult
      .filter(res => res.url.startsWith('file://'))
      .map(res => ({...res, url: (0, _url().fileURLToPath)(res.url)}))
      .filter(
        (
          res // TODO: will this work on windows? It might be better if `shouldInstrument` deals with it anyways
        ) =>
          res.url.startsWith(this._config.rootDir) &&
          this._fileTransforms.has(res.url) &&
          (0, _transform().shouldInstrument)(
            res.url,
            this._coverageOptions,
            this._config
          )
      )
      .map(result => {
        const transformedFile = this._fileTransforms.get(result.url);

        return {
          codeTransformResult: transformedFile,
          result
        };
      });
  } // TODO - remove in Jest 27

  getSourceMapInfo(_coveredFiles) {
    return {};
  }

  getSourceMaps() {
    return fromEntries(this._sourceMapRegistry);
  }

  setMock(from, moduleName, mockFactory, options) {
    if (options === null || options === void 0 ? void 0 : options.virtual) {
      const mockPath = this._resolver.getModulePath(from, moduleName);

      this._virtualMocks.set(mockPath, true);
    }

    const moduleID = this._resolver.getModuleID(
      fromEntries(this._virtualMocks),
      from,
      moduleName
    );

    this._explicitShouldMock.set(moduleID, true);

    this._mockFactories.set(moduleID, mockFactory);
  }

  restoreAllMocks() {
    this._moduleMocker.restoreAllMocks();
  }

  resetAllMocks() {
    this._moduleMocker.resetAllMocks();
  }

  clearAllMocks() {
    this._moduleMocker.clearAllMocks();
  }

  teardown() {
    this.restoreAllMocks();
    this.resetAllMocks();
    this.resetModules();

    this._internalModuleRegistry.clear();

    this._mainModule = null;

    this._mockFactories.clear();

    this._mockMetaDataCache.clear();

    this._shouldMockModuleCache.clear();

    this._shouldUnmockTransitiveDependenciesCache.clear();

    this._explicitShouldMock.clear();

    this._transitiveShouldMock.clear();

    this._virtualMocks.clear();

    this._cacheFS.clear();

    this._unmockList = undefined;

    this._sourceMapRegistry.clear();

    this._fileTransforms.clear();

    this.jestObjectCaches.clear();
    this._v8CoverageResult = [];
    this._v8CoverageInstrumenter = undefined;
    this._moduleImplementation = undefined;
  }

  _resolveModule(from, to) {
    return to ? this._resolver.resolveModule(from, to) : from;
  }

  _requireResolve(from, moduleName, options = {}) {
    if (moduleName == null) {
      throw new Error(
        'The first argument to require.resolve must be a string. Received null or undefined.'
      );
    }

    const {paths} = options;

    if (paths) {
      for (const p of paths) {
        const absolutePath = path().resolve(from, '..', p);

        const module = this._resolver.resolveModuleFromDirIfExists(
          absolutePath,
          moduleName, // required to also resolve files without leading './' directly in the path
          {
            paths: [absolutePath]
          }
        );

        if (module) {
          return module;
        }
      }

      throw new (_jestResolve().default.ModuleNotFoundError)(
        `Cannot resolve module '${moduleName}' from paths ['${paths.join(
          "', '"
        )}'] from ${from}`
      );
    }

    try {
      return this._resolveModule(from, moduleName);
    } catch (err) {
      const module = this._resolver.getMockModule(from, moduleName);

      if (module) {
        return module;
      } else {
        throw err;
      }
    }
  }

  _requireResolvePaths(from, moduleName) {
    if (moduleName == null) {
      throw new Error(
        'The first argument to require.resolve.paths must be a string. Received null or undefined.'
      );
    }

    if (!moduleName.length) {
      throw new Error(
        'The first argument to require.resolve.paths must not be the empty string.'
      );
    }

    if (moduleName[0] === '.') {
      return [path().resolve(from, '..')];
    }

    if (this._resolver.isCoreModule(moduleName)) {
      return null;
    }

    return this._resolver.getModulePaths(path().resolve(from, '..'));
  }

  _execModule(localModule, options, moduleRegistry, from) {
    // If the environment was disposed, prevent this module from being executed.
    if (!this._environment.global) {
      return;
    }

    const module = localModule;
    const filename = module.filename;
    const lastExecutingModulePath = this._currentlyExecutingModulePath;
    this._currentlyExecutingModulePath = filename;
    const origCurrExecutingManualMock = this._isCurrentlyExecutingManualMock;
    this._isCurrentlyExecutingManualMock = filename;
    module.children = [];
    Object.defineProperty(module, 'parent', {
      enumerable: true,

      get() {
        const key = from || '';
        return moduleRegistry.get(key) || null;
      }
    });
    module.paths = this._resolver.getModulePaths(module.path);
    Object.defineProperty(module, 'require', {
      value: this._createRequireImplementation(module, options)
    });
    const transformedCode = this.transformFile(filename, options);
    let compiledFunction = null;
    const script = this.createScriptFromCode(transformedCode, filename);
    let runScript = null; // Use this if available instead of deprecated `JestEnvironment.runScript`

    if (typeof this._environment.getVmContext === 'function') {
      const vmContext = this._environment.getVmContext();

      if (vmContext) {
        runScript = script.runInContext(vmContext, {
          filename
        });
      }
    } else {
      runScript = this._environment.runScript(script);
    }

    if (runScript !== null) {
      compiledFunction = runScript[EVAL_RESULT_VARIABLE];
    }

    if (compiledFunction === null) {
      this._logFormattedReferenceError(
        'You are trying to `import` a file after the Jest environment has been torn down.'
      );

      process.exitCode = 1;
      return;
    }

    const jestObject = this._createJestObjectFor(filename);

    this.jestObjectCaches.set(filename, jestObject);
    const lastArgs = [
      this._config.injectGlobals ? jestObject : undefined, // jest object
      ...this._config.extraGlobals.map(globalVariable => {
        if (this._environment.global[globalVariable]) {
          return this._environment.global[globalVariable];
        }

        throw new Error(
          `You have requested '${globalVariable}' as a global variable, but it was not present. Please check your config or your global environment.`
        );
      })
    ];

    if (!this._mainModule && filename === this._testPath) {
      this._mainModule = module;
    }

    Object.defineProperty(module, 'main', {
      enumerable: true,
      value: this._mainModule
    });

    try {
      compiledFunction.call(
        module.exports,
        module, // module object
        module.exports, // module exports
        module.require, // require implementation
        module.path, // __dirname
        module.filename, // __filename
        this._environment.global, // global object
        // @ts-expect-error
        ...lastArgs.filter(notEmpty)
      );
    } catch (error) {
      this.handleExecutionError(error, module);
    }

    this._isCurrentlyExecutingManualMock = origCurrExecutingManualMock;
    this._currentlyExecutingModulePath = lastExecutingModulePath;
  }

  transformFile(filename, options) {
    const source = this.readFile(filename);

    if (
      options === null || options === void 0 ? void 0 : options.isInternalModule
    ) {
      return source;
    }

    const transformedFile = this._scriptTransformer.transform(
      filename,
      this._getFullTransformationOptions(options),
      source
    );

    this._fileTransforms.set(filename, {
      ...transformedFile,
      wrapperLength: this.constructModuleWrapperStart().length
    });

    if (transformedFile.sourceMapPath) {
      this._sourceMapRegistry.set(filename, transformedFile.sourceMapPath);
    }

    return transformedFile.code;
  }

  createScriptFromCode(scriptSource, filename) {
    try {
      const scriptFilename = this._resolver.isCoreModule(filename)
        ? `jest-nodejs-core-${filename}`
        : filename;
      return new (_vm().Script)(this.wrapCodeInModuleWrapper(scriptSource), {
        displayErrors: true,
        filename: scriptFilename,
        // @ts-expect-error: Experimental ESM API
        importModuleDynamically: specifier => {
          var _this$_environment$ge, _this$_environment;

          const context =
            (_this$_environment$ge = (_this$_environment = this._environment)
              .getVmContext) === null || _this$_environment$ge === void 0
              ? void 0
              : _this$_environment$ge.call(_this$_environment);
          invariant(context);
          return this.linkModules(specifier, scriptFilename, context);
        }
      });
    } catch (e) {
      throw (0, _transform().handlePotentialSyntaxError)(e);
    }
  }

  _requireCoreModule(moduleName) {
    if (moduleName === 'process') {
      return this._environment.global.process;
    }

    if (moduleName === 'module') {
      return this._getMockedNativeModule();
    }

    return require(moduleName);
  }

  _importCoreModule(moduleName, context) {
    const required = this._requireCoreModule(moduleName);

    const module = new (_vm().SyntheticModule)(
      ['default', ...Object.keys(required)],
      function () {
        // @ts-expect-error: TS doesn't know what `this` is
        this.setExport('default', required);
        Object.entries(required).forEach(([key, value]) => {
          // @ts-expect-error: TS doesn't know what `this` is
          this.setExport(key, value);
        });
      }, // should identifier be `node://${moduleName}`?
      {
        context,
        identifier: moduleName
      }
    );
    return evaluateSyntheticModule(module);
  }

  _getMockedNativeModule() {
    if (this._moduleImplementation) {
      return this._moduleImplementation;
    }

    const createRequire = modulePath => {
      const filename =
        typeof modulePath === 'string'
          ? modulePath.startsWith('file:///')
            ? (0, _url().fileURLToPath)(new (_url().URL)(modulePath))
            : modulePath
          : (0, _url().fileURLToPath)(modulePath);

      if (!path().isAbsolute(filename)) {
        const error = new TypeError(
          `The argument 'filename' must be a file URL object, file URL string, or absolute path string. Received '${filename}'`
        ); // @ts-expect-error

        error.code = 'ERR_INVALID_ARG_TYPE';
        throw error;
      }

      return this._createRequireImplementation({
        children: [],
        exports: {},
        filename,
        id: filename,
        loaded: false,
        path: path().dirname(filename)
      });
    }; // should we implement the class ourselves?

    class Module extends nativeModule().Module {}

    Object.entries(nativeModule().Module).forEach(([key, value]) => {
      // @ts-expect-error
      Module[key] = value;
    });
    Module.Module = Module;

    if ('createRequire' in nativeModule()) {
      Module.createRequire = createRequire;
    }

    if ('createRequireFromPath' in nativeModule()) {
      Module.createRequireFromPath = function createRequireFromPath(filename) {
        if (typeof filename !== 'string') {
          const error = new TypeError(
            `The argument 'filename' must be string. Received '${filename}'.${
              filename instanceof _url().URL
                ? ' Use createRequire for URL filename.'
                : ''
            }`
          ); // @ts-expect-error

          error.code = 'ERR_INVALID_ARG_TYPE';
          throw error;
        }

        return createRequire(filename);
      };
    }

    if ('syncBuiltinESMExports' in nativeModule()) {
      Module.syncBuiltinESMExports = function syncBuiltinESMExports() {};
    }

    this._moduleImplementation = Module;
    return Module;
  }

  _generateMock(from, moduleName) {
    const modulePath =
      this._resolver.resolveStubModuleName(from, moduleName) ||
      this._resolveModule(from, moduleName);

    if (!this._mockMetaDataCache.has(modulePath)) {
      // This allows us to handle circular dependencies while generating an
      // automock
      this._mockMetaDataCache.set(
        modulePath,
        this._moduleMocker.getMetadata({}) || {}
      ); // In order to avoid it being possible for automocking to potentially
      // cause side-effects within the module environment, we need to execute
      // the module in isolation. This could cause issues if the module being
      // mocked has calls into side-effectful APIs on another module.

      const origMockRegistry = this._mockRegistry;
      const origModuleRegistry = this._moduleRegistry;
      this._mockRegistry = new Map();
      this._moduleRegistry = new Map();
      const moduleExports = this.requireModule(from, moduleName); // Restore the "real" module/mock registries

      this._mockRegistry = origMockRegistry;
      this._moduleRegistry = origModuleRegistry;

      const mockMetadata = this._moduleMocker.getMetadata(moduleExports);

      if (mockMetadata == null) {
        throw new Error(
          `Failed to get mock metadata: ${modulePath}\n\n` +
            `See: https://jestjs.io/docs/manual-mocks.html#content`
        );
      }

      this._mockMetaDataCache.set(modulePath, mockMetadata);
    }

    return this._moduleMocker.generateFromMetadata(
      // added above if missing
      this._mockMetaDataCache.get(modulePath)
    );
  }

  _shouldMock(from, moduleName) {
    const explicitShouldMock = this._explicitShouldMock;

    const moduleID = this._resolver.getModuleID(
      fromEntries(this._virtualMocks),
      from,
      moduleName
    );

    const key = from + path().delimiter + moduleID;

    if (explicitShouldMock.has(moduleID)) {
      // guaranteed by `has` above
      return explicitShouldMock.get(moduleID);
    }

    if (
      !this._shouldAutoMock ||
      this._resolver.isCoreModule(moduleName) ||
      this._shouldUnmockTransitiveDependenciesCache.get(key)
    ) {
      return false;
    }

    if (this._shouldMockModuleCache.has(moduleID)) {
      // guaranteed by `has` above
      return this._shouldMockModuleCache.get(moduleID);
    }

    let modulePath;

    try {
      modulePath = this._resolveModule(from, moduleName);
    } catch (e) {
      const manualMock = this._resolver.getMockModule(from, moduleName);

      if (manualMock) {
        this._shouldMockModuleCache.set(moduleID, true);

        return true;
      }

      throw e;
    }

    if (this._unmockList && this._unmockList.test(modulePath)) {
      this._shouldMockModuleCache.set(moduleID, false);

      return false;
    } // transitive unmocking for package managers that store flat packages (npm3)

    const currentModuleID = this._resolver.getModuleID(
      fromEntries(this._virtualMocks),
      from
    );

    if (
      this._transitiveShouldMock.get(currentModuleID) === false ||
      (from.includes(NODE_MODULES) &&
        modulePath.includes(NODE_MODULES) &&
        ((this._unmockList && this._unmockList.test(from)) ||
          explicitShouldMock.get(currentModuleID) === false))
    ) {
      this._transitiveShouldMock.set(moduleID, false);

      this._shouldUnmockTransitiveDependenciesCache.set(key, true);

      return false;
    }

    this._shouldMockModuleCache.set(moduleID, true);

    return true;
  }

  _createRequireImplementation(from, options) {
    const resolve = (moduleName, resolveOptions) => {
      const resolved = this._requireResolve(
        from.filename,
        moduleName,
        resolveOptions
      );

      if (
        (resolveOptions === null || resolveOptions === void 0
          ? void 0
          : resolveOptions[OUTSIDE_JEST_VM_RESOLVE_OPTION]) &&
        (options === null || options === void 0
          ? void 0
          : options.isInternalModule)
      ) {
        return (0, _helpers.createOutsideJestVmPath)(resolved);
      }

      return resolved;
    };

    resolve.paths = moduleName =>
      this._requireResolvePaths(from.filename, moduleName);

    const moduleRequire = (
      options === null || options === void 0 ? void 0 : options.isInternalModule
    )
      ? moduleName => this.requireInternalModule(from.filename, moduleName)
      : this.requireModuleOrMock.bind(this, from.filename);
    moduleRequire.extensions = Object.create(null);
    moduleRequire.resolve = resolve;

    moduleRequire.cache = (() => {
      // TODO: consider warning somehow that this does nothing. We should support deletions, anyways
      const notPermittedMethod = () => true;

      return new Proxy(Object.create(null), {
        defineProperty: notPermittedMethod,
        deleteProperty: notPermittedMethod,
        get: (_target, key) =>
          typeof key === 'string' ? this._moduleRegistry.get(key) : undefined,

        getOwnPropertyDescriptor() {
          return {
            configurable: true,
            enumerable: true
          };
        },

        has: (_target, key) =>
          typeof key === 'string' && this._moduleRegistry.has(key),
        ownKeys: () => Array.from(this._moduleRegistry.keys()),
        set: notPermittedMethod
      });
    })();

    Object.defineProperty(moduleRequire, 'main', {
      enumerable: true,
      value: this._mainModule
    });
    return moduleRequire;
  }

  _createJestObjectFor(from) {
    const disableAutomock = () => {
      this._shouldAutoMock = false;
      return jestObject;
    };

    const enableAutomock = () => {
      this._shouldAutoMock = true;
      return jestObject;
    };

    const unmock = moduleName => {
      const moduleID = this._resolver.getModuleID(
        fromEntries(this._virtualMocks),
        from,
        moduleName
      );

      this._explicitShouldMock.set(moduleID, false);

      return jestObject;
    };

    const deepUnmock = moduleName => {
      const moduleID = this._resolver.getModuleID(
        fromEntries(this._virtualMocks),
        from,
        moduleName
      );

      this._explicitShouldMock.set(moduleID, false);

      this._transitiveShouldMock.set(moduleID, false);

      return jestObject;
    };

    const mock = (moduleName, mockFactory, options) => {
      if (mockFactory !== undefined) {
        return setMockFactory(moduleName, mockFactory, options);
      }

      const moduleID = this._resolver.getModuleID(
        fromEntries(this._virtualMocks),
        from,
        moduleName
      );

      this._explicitShouldMock.set(moduleID, true);

      return jestObject;
    };

    const setMockFactory = (moduleName, mockFactory, options) => {
      this.setMock(from, moduleName, mockFactory, options);
      return jestObject;
    };

    const clearAllMocks = () => {
      this.clearAllMocks();
      return jestObject;
    };

    const resetAllMocks = () => {
      this.resetAllMocks();
      return jestObject;
    };

    const restoreAllMocks = () => {
      this.restoreAllMocks();
      return jestObject;
    };

    const _getFakeTimers = () => {
      if (
        !(this._environment.fakeTimers || this._environment.fakeTimersModern)
      ) {
        this._logFormattedReferenceError(
          'You are trying to access a property or method of the Jest environment after it has been torn down.'
        );

        process.exitCode = 1;
      }

      return this._fakeTimersImplementation;
    };

    const useFakeTimers = (type = 'legacy') => {
      if (type === 'modern') {
        this._fakeTimersImplementation = this._environment.fakeTimersModern;
      } else {
        this._fakeTimersImplementation = this._environment.fakeTimers;
      }

      this._fakeTimersImplementation.useFakeTimers();

      return jestObject;
    };

    const useRealTimers = () => {
      _getFakeTimers().useRealTimers();

      return jestObject;
    };

    const resetModules = () => {
      this.resetModules();
      return jestObject;
    };

    const isolateModules = fn => {
      this.isolateModules(fn);
      return jestObject;
    };

    const fn = this._moduleMocker.fn.bind(this._moduleMocker);

    const spyOn = this._moduleMocker.spyOn.bind(this._moduleMocker);

    const setTimeout = timeout => {
      if (this._environment.global.jasmine) {
        this._environment.global.jasmine._DEFAULT_TIMEOUT_INTERVAL = timeout;
      } else {
        // @ts-expect-error: https://github.com/Microsoft/TypeScript/issues/24587
        this._environment.global[testTimeoutSymbol] = timeout;
      }

      return jestObject;
    };

    const retryTimes = numTestRetries => {
      // @ts-expect-error: https://github.com/Microsoft/TypeScript/issues/24587
      this._environment.global[retryTimesSymbol] = numTestRetries;
      return jestObject;
    };

    const jestObject = {
      addMatchers: matchers =>
        this._environment.global.jasmine.addMatchers(matchers),
      advanceTimersByTime: msToRun =>
        _getFakeTimers().advanceTimersByTime(msToRun),
      advanceTimersToNextTimer: steps =>
        _getFakeTimers().advanceTimersToNextTimer(steps),
      autoMockOff: disableAutomock,
      autoMockOn: enableAutomock,
      clearAllMocks,
      clearAllTimers: () => _getFakeTimers().clearAllTimers(),
      createMockFromModule: moduleName => this._generateMock(from, moduleName),
      deepUnmock,
      disableAutomock,
      doMock: mock,
      dontMock: unmock,
      enableAutomock,
      fn,
      genMockFromModule: moduleName => this._generateMock(from, moduleName),
      getRealSystemTime: () => {
        const fakeTimers = _getFakeTimers();

        if (fakeTimers instanceof _fakeTimers().ModernFakeTimers) {
          return fakeTimers.getRealSystemTime();
        } else {
          throw new TypeError(
            'getRealSystemTime is not available when not using modern timers'
          );
        }
      },
      getTimerCount: () => _getFakeTimers().getTimerCount(),
      isMockFunction: this._moduleMocker.isMockFunction,
      isolateModules,
      mock,
      requireActual: this.requireActual.bind(this, from),
      requireMock: this.requireMock.bind(this, from),
      resetAllMocks,
      resetModuleRegistry: resetModules,
      resetModules,
      restoreAllMocks,
      retryTimes,
      runAllImmediates: () => {
        const fakeTimers = _getFakeTimers();

        if (fakeTimers instanceof _fakeTimers().LegacyFakeTimers) {
          fakeTimers.runAllImmediates();
        } else {
          throw new TypeError(
            'runAllImmediates is not available when using modern timers'
          );
        }
      },
      runAllTicks: () => _getFakeTimers().runAllTicks(),
      runAllTimers: () => _getFakeTimers().runAllTimers(),
      runOnlyPendingTimers: () => _getFakeTimers().runOnlyPendingTimers(),
      runTimersToTime: msToRun => _getFakeTimers().advanceTimersByTime(msToRun),
      setMock: (moduleName, mock) => setMockFactory(moduleName, () => mock),
      setSystemTime: now => {
        const fakeTimers = _getFakeTimers();

        if (fakeTimers instanceof _fakeTimers().ModernFakeTimers) {
          fakeTimers.setSystemTime(now);
        } else {
          throw new TypeError(
            'setSystemTime is not available when not using modern timers'
          );
        }
      },
      setTimeout,
      spyOn,
      unmock,
      useFakeTimers,
      useRealTimers
    };
    return jestObject;
  }

  _logFormattedReferenceError(errorMessage) {
    const originalStack = new ReferenceError(errorMessage).stack
      .split('\n') // Remove this file from the stack (jest-message-utils will keep one line)
      .filter(line => line.indexOf(__filename) === -1)
      .join('\n');
    const {message, stack} = (0, _jestMessageUtil().separateMessageFromStack)(
      originalStack
    );
    console.error(
      `\n${message}\n` +
        (0, _jestMessageUtil().formatStackTrace)(stack, this._config, {
          noStackTrace: false
        })
    );
  }

  wrapCodeInModuleWrapper(content) {
    return this.constructModuleWrapperStart() + content + '\n}});';
  }

  constructModuleWrapperStart() {
    const args = this.constructInjectedModuleParameters();
    return '({"' + EVAL_RESULT_VARIABLE + `":function(${args.join(',')}){`;
  }

  constructInjectedModuleParameters() {
    return [
      'module',
      'exports',
      'require',
      '__dirname',
      '__filename',
      'global',
      this._config.injectGlobals ? 'jest' : undefined,
      ...this._config.extraGlobals
    ].filter(notEmpty);
  }

  handleExecutionError(e, module) {
    const moduleNotFoundError = _jestResolve().default.tryCastModuleNotFoundError(
      e
    );

    if (moduleNotFoundError) {
      if (!moduleNotFoundError.requireStack) {
        moduleNotFoundError.requireStack = [module.filename || module.id];

        for (let cursor = module.parent; cursor; cursor = cursor.parent) {
          moduleNotFoundError.requireStack.push(cursor.filename || cursor.id);
        }

        moduleNotFoundError.buildMessage(this._config.rootDir);
      }

      throw moduleNotFoundError;
    }

    throw e;
  }

  getGlobalsForCjs(from) {
    const jest = this.jestObjectCaches.get(from);
    invariant(jest, 'There should always be a Jest object already');
    return {...this.getGlobalsFromEnvironment(), jest};
  }

  getGlobalsForEsm(from, context) {
    let jest = this.jestObjectCaches.get(from);

    if (!jest) {
      jest = this._createJestObjectFor(from);
      this.jestObjectCaches.set(from, jest);
    }

    const globals = {...this.getGlobalsFromEnvironment(), jest};
    const module = new (_vm().SyntheticModule)(
      Object.keys(globals),
      function () {
        Object.entries(globals).forEach(([key, value]) => {
          // @ts-expect-error: TS doesn't know what `this` is
          this.setExport(key, value);
        });
      },
      {
        context,
        identifier: '@jest/globals'
      }
    );
    return evaluateSyntheticModule(module);
  }

  getGlobalsFromEnvironment() {
    if (this.jestGlobals) {
      return {...this.jestGlobals};
    }

    return {
      afterAll: this._environment.global.afterAll,
      afterEach: this._environment.global.afterEach,
      beforeAll: this._environment.global.beforeAll,
      beforeEach: this._environment.global.beforeEach,
      describe: this._environment.global.describe,
      expect: this._environment.global.expect,
      fdescribe: this._environment.global.fdescribe,
      fit: this._environment.global.fit,
      it: this._environment.global.it,
      test: this._environment.global.test,
      xdescribe: this._environment.global.xdescribe,
      xit: this._environment.global.xit,
      xtest: this._environment.global.xtest
    };
  }

  readFile(filename) {
    let source = this._cacheFS.get(filename);

    if (!source) {
      source = fs().readFileSync(filename, 'utf8');

      this._cacheFS.set(filename, source);
    }

    return source;
  }

  setGlobalsForRuntime(globals) {
    this.jestGlobals = globals;
  }
}

_defineProperty(Runtime, 'shouldInstrument', _transform().shouldInstrument);

function invariant(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function notEmpty(value) {
  return value !== null && value !== undefined;
}

async function evaluateSyntheticModule(module) {
  await module.link(() => {
    throw new Error('This should never happen');
  });
  await module.evaluate();
  return module;
}

module.exports = Runtime;

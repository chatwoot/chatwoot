'use strict';

function path() {
  const data = _interopRequireWildcard(require('path'));

  path = function () {
    return data;
  };

  return data;
}

function _chalk() {
  const data = _interopRequireDefault(require('chalk'));

  _chalk = function () {
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

function _jestUtil() {
  const data = require('jest-util');

  _jestUtil = function () {
    return data;
  };

  return data;
}

var _ModuleNotFoundError = _interopRequireDefault(
  require('./ModuleNotFoundError')
);

var _defaultResolver = _interopRequireWildcard(require('./defaultResolver'));

var _isBuiltinModule = _interopRequireDefault(require('./isBuiltinModule'));

var _nodeModulesPaths = _interopRequireDefault(require('./nodeModulesPaths'));

var _shouldLoadAsEsm = _interopRequireWildcard(require('./shouldLoadAsEsm'));

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

const NATIVE_PLATFORM = 'native'; // We might be inside a symlink.

const resolvedCwd = (0, _jestUtil().tryRealpath)(process.cwd());
const {NODE_PATH} = process.env;
const nodePaths = NODE_PATH
  ? NODE_PATH.split(path().delimiter)
      .filter(Boolean) // The resolver expects absolute paths.
      .map(p => path().resolve(resolvedCwd, p))
  : undefined;

class Resolver {
  constructor(moduleMap, options) {
    _defineProperty(this, '_options', void 0);

    _defineProperty(this, '_moduleMap', void 0);

    _defineProperty(this, '_moduleIDCache', void 0);

    _defineProperty(this, '_moduleNameCache', void 0);

    _defineProperty(this, '_modulePathCache', void 0);

    _defineProperty(this, '_supportsNativePlatform', void 0);

    this._options = {
      defaultPlatform: options.defaultPlatform,
      extensions: options.extensions,
      hasCoreModules:
        options.hasCoreModules === undefined ? true : options.hasCoreModules,
      moduleDirectories: options.moduleDirectories || ['node_modules'],
      moduleNameMapper: options.moduleNameMapper,
      modulePaths: options.modulePaths,
      platforms: options.platforms,
      resolver: options.resolver,
      rootDir: options.rootDir
    };
    this._supportsNativePlatform = options.platforms
      ? options.platforms.includes(NATIVE_PLATFORM)
      : false;
    this._moduleMap = moduleMap;
    this._moduleIDCache = new Map();
    this._moduleNameCache = new Map();
    this._modulePathCache = new Map();
  }

  static tryCastModuleNotFoundError(error) {
    if (error instanceof _ModuleNotFoundError.default) {
      return error;
    }

    const casted = error;

    if (casted.code === 'MODULE_NOT_FOUND') {
      return _ModuleNotFoundError.default.duckType(casted);
    }

    return null;
  }

  static clearDefaultResolverCache() {
    (0, _defaultResolver.clearDefaultResolverCache)();
    (0, _shouldLoadAsEsm.clearCachedLookups)();
  }

  static findNodeModule(path, options) {
    const resolver = options.resolver
      ? require(options.resolver)
      : _defaultResolver.default;
    const paths = options.paths;

    try {
      return resolver(path, {
        basedir: options.basedir,
        browser: options.browser,
        defaultResolver: _defaultResolver.default,
        extensions: options.extensions,
        moduleDirectory: options.moduleDirectory,
        paths: paths ? (nodePaths || []).concat(paths) : nodePaths,
        rootDir: options.rootDir
      });
    } catch (e) {
      if (options.throwIfNotFound) {
        throw e;
      }
    }

    return null;
  } // unstable as it should be replaced by https://github.com/nodejs/modules/issues/393, and we don't want people to use it

  resolveModuleFromDirIfExists(dirname, moduleName, options) {
    const paths = (options && options.paths) || this._options.modulePaths;
    const moduleDirectory = this._options.moduleDirectories;
    const key = dirname + path().delimiter + moduleName;
    const defaultPlatform = this._options.defaultPlatform;

    const extensions = this._options.extensions.slice();

    let module;

    if (this._supportsNativePlatform) {
      extensions.unshift(
        ...this._options.extensions.map(ext => '.' + NATIVE_PLATFORM + ext)
      );
    }

    if (defaultPlatform) {
      extensions.unshift(
        ...this._options.extensions.map(ext => '.' + defaultPlatform + ext)
      );
    } // 1. If we have already resolved this module for this directory name,
    // return a value from the cache.

    const cacheResult = this._moduleNameCache.get(key);

    if (cacheResult) {
      return cacheResult;
    } // 2. Check if the module is a haste module.

    module = this.getModule(moduleName);

    if (module) {
      this._moduleNameCache.set(key, module);

      return module;
    } // 3. Check if the module is a node module and resolve it based on
    // the node module resolution algorithm. If skipNodeResolution is given we
    // ignore all modules that look like node modules (ie. are not relative
    // requires). This enables us to speed up resolution when we build a
    // dependency graph because we don't have to look at modules that may not
    // exist and aren't mocked.

    const skipResolution =
      options && options.skipNodeResolution && !moduleName.includes(path().sep);

    const resolveNodeModule = (name, throwIfNotFound = false) =>
      Resolver.findNodeModule(name, {
        basedir: dirname,
        extensions,
        moduleDirectory,
        paths,
        resolver: this._options.resolver,
        rootDir: this._options.rootDir,
        throwIfNotFound
      });

    if (!skipResolution) {
      module = resolveNodeModule(moduleName, Boolean(process.versions.pnp));

      if (module) {
        this._moduleNameCache.set(key, module);

        return module;
      }
    } // 4. Resolve "haste packages" which are `package.json` files outside of
    // `node_modules` folders anywhere in the file system.

    const parts = moduleName.split('/');
    const hastePackage = this.getPackage(parts.shift());

    if (hastePackage) {
      try {
        const module = path().join.apply(
          path(),
          [path().dirname(hastePackage)].concat(parts)
        ); // try resolving with custom resolver first to support extensions,
        // then fallback to require.resolve

        const resolvedModule =
          resolveNodeModule(module) || require.resolve(module);

        this._moduleNameCache.set(key, resolvedModule);

        return resolvedModule;
      } catch {}
    }

    return null;
  }

  resolveModule(from, moduleName, options) {
    const dirname = path().dirname(from);
    const module =
      this.resolveStubModuleName(from, moduleName) ||
      this.resolveModuleFromDirIfExists(dirname, moduleName, options);
    if (module) return module; // 5. Throw an error if the module could not be found. `resolve.sync` only
    // produces an error based on the dirname but we have the actual current
    // module name available.

    const relativePath =
      (0, _slash().default)(path().relative(this._options.rootDir, from)) ||
      '.';
    throw new _ModuleNotFoundError.default(
      `Cannot find module '${moduleName}' from '${relativePath}'`,
      moduleName
    );
  }

  _isAliasModule(moduleName) {
    const moduleNameMapper = this._options.moduleNameMapper;

    if (!moduleNameMapper) {
      return false;
    }

    return moduleNameMapper.some(({regex}) => regex.test(moduleName));
  }

  isCoreModule(moduleName) {
    return (
      this._options.hasCoreModules &&
      (0, _isBuiltinModule.default)(moduleName) &&
      !this._isAliasModule(moduleName)
    );
  }

  getModule(name) {
    return this._moduleMap.getModule(
      name,
      this._options.defaultPlatform,
      this._supportsNativePlatform
    );
  }

  getModulePath(from, moduleName) {
    if (moduleName[0] !== '.' || path().isAbsolute(moduleName)) {
      return moduleName;
    }

    return path().normalize(path().dirname(from) + '/' + moduleName);
  }

  getPackage(name) {
    return this._moduleMap.getPackage(
      name,
      this._options.defaultPlatform,
      this._supportsNativePlatform
    );
  }

  getMockModule(from, name) {
    const mock = this._moduleMap.getMockModule(name);

    if (mock) {
      return mock;
    } else {
      const moduleName = this.resolveStubModuleName(from, name);

      if (moduleName) {
        return this.getModule(moduleName) || moduleName;
      }
    }

    return null;
  }

  getModulePaths(from) {
    const cachedModule = this._modulePathCache.get(from);

    if (cachedModule) {
      return cachedModule;
    }

    const moduleDirectory = this._options.moduleDirectories;
    const paths = (0, _nodeModulesPaths.default)(from, {
      moduleDirectory
    });

    if (paths[paths.length - 1] === undefined) {
      // circumvent node-resolve bug that adds `undefined` as last item.
      paths.pop();
    }

    this._modulePathCache.set(from, paths);

    return paths;
  }

  getModuleID(virtualMocks, from, _moduleName) {
    const moduleName = _moduleName || '';
    const key = from + path().delimiter + moduleName;

    const cachedModuleID = this._moduleIDCache.get(key);

    if (cachedModuleID) {
      return cachedModuleID;
    }

    const moduleType = this._getModuleType(moduleName);

    const absolutePath = this._getAbsolutePath(virtualMocks, from, moduleName);

    const mockPath = this._getMockPath(from, moduleName);

    const sep = path().delimiter;
    const id =
      moduleType +
      sep +
      (absolutePath ? absolutePath + sep : '') +
      (mockPath ? mockPath + sep : '');

    this._moduleIDCache.set(key, id);

    return id;
  }

  _getModuleType(moduleName) {
    return this.isCoreModule(moduleName) ? 'node' : 'user';
  }

  _getAbsolutePath(virtualMocks, from, moduleName) {
    if (this.isCoreModule(moduleName)) {
      return moduleName;
    }

    return this._isModuleResolved(from, moduleName)
      ? this.getModule(moduleName)
      : this._getVirtualMockPath(virtualMocks, from, moduleName);
  }

  _getMockPath(from, moduleName) {
    return !this.isCoreModule(moduleName)
      ? this.getMockModule(from, moduleName)
      : null;
  }

  _getVirtualMockPath(virtualMocks, from, moduleName) {
    const virtualMockPath = this.getModulePath(from, moduleName);
    return virtualMocks[virtualMockPath]
      ? virtualMockPath
      : moduleName
      ? this.resolveModule(from, moduleName)
      : from;
  }

  _isModuleResolved(from, moduleName) {
    return !!(
      this.getModule(moduleName) || this.getMockModule(from, moduleName)
    );
  }

  resolveStubModuleName(from, moduleName) {
    const dirname = path().dirname(from);
    const paths = this._options.modulePaths;

    const extensions = this._options.extensions.slice();

    const moduleDirectory = this._options.moduleDirectories;
    const moduleNameMapper = this._options.moduleNameMapper;
    const resolver = this._options.resolver;
    const defaultPlatform = this._options.defaultPlatform;

    if (this._supportsNativePlatform) {
      extensions.unshift(
        ...this._options.extensions.map(ext => '.' + NATIVE_PLATFORM + ext)
      );
    }

    if (defaultPlatform) {
      extensions.unshift(
        ...this._options.extensions.map(ext => '.' + defaultPlatform + ext)
      );
    }

    if (moduleNameMapper) {
      for (const {moduleName: mappedModuleName, regex} of moduleNameMapper) {
        if (regex.test(moduleName)) {
          // Note: once a moduleNameMapper matches the name, it must result
          // in a module, or else an error is thrown.
          const matches = moduleName.match(regex);
          const mapModuleName = matches
            ? moduleName =>
                moduleName.replace(
                  /\$([0-9]+)/g,
                  (_, index) => matches[parseInt(index, 10)]
                )
            : moduleName => moduleName;
          const possibleModuleNames = Array.isArray(mappedModuleName)
            ? mappedModuleName
            : [mappedModuleName];
          let module = null;

          for (const possibleModuleName of possibleModuleNames) {
            const updatedName = mapModuleName(possibleModuleName);
            module =
              this.getModule(updatedName) ||
              Resolver.findNodeModule(updatedName, {
                basedir: dirname,
                extensions,
                moduleDirectory,
                paths,
                resolver,
                rootDir: this._options.rootDir
              });

            if (module) {
              break;
            }
          }

          if (!module) {
            throw createNoMappedModuleFoundError(
              moduleName,
              mapModuleName,
              mappedModuleName,
              regex,
              resolver
            );
          }

          return module;
        }
      }
    }

    return null;
  }
}

_defineProperty(Resolver, 'ModuleNotFoundError', _ModuleNotFoundError.default);

_defineProperty(Resolver, 'unstable_shouldLoadAsEsm', _shouldLoadAsEsm.default);

const createNoMappedModuleFoundError = (
  moduleName,
  mapModuleName,
  mappedModuleName,
  regex,
  resolver
) => {
  const mappedAs = Array.isArray(mappedModuleName)
    ? JSON.stringify(mappedModuleName.map(mapModuleName), null, 2)
    : mappedModuleName;
  const original = Array.isArray(mappedModuleName)
    ? JSON.stringify(mappedModuleName, null, 6) // using 6 because of misalignment when nested below
        .slice(0, -1) + '    ]' /// align last bracket correctly as well
    : mappedModuleName;
  const error = new Error(
    _chalk().default.red(`${_chalk().default.bold('Configuration error')}:

Could not locate module ${_chalk().default.bold(moduleName)} mapped as:
${_chalk().default.bold(mappedAs)}.

Please check your configuration for these entries:
{
  "moduleNameMapper": {
    "${regex.toString()}": "${_chalk().default.bold(original)}"
  },
  "resolver": ${_chalk().default.bold(String(resolver))}
}`)
  );
  error.name = '';
  return error;
};

module.exports = Resolver;

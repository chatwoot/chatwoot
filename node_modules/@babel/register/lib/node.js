"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.revert = revert;
exports.default = register;

var registerCache = _interopRequireWildcard(require("./cache"));

var babel = _interopRequireWildcard(require("@babel/core"));

var _pirates = require("pirates");

function _getRequireWildcardCache() { if (typeof WeakMap !== "function") return null; var cache = new WeakMap(); _getRequireWildcardCache = function () { return cache; }; return cache; }

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } if (obj === null || typeof obj !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

const cloneDeep = require("clone-deep");

const sourceMapSupport = require("source-map-support");

const fs = require("fs");

const path = require("path");

const Module = require("module");

const maps = {};
let transformOpts = {};
let piratesRevert = null;

function installSourceMapSupport() {
  sourceMapSupport.install({
    handleUncaughtExceptions: false,
    environment: "node",

    retrieveSourceMap(source) {
      const map = maps && maps[source];

      if (map) {
        return {
          url: null,
          map: map
        };
      } else {
        return null;
      }
    }

  });
}

let cache;

function mtime(filename) {
  return +fs.statSync(filename).mtime;
}

function compile(code, filename) {
  const opts = new babel.OptionManager().init(Object.assign({
    sourceRoot: path.dirname(filename) + path.sep
  }, cloneDeep(transformOpts), {
    filename
  }));
  if (opts === null) return code;
  let cacheKey = `${JSON.stringify(opts)}:${babel.version}`;
  const env = babel.getEnv(false);
  if (env) cacheKey += `:${env}`;
  let cached = cache && cache[cacheKey];

  if (!cached || cached.mtime !== mtime(filename)) {
    cached = babel.transform(code, Object.assign({}, opts, {
      sourceMaps: opts.sourceMaps === undefined ? "both" : opts.sourceMaps,
      ast: false
    }));

    if (cache) {
      cache[cacheKey] = cached;
      cached.mtime = mtime(filename);
      registerCache.setDirty();
    }
  }

  if (cached.map) {
    if (Object.keys(maps).length === 0) {
      installSourceMapSupport();
    }

    maps[filename] = cached.map;
  }

  return cached.code;
}

let compiling = false;
const internalModuleCache = Module._cache;

function compileHook(code, filename) {
  if (compiling) return code;
  const globalModuleCache = Module._cache;

  try {
    compiling = true;
    Module._cache = internalModuleCache;
    return compile(code, filename);
  } finally {
    compiling = false;
    Module._cache = globalModuleCache;
  }
}

function hookExtensions(exts) {
  if (piratesRevert) piratesRevert();
  piratesRevert = (0, _pirates.addHook)(compileHook, {
    exts,
    ignoreNodeModules: false
  });
}

function revert() {
  if (piratesRevert) piratesRevert();
}

function escapeRegExp(string) {
  return string.replace(/[|\\{}()[\]^$+*?.]/g, "\\$&");
}

function register(opts = {}) {
  opts = Object.assign({}, opts);
  hookExtensions(opts.extensions || babel.DEFAULT_EXTENSIONS);

  if (opts.cache === false && cache) {
    registerCache.clear();
    cache = null;
  } else if (opts.cache !== false && !cache) {
    registerCache.load();
    cache = registerCache.get();
  }

  delete opts.extensions;
  delete opts.cache;
  transformOpts = Object.assign({}, opts, {
    caller: Object.assign({
      name: "@babel/register"
    }, opts.caller || {})
  });
  let {
    cwd = "."
  } = transformOpts;
  cwd = transformOpts.cwd = path.resolve(cwd);

  if (transformOpts.ignore === undefined && transformOpts.only === undefined) {
    transformOpts.only = [new RegExp("^" + escapeRegExp(cwd), "i")];
    transformOpts.ignore = [new RegExp("^" + escapeRegExp(cwd) + "(?:" + path.sep + ".*)?" + escapeRegExp(path.sep + "node_modules" + path.sep), "i")];
  }
}
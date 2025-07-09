'use strict';

var node_module = require('node:module');
var path = require('node:path');
var node_url = require('node:url');
var vm = require('node:vm');
var pathe = require('pathe');
var createDebug = require('debug');
var utils = require('./utils.cjs');
var sourceMap = require('./source-map.cjs');
require('node:fs');

const { setTimeout, clearTimeout } = globalThis;
const debugExecute = createDebug("vite-node:client:execute");
const debugNative = createDebug("vite-node:client:native");
const clientStub = {
  injectQuery: (id) => id,
  createHotContext: () => {
    return {
      accept: () => {
      },
      prune: () => {
      },
      dispose: () => {
      },
      decline: () => {
      },
      invalidate: () => {
      },
      on: () => {
      },
      send: () => {
      }
    };
  },
  updateStyle: () => {
  },
  removeStyle: () => {
  }
};
const env = utils.createImportMetaEnvProxy();
const DEFAULT_REQUEST_STUBS = {
  "/@vite/client": clientStub,
  "@vite/client": clientStub
};
class ModuleCacheMap extends Map {
  normalizePath(fsPath) {
    return utils.normalizeModuleId(fsPath);
  }
  /**
   * Assign partial data to the map
   */
  update(fsPath, mod) {
    fsPath = this.normalizePath(fsPath);
    if (!super.has(fsPath)) {
      this.setByModuleId(fsPath, mod);
    } else {
      Object.assign(super.get(fsPath), mod);
    }
    return this;
  }
  setByModuleId(modulePath, mod) {
    return super.set(modulePath, mod);
  }
  set(fsPath, mod) {
    return this.setByModuleId(this.normalizePath(fsPath), mod);
  }
  getByModuleId(modulePath) {
    if (!super.has(modulePath)) {
      this.setByModuleId(modulePath, {});
    }
    const mod = super.get(modulePath);
    if (!mod.imports) {
      Object.assign(mod, {
        imports: /* @__PURE__ */ new Set(),
        importers: /* @__PURE__ */ new Set()
      });
    }
    return mod;
  }
  get(fsPath) {
    return this.getByModuleId(this.normalizePath(fsPath));
  }
  deleteByModuleId(modulePath) {
    return super.delete(modulePath);
  }
  delete(fsPath) {
    return this.deleteByModuleId(this.normalizePath(fsPath));
  }
  invalidateModule(mod) {
    var _a, _b;
    delete mod.evaluated;
    delete mod.resolving;
    delete mod.promise;
    delete mod.exports;
    (_a = mod.importers) == null ? void 0 : _a.clear();
    (_b = mod.imports) == null ? void 0 : _b.clear();
    return true;
  }
  /**
   * Invalidate modules that dependent on the given modules, up to the main entry
   */
  invalidateDepTree(ids, invalidated = /* @__PURE__ */ new Set()) {
    for (const _id of ids) {
      const id = this.normalizePath(_id);
      if (invalidated.has(id)) {
        continue;
      }
      invalidated.add(id);
      const mod = super.get(id);
      if (mod == null ? void 0 : mod.importers) {
        this.invalidateDepTree(mod.importers, invalidated);
      }
      super.delete(id);
    }
    return invalidated;
  }
  /**
   * Invalidate dependency modules of the given modules, down to the bottom-level dependencies
   */
  invalidateSubDepTree(ids, invalidated = /* @__PURE__ */ new Set()) {
    for (const _id of ids) {
      const id = this.normalizePath(_id);
      if (invalidated.has(id)) {
        continue;
      }
      invalidated.add(id);
      const subIds = Array.from(super.entries()).filter(([, mod]) => {
        var _a;
        return (_a = mod.importers) == null ? void 0 : _a.has(id);
      }).map(([key]) => key);
      subIds.length && this.invalidateSubDepTree(subIds, invalidated);
      super.delete(id);
    }
    return invalidated;
  }
  /**
   * Return parsed source map based on inlined source map of the module
   */
  getSourceMap(id) {
    const cache = this.get(id);
    if (cache.map) {
      return cache.map;
    }
    const map = cache.code && sourceMap.extractSourceMap(cache.code);
    if (map) {
      cache.map = map;
      return map;
    }
    return null;
  }
}
class ViteNodeRunner {
  constructor(options) {
    this.options = options;
    this.root = options.root ?? process.cwd();
    this.moduleCache = options.moduleCache ?? new ModuleCacheMap();
    this.debug = options.debug ?? (typeof process !== "undefined" ? !!process.env.VITE_NODE_DEBUG_RUNNER : false);
  }
  root;
  debug;
  /**
   * Holds the cache of modules
   * Keys of the map are filepaths, or plain package names
   */
  moduleCache;
  async executeFile(file) {
    const url = `/@fs/${utils.slash(pathe.resolve(file))}`;
    return await this.cachedRequest(url, url, []);
  }
  async executeId(rawId) {
    const [id, url] = await this.resolveUrl(rawId);
    return await this.cachedRequest(id, url, []);
  }
  /** @internal */
  async cachedRequest(id, fsPath, callstack) {
    const importee = callstack[callstack.length - 1];
    const mod = this.moduleCache.get(fsPath);
    const { imports, importers } = mod;
    if (importee) {
      importers.add(importee);
    }
    const getStack = () => `stack:
${[...callstack, fsPath].reverse().map((p) => `  - ${p}`).join("\n")}`;
    if (callstack.includes(fsPath) || Array.from(imports.values()).some((i) => importers.has(i))) {
      if (mod.exports) {
        return mod.exports;
      }
    }
    let debugTimer;
    if (this.debug) {
      debugTimer = setTimeout(
        () => console.warn(
          `[vite-node] module ${fsPath} takes over 2s to load.
${getStack()}`
        ),
        2e3
      );
    }
    try {
      if (mod.promise) {
        return await mod.promise;
      }
      const promise = this.directRequest(id, fsPath, callstack);
      Object.assign(mod, { promise, evaluated: false });
      return await promise;
    } finally {
      mod.evaluated = true;
      if (debugTimer) {
        clearTimeout(debugTimer);
      }
    }
  }
  shouldResolveId(id, _importee) {
    return !utils.isInternalRequest(id) && !utils.isNodeBuiltin(id) && !id.startsWith("data:");
  }
  async _resolveUrl(id, importer) {
    var _a, _b;
    const dep = utils.normalizeRequestId(id, this.options.base);
    if (!this.shouldResolveId(dep)) {
      return [dep, dep];
    }
    const { path, exists } = utils.toFilePath(dep, this.root);
    if (!this.options.resolveId || exists) {
      return [dep, path];
    }
    const resolved = await this.options.resolveId(dep, importer);
    if ((_b = (_a = resolved == null ? void 0 : resolved.meta) == null ? void 0 : _a["vite:alias"]) == null ? void 0 : _b.noResolved) {
      const error = new Error(
        `Cannot find module '${id}'${importer ? ` imported from '${importer}'` : ""}.

- If you rely on tsconfig.json's "paths" to resolve modules, please install "vite-tsconfig-paths" plugin to handle module resolution.
- Make sure you don't have relative aliases in your Vitest config. Use absolute paths instead. Read more: https://vitest.dev/guide/common-errors`
      );
      Object.defineProperty(error, "code", {
        value: "ERR_MODULE_NOT_FOUND",
        enumerable: true
      });
      Object.defineProperty(error, Symbol.for("vitest.error.not_found.data"), {
        value: { id: dep, importer },
        enumerable: false
      });
      throw error;
    }
    const resolvedId = resolved ? utils.normalizeRequestId(resolved.id, this.options.base) : dep;
    return [resolvedId, resolvedId];
  }
  async resolveUrl(id, importee) {
    const resolveKey = `resolve:${id}`;
    this.moduleCache.setByModuleId(resolveKey, { resolving: true });
    try {
      return await this._resolveUrl(id, importee);
    } finally {
      this.moduleCache.deleteByModuleId(resolveKey);
    }
  }
  /** @internal */
  async dependencyRequest(id, fsPath, callstack) {
    return await this.cachedRequest(id, fsPath, callstack);
  }
  /** @internal */
  async directRequest(id, fsPath, _callstack) {
    const moduleId = utils.normalizeModuleId(fsPath);
    const callstack = [..._callstack, moduleId];
    const mod = this.moduleCache.getByModuleId(moduleId);
    const request = async (dep) => {
      const [id2, depFsPath] = await this.resolveUrl(String(dep), fsPath);
      const depMod = this.moduleCache.getByModuleId(depFsPath);
      depMod.importers.add(moduleId);
      mod.imports.add(depFsPath);
      return this.dependencyRequest(id2, depFsPath, callstack);
    };
    const requestStubs = this.options.requestStubs || DEFAULT_REQUEST_STUBS;
    if (id in requestStubs) {
      return requestStubs[id];
    }
    let { code: transformed, externalize } = await this.options.fetchModule(id);
    if (externalize) {
      debugNative(externalize);
      const exports2 = await this.interopedImport(externalize);
      mod.exports = exports2;
      return exports2;
    }
    if (transformed == null) {
      throw new Error(
        `[vite-node] Failed to load "${id}" imported from ${callstack[callstack.length - 2]}`
      );
    }
    const { Object: Object2, Reflect: Reflect2, Symbol: Symbol2 } = this.getContextPrimitives();
    const modulePath = utils.cleanUrl(moduleId);
    const href = node_url.pathToFileURL(modulePath).href;
    const __filename = node_url.fileURLToPath(href);
    const __dirname = path.dirname(__filename);
    const meta = {
      url: href,
      env,
      filename: __filename,
      dirname: __dirname
    };
    const exports = Object2.create(null);
    Object2.defineProperty(exports, Symbol2.toStringTag, {
      value: "Module",
      enumerable: false,
      configurable: false
    });
    const SYMBOL_NOT_DEFINED = Symbol2("not defined");
    let moduleExports = SYMBOL_NOT_DEFINED;
    const cjsExports = new Proxy(exports, {
      get: (target, p, receiver) => {
        if (Reflect2.has(target, p)) {
          return Reflect2.get(target, p, receiver);
        }
        return Reflect2.get(Object2.prototype, p, receiver);
      },
      getPrototypeOf: () => Object2.prototype,
      set: (_, p, value) => {
        if (p === "default" && this.shouldInterop(modulePath, { default: value }) && cjsExports !== value) {
          exportAll(cjsExports, value);
          exports.default = value;
          return true;
        }
        if (!Reflect2.has(exports, "default")) {
          exports.default = {};
        }
        if (moduleExports !== SYMBOL_NOT_DEFINED && utils.isPrimitive(moduleExports)) {
          defineExport(exports, p, () => void 0);
          return true;
        }
        if (!utils.isPrimitive(exports.default)) {
          exports.default[p] = value;
        }
        if (p !== "default") {
          defineExport(exports, p, () => value);
        }
        return true;
      }
    });
    Object2.assign(mod, { code: transformed, exports });
    const moduleProxy = {
      set exports(value) {
        exportAll(cjsExports, value);
        exports.default = value;
        moduleExports = value;
      },
      get exports() {
        return cjsExports;
      }
    };
    let hotContext;
    if (this.options.createHotContext) {
      Object2.defineProperty(meta, "hot", {
        enumerable: true,
        get: () => {
          var _a, _b;
          hotContext || (hotContext = (_b = (_a = this.options).createHotContext) == null ? void 0 : _b.call(_a, this, moduleId));
          return hotContext;
        },
        set: (value) => {
          hotContext = value;
        }
      });
    }
    const context = this.prepareContext({
      // esm transformed by Vite
      __vite_ssr_import__: request,
      __vite_ssr_dynamic_import__: request,
      __vite_ssr_exports__: exports,
      __vite_ssr_exportAll__: (obj) => exportAll(exports, obj),
      __vite_ssr_import_meta__: meta,
      // cjs compact
      require: node_module.createRequire(href),
      exports: cjsExports,
      module: moduleProxy,
      __filename,
      __dirname
    });
    debugExecute(__filename);
    if (transformed[0] === "#") {
      transformed = transformed.replace(/^#!.*/, (s) => " ".repeat(s.length));
    }
    await this.runModule(context, transformed);
    return exports;
  }
  getContextPrimitives() {
    return { Object, Reflect, Symbol };
  }
  async runModule(context, transformed) {
    const codeDefinition = `'use strict';async (${Object.keys(context).join(
      ","
    )})=>{{`;
    const code = `${codeDefinition}${transformed}
}}`;
    const options = {
      filename: context.__filename,
      lineOffset: 0,
      columnOffset: -codeDefinition.length
    };
    const fn = vm.runInThisContext(code, options);
    await fn(...Object.values(context));
  }
  prepareContext(context) {
    return context;
  }
  /**
   * Define if a module should be interop-ed
   * This function mostly for the ability to override by subclass
   */
  shouldInterop(path, mod) {
    if (this.options.interopDefault === false) {
      return false;
    }
    return !path.endsWith(".mjs") && "default" in mod;
  }
  importExternalModule(path) {
    return import(path);
  }
  /**
   * Import a module and interop it
   */
  async interopedImport(path) {
    const importedModule = await this.importExternalModule(path);
    if (!this.shouldInterop(path, importedModule)) {
      return importedModule;
    }
    const { mod, defaultExport } = interopModule(importedModule);
    return new Proxy(mod, {
      get(mod2, prop) {
        if (prop === "default") {
          return defaultExport;
        }
        return mod2[prop] ?? (defaultExport == null ? void 0 : defaultExport[prop]);
      },
      has(mod2, prop) {
        if (prop === "default") {
          return defaultExport !== void 0;
        }
        return prop in mod2 || defaultExport && prop in defaultExport;
      },
      getOwnPropertyDescriptor(mod2, prop) {
        const descriptor = Reflect.getOwnPropertyDescriptor(mod2, prop);
        if (descriptor) {
          return descriptor;
        }
        if (prop === "default" && defaultExport !== void 0) {
          return {
            value: defaultExport,
            enumerable: true,
            configurable: true
          };
        }
      }
    });
  }
}
function interopModule(mod) {
  if (utils.isPrimitive(mod)) {
    return {
      mod: { default: mod },
      defaultExport: mod
    };
  }
  let defaultExport = "default" in mod ? mod.default : mod;
  if (!utils.isPrimitive(defaultExport) && "__esModule" in defaultExport) {
    mod = defaultExport;
    if ("default" in defaultExport) {
      defaultExport = defaultExport.default;
    }
  }
  return { mod, defaultExport };
}
function defineExport(exports, key, value) {
  Object.defineProperty(exports, key, {
    enumerable: true,
    configurable: true,
    get: value
  });
}
function exportAll(exports, sourceModule) {
  if (exports === sourceModule) {
    return;
  }
  if (utils.isPrimitive(sourceModule) || Array.isArray(sourceModule) || sourceModule instanceof Promise) {
    return;
  }
  for (const key in sourceModule) {
    if (key !== "default") {
      try {
        defineExport(exports, key, () => sourceModule[key]);
      } catch (_err) {
      }
    }
  }
}

exports.DEFAULT_REQUEST_STUBS = DEFAULT_REQUEST_STUBS;
exports.ModuleCacheMap = ModuleCacheMap;
exports.ViteNodeRunner = ViteNodeRunner;

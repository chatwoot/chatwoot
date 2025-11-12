'use strict';

var node_perf_hooks = require('node:perf_hooks');
var fs = require('node:fs');
var assert = require('node:assert');
var pathe = require('pathe');
var createDebug = require('debug');
var utils = require('./utils.cjs');
var constants = require('./constants.cjs');
var c = require('picocolors');
var sourceMap = require('./source-map.cjs');
require('node:url');
require('node:module');
require('node:path');

const BUILTIN_EXTENSIONS = /* @__PURE__ */ new Set([".mjs", ".cjs", ".node", ".wasm"]);
const ESM_SYNTAX_RE = /(?:[\s;]|^)(?:import[\s\w*,{}]*from|import\s*["'*{]|export\b\s*(?:[*{]|default|class|type|function|const|var|let|async function)|import\.meta\b)/m;
const ESM_EXT_RE = /\.(es|esm|esm-browser|esm-bundler|es6|module)\.js$/;
const ESM_FOLDER_RE = /\/(es|esm)\/(.*\.js)$/;
const defaultInline = [
  /virtual:/,
  /\.[mc]?ts$/,
  // special Vite query strings
  /[?&](init|raw|url|inline)\b/,
  // Vite returns a string for assets imports, even if it's inside "node_modules"
  constants.KNOWN_ASSET_RE
];
const depsExternal = [
  /\/node_modules\/.*\.cjs\.js$/,
  /\/node_modules\/.*\.mjs$/
];
function guessCJSversion(id) {
  if (id.match(ESM_EXT_RE)) {
    for (const i of [
      id.replace(ESM_EXT_RE, ".mjs"),
      id.replace(ESM_EXT_RE, ".umd.js"),
      id.replace(ESM_EXT_RE, ".cjs.js"),
      id.replace(ESM_EXT_RE, ".js")
    ]) {
      if (fs.existsSync(i)) {
        return i;
      }
    }
  }
  if (id.match(ESM_FOLDER_RE)) {
    for (const i of [
      id.replace(ESM_FOLDER_RE, "/umd/$1"),
      id.replace(ESM_FOLDER_RE, "/cjs/$1"),
      id.replace(ESM_FOLDER_RE, "/lib/$1"),
      id.replace(ESM_FOLDER_RE, "/$1")
    ]) {
      if (fs.existsSync(i)) {
        return i;
      }
    }
  }
}
async function isValidNodeImport(id) {
  const extension = pathe.extname(id);
  if (BUILTIN_EXTENSIONS.has(extension)) {
    return true;
  }
  if (extension !== ".js") {
    return false;
  }
  id = id.replace("file:///", "");
  const package_ = await utils.findNearestPackageData(pathe.dirname(id));
  if (package_.type === "module") {
    return true;
  }
  if (/\.(?:\w+-)?esm?(?:-\w+)?\.js$|\/esm?\//.test(id)) {
    return false;
  }
  const code = await fs.promises.readFile(id, "utf8").catch(() => "");
  return !ESM_SYNTAX_RE.test(code);
}
const _defaultExternalizeCache = /* @__PURE__ */ new Map();
async function shouldExternalize(id, options, cache = _defaultExternalizeCache) {
  if (!cache.has(id)) {
    cache.set(id, _shouldExternalize(id, options));
  }
  return cache.get(id);
}
async function _shouldExternalize(id, options) {
  if (utils.isNodeBuiltin(id)) {
    return id;
  }
  if (id.startsWith("data:") || /^(?:https?:)?\/\//.test(id)) {
    return id;
  }
  id = patchWindowsImportPath(id);
  if ((options == null ? void 0 : options.cacheDir) && id.includes(options.cacheDir)) {
    return id;
  }
  const moduleDirectories = (options == null ? void 0 : options.moduleDirectories) || ["/node_modules/"];
  if (matchExternalizePattern(id, moduleDirectories, options == null ? void 0 : options.inline)) {
    return false;
  }
  if (matchExternalizePattern(id, moduleDirectories, options == null ? void 0 : options.external)) {
    return id;
  }
  const isLibraryModule = moduleDirectories.some((dir) => id.includes(dir));
  const guessCJS = isLibraryModule && (options == null ? void 0 : options.fallbackCJS);
  id = guessCJS ? guessCJSversion(id) || id : id;
  if (matchExternalizePattern(id, moduleDirectories, defaultInline)) {
    return false;
  }
  if (matchExternalizePattern(id, moduleDirectories, depsExternal)) {
    return id;
  }
  if (isLibraryModule && await isValidNodeImport(id)) {
    return id;
  }
  return false;
}
function matchExternalizePattern(id, moduleDirectories, patterns) {
  if (patterns == null) {
    return false;
  }
  if (patterns === true) {
    return true;
  }
  for (const ex of patterns) {
    if (typeof ex === "string") {
      if (moduleDirectories.some((dir) => id.includes(pathe.join(dir, ex)))) {
        return true;
      }
    } else {
      if (ex.test(id)) {
        return true;
      }
    }
  }
  return false;
}
function patchWindowsImportPath(path) {
  if (path.match(/^\w:\\/)) {
    return `file:///${utils.slash(path)}`;
  } else if (path.match(/^\w:\//)) {
    return `file:///${path}`;
  } else {
    return path;
  }
}

function hashCode(s) {
  return s.split("").reduce((a, b) => {
    a = (a << 5) - a + b.charCodeAt(0);
    return a & a;
  }, 0);
}
class Debugger {
  constructor(root, options) {
    this.options = options;
    if (options.dumpModules) {
      this.dumpDir = pathe.resolve(
        root,
        options.dumpModules === true ? ".vite-node/dump" : options.dumpModules
      );
    }
    if (this.dumpDir) {
      if (options.loadDumppedModules) {
        console.info(
          c.gray(`[vite-node] [debug] load modules from ${this.dumpDir}`)
        );
      } else {
        console.info(
          c.gray(`[vite-node] [debug] dump modules to ${this.dumpDir}`)
        );
      }
    }
    this.initPromise = this.clearDump();
  }
  dumpDir;
  initPromise;
  externalizeMap = /* @__PURE__ */ new Map();
  async clearDump() {
    if (!this.dumpDir) {
      return;
    }
    if (!this.options.loadDumppedModules && fs.existsSync(this.dumpDir)) {
      await fs.promises.rm(this.dumpDir, { recursive: true, force: true });
    }
    await fs.promises.mkdir(this.dumpDir, { recursive: true });
  }
  encodeId(id) {
    return `${id.replace(/[^\w@\-]/g, "_").replace(/_+/g, "_")}-${hashCode(
      id
    )}.js`;
  }
  async recordExternalize(id, path) {
    if (!this.dumpDir) {
      return;
    }
    this.externalizeMap.set(id, path);
    await this.writeInfo();
  }
  async dumpFile(id, result) {
    if (!result || !this.dumpDir) {
      return;
    }
    await this.initPromise;
    const name = this.encodeId(id);
    return await fs.promises.writeFile(
      pathe.join(this.dumpDir, name),
      `// ${id.replace(/\0/g, "\\0")}
${result.code}`,
      "utf-8"
    );
  }
  async loadDump(id) {
    if (!this.dumpDir) {
      return null;
    }
    await this.initPromise;
    const name = this.encodeId(id);
    const path = pathe.join(this.dumpDir, name);
    if (!fs.existsSync(path)) {
      return null;
    }
    const code = await fs.promises.readFile(path, "utf-8");
    return {
      code: code.replace(/^\/\/.*\n/, ""),
      map: void 0
    };
  }
  async writeInfo() {
    if (!this.dumpDir) {
      return;
    }
    const info = JSON.stringify(
      {
        time: (/* @__PURE__ */ new Date()).toLocaleString(),
        externalize: Object.fromEntries(this.externalizeMap.entries())
      },
      null,
      2
    );
    return fs.promises.writeFile(pathe.join(this.dumpDir, "info.json"), info, "utf-8");
  }
}

const debugRequest = createDebug("vite-node:server:request");
class ViteNodeServer {
  constructor(server, options = {}) {
    this.server = server;
    this.options = options;
    var _a, _b, _c;
    const ssrOptions = server.config.ssr;
    options.deps ?? (options.deps = {});
    options.deps.cacheDir = pathe.relative(
      server.config.root,
      options.deps.cacheDir || server.config.cacheDir
    );
    if (ssrOptions) {
      if (ssrOptions.noExternal === true) {
        (_a = options.deps).inline ?? (_a.inline = true);
      } else if (options.deps.inline !== true) {
        (_b = options.deps).inline ?? (_b.inline = []);
        const inline = options.deps.inline;
        options.deps.inline.push(
          ...utils.toArray(ssrOptions.noExternal).filter(
            (dep) => !inline.includes(dep)
          )
        );
      }
    }
    if (process.env.VITE_NODE_DEBUG_DUMP) {
      options.debug = Object.assign(
        {
          dumpModules: !!process.env.VITE_NODE_DEBUG_DUMP,
          loadDumppedModules: process.env.VITE_NODE_DEBUG_DUMP === "load"
        },
        options.debug ?? {}
      );
    }
    if (options.debug) {
      this.debugger = new Debugger(server.config.root, options.debug);
    }
    (_c = options.deps).moduleDirectories ?? (_c.moduleDirectories = []);
    const envValue = process.env.VITE_NODE_DEPS_MODULE_DIRECTORIES || process.env.npm_config_VITE_NODE_DEPS_MODULE_DIRECTORIES;
    const customModuleDirectories = envValue == null ? void 0 : envValue.split(",");
    if (customModuleDirectories) {
      options.deps.moduleDirectories.push(...customModuleDirectories);
    }
    options.deps.moduleDirectories = options.deps.moduleDirectories.map(
      (dir) => {
        if (!dir.startsWith("/")) {
          dir = `/${dir}`;
        }
        if (!dir.endsWith("/")) {
          dir += "/";
        }
        return pathe.normalize(dir);
      }
    );
    if (!options.deps.moduleDirectories.includes("/node_modules/")) {
      options.deps.moduleDirectories.push("/node_modules/");
    }
  }
  fetchPromiseMap = {
    ssr: /* @__PURE__ */ new Map(),
    web: /* @__PURE__ */ new Map()
  };
  transformPromiseMap = {
    ssr: /* @__PURE__ */ new Map(),
    web: /* @__PURE__ */ new Map()
  };
  durations = {
    ssr: /* @__PURE__ */ new Map(),
    web: /* @__PURE__ */ new Map()
  };
  existingOptimizedDeps = /* @__PURE__ */ new Set();
  fetchCaches = {
    ssr: /* @__PURE__ */ new Map(),
    web: /* @__PURE__ */ new Map()
  };
  fetchCache = /* @__PURE__ */ new Map();
  externalizeCache = /* @__PURE__ */ new Map();
  debugger;
  shouldExternalize(id) {
    return shouldExternalize(id, this.options.deps, this.externalizeCache);
  }
  getTotalDuration() {
    const ssrDurations = [...this.durations.ssr.values()].flat();
    const webDurations = [...this.durations.web.values()].flat();
    return [...ssrDurations, ...webDurations].reduce((a, b) => a + b, 0);
  }
  async ensureExists(id) {
    if (this.existingOptimizedDeps.has(id)) {
      return true;
    }
    if (fs.existsSync(id)) {
      this.existingOptimizedDeps.add(id);
      return true;
    }
    return new Promise((resolve2) => {
      setTimeout(() => {
        this.ensureExists(id).then(() => {
          resolve2(true);
        });
      });
    });
  }
  async resolveId(id, importer, transformMode) {
    if (importer && !importer.startsWith(utils.withTrailingSlash(this.server.config.root))) {
      importer = pathe.resolve(this.server.config.root, importer);
    }
    const mode = transformMode ?? (importer && this.getTransformMode(importer) || "ssr");
    return this.server.pluginContainer.resolveId(id, importer, {
      ssr: mode === "ssr"
    });
  }
  getSourceMap(source) {
    var _a, _b;
    const fetchResult = (_a = this.fetchCache.get(source)) == null ? void 0 : _a.result;
    if (fetchResult == null ? void 0 : fetchResult.map) {
      return fetchResult.map;
    }
    const ssrTransformResult = (_b = this.server.moduleGraph.getModuleById(source)) == null ? void 0 : _b.ssrTransformResult;
    return (ssrTransformResult == null ? void 0 : ssrTransformResult.map) || null;
  }
  assertMode(mode) {
    assert(
      mode === "web" || mode === "ssr",
      `"transformMode" can only be "web" or "ssr", received "${mode}".`
    );
  }
  async fetchModule(id, transformMode) {
    const mode = transformMode || this.getTransformMode(id);
    return this.fetchResult(id, mode).then((r) => {
      return this.options.sourcemap !== true ? { ...r, map: void 0 } : r;
    });
  }
  async fetchResult(id, mode) {
    const moduleId = utils.normalizeModuleId(id);
    this.assertMode(mode);
    const promiseMap = this.fetchPromiseMap[mode];
    if (!promiseMap.has(moduleId)) {
      promiseMap.set(
        moduleId,
        this._fetchModule(moduleId, mode).finally(() => {
          promiseMap.delete(moduleId);
        })
      );
    }
    return promiseMap.get(moduleId);
  }
  async transformRequest(id, filepath = id, transformMode) {
    const mode = transformMode || this.getTransformMode(id);
    this.assertMode(mode);
    const promiseMap = this.transformPromiseMap[mode];
    if (!promiseMap.has(id)) {
      promiseMap.set(
        id,
        this._transformRequest(id, filepath, mode).finally(() => {
          promiseMap.delete(id);
        })
      );
    }
    return promiseMap.get(id);
  }
  async transformModule(id, transformMode) {
    if (transformMode !== "web") {
      throw new Error(
        '`transformModule` only supports `transformMode: "web"`.'
      );
    }
    const normalizedId = utils.normalizeModuleId(id);
    const mod = this.server.moduleGraph.getModuleById(normalizedId);
    const result = (mod == null ? void 0 : mod.transformResult) || await this.server.transformRequest(normalizedId);
    return {
      code: result == null ? void 0 : result.code
    };
  }
  getTransformMode(id) {
    var _a, _b, _c, _d;
    const withoutQuery = id.split("?")[0];
    if ((_b = (_a = this.options.transformMode) == null ? void 0 : _a.web) == null ? void 0 : _b.some((r) => withoutQuery.match(r))) {
      return "web";
    }
    if ((_d = (_c = this.options.transformMode) == null ? void 0 : _c.ssr) == null ? void 0 : _d.some((r) => withoutQuery.match(r))) {
      return "ssr";
    }
    if (withoutQuery.match(/\.([cm]?[jt]sx?|json)$/)) {
      return "ssr";
    }
    return "web";
  }
  getChangedModule(id, file) {
    const module = this.server.moduleGraph.getModuleById(id) || this.server.moduleGraph.getModuleById(file);
    if (module) {
      return module;
    }
    const _modules = this.server.moduleGraph.getModulesByFile(file);
    if (!_modules || !_modules.size) {
      return null;
    }
    const modules = [..._modules];
    let mod = modules[0];
    let latestMax = -1;
    for (const m of _modules) {
      const timestamp = Math.max(
        m.lastHMRTimestamp,
        m.lastInvalidationTimestamp
      );
      if (timestamp > latestMax) {
        latestMax = timestamp;
        mod = m;
      }
    }
    return mod;
  }
  async _fetchModule(id, transformMode) {
    var _a, _b;
    let result;
    const cacheDir = (_a = this.options.deps) == null ? void 0 : _a.cacheDir;
    if (cacheDir && id.includes(cacheDir)) {
      if (!id.startsWith(utils.withTrailingSlash(this.server.config.root))) {
        id = pathe.join(this.server.config.root, id);
      }
      const timeout = setTimeout(() => {
        throw new Error(
          `ViteNodeServer: ${id} not found. This is a bug, please report it.`
        );
      }, 5e3);
      await this.ensureExists(id);
      clearTimeout(timeout);
    }
    const { path: filePath } = utils.toFilePath(id, this.server.config.root);
    const moduleNode = this.getChangedModule(id, filePath);
    const cache = this.fetchCaches[transformMode].get(filePath);
    const timestamp = moduleNode ? Math.max(
      moduleNode.lastHMRTimestamp,
      moduleNode.lastInvalidationTimestamp
    ) : 0;
    if (cache && (timestamp === 0 || cache.timestamp >= timestamp)) {
      return cache.result;
    }
    const time = Date.now();
    const externalize = await this.shouldExternalize(filePath);
    let duration;
    if (externalize) {
      result = { externalize };
      (_b = this.debugger) == null ? void 0 : _b.recordExternalize(id, externalize);
    } else {
      const start = node_perf_hooks.performance.now();
      const r = await this._transformRequest(id, filePath, transformMode);
      duration = node_perf_hooks.performance.now() - start;
      result = { code: r == null ? void 0 : r.code, map: r == null ? void 0 : r.map };
    }
    const cacheEntry = {
      duration,
      timestamp: time,
      result
    };
    const durations = this.durations[transformMode].get(filePath) || [];
    this.durations[transformMode].set(filePath, [...durations, duration ?? 0]);
    this.fetchCaches[transformMode].set(filePath, cacheEntry);
    this.fetchCache.set(filePath, cacheEntry);
    return result;
  }
  async processTransformResult(filepath, result) {
    const mod = this.server.moduleGraph.getModuleById(filepath);
    return sourceMap.withInlineSourcemap(result, {
      filepath: (mod == null ? void 0 : mod.file) || filepath,
      root: this.server.config.root
    });
  }
  async _transformRequest(id, filepath, transformMode) {
    var _a, _b, _c, _d;
    debugRequest(id);
    let result = null;
    if ((_a = this.options.debug) == null ? void 0 : _a.loadDumppedModules) {
      result = await ((_b = this.debugger) == null ? void 0 : _b.loadDump(id)) ?? null;
      if (result) {
        return result;
      }
    }
    if (transformMode === "web") {
      result = await this.server.transformRequest(id);
      if (result) {
        result = await this.server.ssrTransform(result.code, result.map, id);
      }
    } else {
      result = await this.server.transformRequest(id, { ssr: true });
    }
    const sourcemap = this.options.sourcemap ?? "inline";
    if (sourcemap === "inline" && result && !id.includes("node_modules")) {
      result = await this.processTransformResult(filepath, result);
    }
    if ((_c = this.options.debug) == null ? void 0 : _c.dumpModules) {
      await ((_d = this.debugger) == null ? void 0 : _d.dumpFile(id, result));
    }
    return result;
  }
}

exports.ViteNodeServer = ViteNodeServer;
exports.guessCJSversion = guessCJSversion;
exports.shouldExternalize = shouldExternalize;

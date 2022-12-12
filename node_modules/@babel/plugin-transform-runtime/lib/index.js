"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _helperPluginUtils = require("@babel/helper-plugin-utils");

var _helperModuleImports = require("@babel/helper-module-imports");

var _core = require("@babel/core");

var _helpers = require("./helpers");

var _getRuntimePath = _interopRequireDefault(require("./get-runtime-path"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const _pluginCorejs2 = require("babel-plugin-polyfill-corejs2");

const _pluginCorejs3 = require("babel-plugin-polyfill-corejs3");

const _pluginRegenerator = require("babel-plugin-polyfill-regenerator");

const pluginCorejs2 = _pluginCorejs2.default;
const pluginCorejs3 = _pluginCorejs3.default;
const pluginRegenerator = _pluginRegenerator.default;
const pluginsCompat = "#__secret_key__@babel/runtime__compatibility";

function supportsStaticESM(caller) {
  return !!(caller != null && caller.supportsStaticESM);
}

var _default = (0, _helperPluginUtils.declare)((api, options, dirname) => {
  api.assertVersion(7);
  const {
    corejs,
    helpers: useRuntimeHelpers = true,
    regenerator: useRuntimeRegenerator = true,
    useESModules = false,
    version: runtimeVersion = "7.0.0-beta.0",
    absoluteRuntime = false
  } = options;
  let proposals = false;
  let rawVersion;

  if (typeof corejs === "object" && corejs !== null) {
    rawVersion = corejs.version;
    proposals = Boolean(corejs.proposals);
  } else {
    rawVersion = corejs;
  }

  const corejsVersion = rawVersion ? Number(rawVersion) : false;

  if (![false, 2, 3].includes(corejsVersion)) {
    throw new Error(`The \`core-js\` version must be false, 2 or 3, but got ${JSON.stringify(rawVersion)}.`);
  }

  if (proposals && (!corejsVersion || corejsVersion < 3)) {
    throw new Error("The 'proposals' option is only supported when using 'corejs: 3'");
  }

  if (typeof useRuntimeRegenerator !== "boolean") {
    throw new Error("The 'regenerator' option must be undefined, or a boolean.");
  }

  if (typeof useRuntimeHelpers !== "boolean") {
    throw new Error("The 'helpers' option must be undefined, or a boolean.");
  }

  if (typeof useESModules !== "boolean" && useESModules !== "auto") {
    throw new Error("The 'useESModules' option must be undefined, or a boolean, or 'auto'.");
  }

  if (typeof absoluteRuntime !== "boolean" && typeof absoluteRuntime !== "string") {
    throw new Error("The 'absoluteRuntime' option must be undefined, a boolean, or a string.");
  }

  if (typeof runtimeVersion !== "string") {
    throw new Error(`The 'version' option must be a version string.`);
  }

  const DUAL_MODE_RUNTIME = "7.13.0";
  const supportsCJSDefault = (0, _helpers.hasMinVersion)(DUAL_MODE_RUNTIME, runtimeVersion);

  function has(obj, key) {
    return Object.prototype.hasOwnProperty.call(obj, key);
  }

  if (has(options, "useBuiltIns")) {
    if (options.useBuiltIns) {
      throw new Error("The 'useBuiltIns' option has been removed. The @babel/runtime " + "module now uses builtins by default.");
    } else {
      throw new Error("The 'useBuiltIns' option has been removed. Use the 'corejs'" + "option to polyfill with `core-js` via @babel/runtime.");
    }
  }

  if (has(options, "polyfill")) {
    if (options.polyfill === false) {
      throw new Error("The 'polyfill' option has been removed. The @babel/runtime " + "module now skips polyfilling by default.");
    } else {
      throw new Error("The 'polyfill' option has been removed. Use the 'corejs'" + "option to polyfill with `core-js` via @babel/runtime.");
    }
  }

  if (has(options, "moduleName")) {
    throw new Error("The 'moduleName' option has been removed. @babel/transform-runtime " + "no longer supports arbitrary runtimes. If you were using this to " + "set an absolute path for Babel's standard runtimes, please use the " + "'absoluteRuntime' option.");
  }

  const esModules = useESModules === "auto" ? api.caller(supportsStaticESM) : useESModules;
  const injectCoreJS2 = corejsVersion === 2;
  const injectCoreJS3 = corejsVersion === 3;
  const moduleName = injectCoreJS3 ? "@babel/runtime-corejs3" : injectCoreJS2 ? "@babel/runtime-corejs2" : "@babel/runtime";
  const HEADER_HELPERS = ["interopRequireWildcard", "interopRequireDefault"];
  const modulePath = (0, _getRuntimePath.default)(moduleName, dirname, absoluteRuntime);

  function createCorejsPlgin(plugin, options, regeneratorPlugin) {
    return (api, _, filename) => {
      return Object.assign({}, plugin(api, options, filename), {
        inherits: regeneratorPlugin
      });
    };
  }

  function createRegeneratorPlugin(options) {
    if (!useRuntimeRegenerator) return undefined;
    return (api, _, filename) => {
      return pluginRegenerator(api, options, filename);
    };
  }

  const corejsExt = absoluteRuntime ? ".js" : "";
  return {
    name: "transform-runtime",
    inherits: injectCoreJS2 ? createCorejsPlgin(pluginCorejs2, {
      method: "usage-pure",
      [pluginsCompat]: {
        runtimeVersion,
        useBabelRuntime: modulePath,
        ext: corejsExt
      }
    }, createRegeneratorPlugin({
      method: "usage-pure",
      [pluginsCompat]: {
        useBabelRuntime: modulePath
      }
    })) : injectCoreJS3 ? createCorejsPlgin(pluginCorejs3, {
      method: "usage-pure",
      version: 3,
      proposals,
      [pluginsCompat]: {
        useBabelRuntime: modulePath,
        ext: corejsExt
      }
    }, createRegeneratorPlugin({
      method: "usage-pure",
      [pluginsCompat]: {
        useBabelRuntime: modulePath
      }
    })) : createRegeneratorPlugin({
      method: "usage-pure",
      [pluginsCompat]: {
        useBabelRuntime: modulePath
      }
    }),

    pre(file) {
      if (!useRuntimeHelpers) return;
      file.set("helperGenerator", name => {
        if (file.availableHelper && !file.availableHelper(name, runtimeVersion)) {
          return;
        }

        const isInteropHelper = HEADER_HELPERS.indexOf(name) !== -1;
        const blockHoist = isInteropHelper && !(0, _helperModuleImports.isModule)(file.path) ? 4 : undefined;
        const helpersDir = esModules && file.path.node.sourceType === "module" ? "helpers/esm" : "helpers";
        return addDefaultImport(`${modulePath}/${helpersDir}/${name}`, name, blockHoist, true);
      });
      const cache = new Map();

      function addDefaultImport(source, nameHint, blockHoist, isHelper = false) {
        const cacheKey = (0, _helperModuleImports.isModule)(file.path);
        const key = `${source}:${nameHint}:${cacheKey || ""}`;
        let cached = cache.get(key);

        if (cached) {
          cached = _core.types.cloneNode(cached);
        } else {
          cached = (0, _helperModuleImports.addDefault)(file.path, source, {
            importedInterop: isHelper && supportsCJSDefault ? "compiled" : "uncompiled",
            nameHint,
            blockHoist
          });
          cache.set(key, cached);
        }

        return cached;
      }
    }

  };
});

exports.default = _default;
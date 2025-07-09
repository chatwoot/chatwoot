"use strict";
var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// src/index.ts
var src_exports = {};
__export(src_exports, {
  default: () => ViteRubyPlugin,
  projectRoot: () => projectRoot
});
module.exports = __toCommonJS(src_exports);
var import_path3 = require("path");
var import_fs3 = require("fs");
var import_debug2 = __toESM(require("debug"), 1);

// src/utils.ts
var import_fs = require("fs");

// src/constants.ts
var APP_ENV = process.env.RAILS_ENV || process.env.RACK_ENV || process.env.APP_ENV;
var ENV_PREFIX = "VITE_RUBY";
var ALL_ENVS_KEY = "all";
var KNOWN_CSS_EXTENSIONS = [
  "css",
  "less",
  "sass",
  "scss",
  "styl",
  "stylus",
  "pcss",
  "postcss"
];
var KNOWN_ENTRYPOINT_TYPES = [
  "html",
  "jsx?",
  "tsx?",
  ...KNOWN_CSS_EXTENSIONS
];
var ENTRYPOINT_TYPES_REGEX = new RegExp(
  `\\.(${KNOWN_ENTRYPOINT_TYPES.join("|")})(\\?.*)?$`
);

// src/utils.ts
function slash(path2) {
  return path2.replace(/\\/g, "/");
}
function isObject(value) {
  return Object.prototype.toString.call(value) === "[object Object]";
}
function screamCase(key) {
  return key.replace(/([a-z])([A-Z])/g, "$1_$2").toUpperCase();
}
function configOptionFromEnv(optionName) {
  return process.env[`${ENV_PREFIX}_${screamCase(optionName)}`];
}
function booleanOption(value) {
  if (value === "true")
    return true;
  if (value === "false")
    return false;
  return value;
}
function loadJsonConfig(filepath) {
  return JSON.parse((0, import_fs.readFileSync)(filepath, { encoding: "utf8", flag: "r" }));
}
function cleanConfig(object) {
  Object.keys(object).forEach((key) => {
    const value = object[key];
    if (value === void 0 || value === null)
      delete object[key];
    else if (isObject(value))
      cleanConfig(value);
  });
  return object;
}

// src/config.ts
var import_path = require("path");
var import_fast_glob = __toESM(require("fast-glob"), 1);
var defaultConfig = loadJsonConfig((0, import_path.resolve)(__dirname, "../default.vite.json"));
function filterEntrypointsForRollup(entrypoints) {
  return entrypoints.filter(([_name, filename]) => ENTRYPOINT_TYPES_REGEX.test(filename));
}
function filterEntrypointAssets(entrypoints) {
  return entrypoints.filter(([_name, filename]) => !ENTRYPOINT_TYPES_REGEX.test(filename));
}
function resolveEntrypointFiles(projectRoot2, sourceCodeDir, config2) {
  const inputGlobs = config2.ssrBuild ? [config2.ssrEntrypoint] : [`~/${config2.entrypointsDir}/**/*`, ...config2.additionalEntrypoints];
  const entrypointFiles = import_fast_glob.default.sync(resolveGlobs(projectRoot2, sourceCodeDir, inputGlobs));
  if (config2.ssrBuild) {
    if (entrypointFiles.length === 0)
      throw new Error(`No SSR entrypoint available, please create \`${config2.ssrEntrypoint}\` to do an SSR build.`);
    else if (entrypointFiles.length > 1)
      throw new Error(`Expected a single SSR entrypoint, found: ${entrypointFiles}`);
    return entrypointFiles.map((file) => ["ssr", file]);
  }
  return entrypointFiles.map((filename) => {
    let name = (0, import_path.relative)(sourceCodeDir, filename);
    if (name.startsWith(".."))
      name = (0, import_path.relative)(projectRoot2, filename);
    return [name, filename];
  });
}
function resolveGlobs(projectRoot2, sourceCodeDir, patterns) {
  return patterns.map(
    (pattern) => slash((0, import_path.resolve)(projectRoot2, pattern.replace(/^~\//, `${sourceCodeDir}/`)))
  );
}
function configFromEnv() {
  const envConfig = {};
  Object.keys(defaultConfig).forEach((optionName) => {
    const envValue = configOptionFromEnv(optionName);
    if (envValue !== void 0)
      envConfig[optionName] = envValue;
  });
  return envConfig;
}
function loadConfiguration(viteMode, projectRoot2, userConfig) {
  const envConfig = configFromEnv();
  const mode = envConfig.mode || APP_ENV || viteMode;
  const filePath = (0, import_path.join)(projectRoot2, envConfig.configPath || defaultConfig.configPath);
  const multiEnvConfig = loadJsonConfig(filePath);
  const fileConfig = { ...multiEnvConfig[ALL_ENVS_KEY], ...multiEnvConfig[mode] };
  return coerceConfigurationValues({ ...defaultConfig, ...fileConfig, ...envConfig, mode }, projectRoot2, userConfig);
}
function coerceConfigurationValues(config2, projectRoot2, userConfig) {
  var _a, _b, _c, _d, _e, _f, _g;
  const port = config2.port = parseInt(config2.port);
  const https = config2.https = ((_a = userConfig.server) == null ? void 0 : _a.https) || booleanOption(config2.https);
  const fs = { allow: [projectRoot2], strict: (_d = (_c = (_b = userConfig.server) == null ? void 0 : _b.fs) == null ? void 0 : _c.strict) != null ? _d : true };
  const server = { fs, host: config2.host, https, port, strictPort: true };
  if (booleanOption(config2.skipProxy))
    server.origin = `${https ? "https" : "http"}://${config2.host}:${config2.port}`;
  const hmr = (_f = (_e = userConfig.server) == null ? void 0 : _e.hmr) != null ? _f : {};
  if (typeof hmr === "object" && !hmr.hasOwnProperty("clientPort")) {
    hmr.clientPort || (hmr.clientPort = port);
    server.hmr = hmr;
  }
  const root = (0, import_path.join)(projectRoot2, config2.sourceCodeDir);
  const ssrEntrypoint = (_g = userConfig.build) == null ? void 0 : _g.ssr;
  config2.ssrBuild = Boolean(ssrEntrypoint);
  if (typeof ssrEntrypoint === "string")
    config2.ssrEntrypoint = ssrEntrypoint;
  const outDir = (0, import_path.relative)(root, config2.ssrBuild ? config2.ssrOutputDir : (0, import_path.join)(config2.publicDir, config2.publicOutputDir));
  const base = resolveViteBase(config2);
  const entrypoints = resolveEntrypointFiles(projectRoot2, root, config2);
  return { ...config2, server, root, outDir, base, entrypoints };
}
function resolveViteBase({ assetHost, base, publicOutputDir }) {
  if (assetHost && !assetHost.startsWith("http"))
    assetHost = `//${assetHost}`;
  return [
    ensureTrailingSlash(assetHost || base || "/"),
    publicOutputDir ? ensureTrailingSlash(slash(publicOutputDir)) : ""
  ].join("");
}
function ensureTrailingSlash(path2) {
  return path2.endsWith("/") ? path2 : `${path2}/`;
}

// src/manifest.ts
var import_path2 = __toESM(require("path"), 1);
var import_fs2 = require("fs");
var import_debug = __toESM(require("debug"), 1);
var debug = (0, import_debug.default)("vite-plugin-ruby:assets-manifest");
function assetsManifestPlugin() {
  let config2;
  let viteRubyConfig;
  async function fingerprintRemainingAssets(ctx, bundle, manifest) {
    const remainingAssets = filterEntrypointAssets(viteRubyConfig.entrypoints);
    for (const [filename, absoluteFilename] of remainingAssets) {
      const content = await import_fs2.promises.readFile(absoluteFilename);
      const ref = ctx.emitFile({ name: import_path2.default.basename(filename), type: "asset", source: content });
      const hashedFilename = ctx.getFileName(ref);
      manifest.set(import_path2.default.relative(config2.root, absoluteFilename), { file: hashedFilename, src: filename });
    }
  }
  return {
    name: "vite-plugin-ruby:assets-manifest",
    apply: "build",
    enforce: "post",
    configResolved(resolvedConfig) {
      config2 = resolvedConfig;
      viteRubyConfig = config2.viteRuby;
    },
    async generateBundle(_options, bundle) {
      if (!config2.build.manifest)
        return;
      const manifestDir = typeof config2.build.manifest === "string" ? import_path2.default.basename(config2.build.manifest) : ".vite";
      const fileName = `${manifestDir}/manifest-assets.json`;
      const manifest = /* @__PURE__ */ new Map();
      await fingerprintRemainingAssets(this, bundle, manifest);
      debug({ manifest, fileName });
      this.emitFile({
        fileName,
        type: "asset",
        source: JSON.stringify(Object.fromEntries(manifest), null, 2)
      });
    }
  };
}

// src/index.ts
var projectRoot = configOptionFromEnv("root") || process.cwd();
var watchAdditionalPaths = [];
function ViteRubyPlugin() {
  return [
    {
      name: "vite-plugin-ruby",
      config,
      configureServer
    },
    assetsManifestPlugin()
  ];
}
var debug2 = (0, import_debug2.default)("vite-plugin-ruby:config");
function config(userConfig, env) {
  var _a, _b, _c, _d;
  const config2 = loadConfiguration(env.mode, projectRoot, userConfig);
  const { assetsDir, base, outDir, server, root, entrypoints, ssrBuild } = config2;
  const isLocal = config2.mode === "development" || config2.mode === "test";
  const build = {
    emptyOutDir: (_b = (_a = userConfig.build) == null ? void 0 : _a.emptyOutDir) != null ? _b : ssrBuild || isLocal,
    sourcemap: !isLocal,
    ...userConfig.build,
    assetsDir,
    manifest: !ssrBuild,
    outDir,
    rollupOptions: {
      input: Object.fromEntries(filterEntrypointsForRollup(entrypoints)),
      output: {
        ...outputOptions(assetsDir, ssrBuild),
        ...(_d = (_c = userConfig.build) == null ? void 0 : _c.rollupOptions) == null ? void 0 : _d.output
      }
    }
  };
  const envDir = userConfig.envDir || projectRoot;
  debug2({ base, build, envDir, root, server, entrypoints: Object.fromEntries(entrypoints) });
  watchAdditionalPaths = resolveGlobs(projectRoot, root, config2.watchAdditionalPaths || []);
  const alias = { "~/": `${root}/`, "@/": `${root}/` };
  return cleanConfig({
    resolve: { alias },
    base,
    envDir,
    root,
    server,
    build,
    viteRuby: config2
  });
}
function configureServer(server) {
  server.watcher.add(watchAdditionalPaths);
  return () => server.middlewares.use((req, res, next) => {
    if (req.url === "/index.html" && !(0, import_fs3.existsSync)((0, import_path3.resolve)(server.config.root, "index.html"))) {
      res.statusCode = 404;
      const file = (0, import_fs3.readFileSync)((0, import_path3.resolve)(__dirname, "dev-server-index.html"), "utf-8");
      res.end(file);
    }
    next();
  });
}
function outputOptions(assetsDir, ssrBuild) {
  const outputFileName = (ext) => ({ name }) => {
    const shortName = (0, import_path3.basename)(name).split(".")[0];
    return import_path3.posix.join(assetsDir, `${shortName}-[hash].${ext}`);
  };
  return {
    assetFileNames: ssrBuild ? void 0 : outputFileName("[ext]"),
    entryFileNames: ssrBuild ? void 0 : outputFileName("js")
  };
}
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {
  projectRoot
});
//# sourceMappingURL=index.cjs.map
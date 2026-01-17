'use strict';

var path = require('node:path');
var cac = require('cac');
var c = require('picocolors');
var vite = require('vite');
var server = require('./server.cjs');
var client = require('./client.cjs');
var utils = require('./utils.cjs');
var sourceMap = require('./source-map.cjs');
var hmr = require('./chunk-hmr.cjs');
require('node:perf_hooks');
require('node:fs');
require('node:assert');
require('pathe');
require('debug');
require('./constants.cjs');
require('node:module');
require('node:url');
require('node:vm');
require('node:events');

var version = "2.0.1";

const cli = cac("vite-node");
cli.option("-r, --root <path>", "Use specified root directory").option("-c, --config <path>", "Use specified config file").option("-m, --mode <mode>", "Set env mode").option("-w, --watch", 'Restart on file changes, similar to "nodemon"').option("--script", "Use vite-node as a script runner").option("--options <options>", "Use specified Vite server options").option("-v, --version", "Output the version number").option("-h, --help", "Display help for command");
cli.command("[...files]").allowUnknownOptions().action(run);
cli.parse(process.argv, { run: false });
if (cli.args.length === 0) {
  cli.runMatchedCommand();
} else {
  const i = cli.rawArgs.indexOf(cli.args[0]) + 1;
  const scriptArgs = cli.rawArgs.slice(i).filter((it) => it !== "--");
  const executeArgs = [...cli.rawArgs.slice(0, i), "--", ...scriptArgs];
  cli.parse(executeArgs);
}
async function run(files, options = {}) {
  var _a, _b;
  if (options.script) {
    files = [files[0]];
    options = {};
    process.argv = [
      process.argv[0],
      path.resolve(files[0]),
      ...process.argv.slice(2).filter((arg) => arg !== "--script" && arg !== files[0])
    ];
  } else {
    process.argv = [...process.argv.slice(0, 2), ...options["--"] || []];
  }
  if (options.version) {
    cli.version(version);
    cli.outputVersion();
    process.exit(0);
  }
  if (options.help) {
    cli.version(version).outputHelp();
    process.exit(0);
  }
  if (!files.length) {
    console.error(c.red("No files specified."));
    cli.version(version).outputHelp();
    process.exit(1);
  }
  const serverOptions = options.options ? parseServerOptions(options.options) : {};
  const server$1 = await vite.createServer({
    logLevel: "error",
    configFile: options.config,
    root: options.root,
    mode: options.mode,
    server: {
      hmr: !!options.watch
    },
    plugins: [options.watch && hmr.viteNodeHmrPlugin()]
  });
  await server$1.pluginContainer.buildStart({});
  const env = vite.loadEnv(server$1.config.mode, server$1.config.envDir, "");
  for (const key in env) {
    (_a = process.env)[key] ?? (_a[key] = env[key]);
  }
  const node = new server.ViteNodeServer(server$1, serverOptions);
  sourceMap.installSourcemapsSupport({
    getSourceMap: (source) => node.getSourceMap(source)
  });
  const runner = new client.ViteNodeRunner({
    root: server$1.config.root,
    base: server$1.config.base,
    fetchModule(id) {
      return node.fetchModule(id);
    },
    resolveId(id, importer) {
      return node.resolveId(id, importer);
    },
    createHotContext(runner2, url) {
      return hmr.createHotContext(runner2, server$1.emitter, files, url);
    }
  });
  await runner.executeId("/@vite/env");
  for (const file of files) {
    await runner.executeFile(file);
  }
  if (!options.watch) {
    await server$1.close();
  }
  (_b = server$1.emitter) == null ? void 0 : _b.on("message", (payload) => {
    hmr.handleMessage(runner, server$1.emitter, files, payload);
  });
  if (options.watch) {
    process.on("uncaughtException", (err) => {
      console.error(c.red("[vite-node] Failed to execute file: \n"), err);
    });
  }
}
function parseServerOptions(serverOptions) {
  var _a, _b, _c, _d, _e, _f, _g;
  const inlineOptions = ((_a = serverOptions.deps) == null ? void 0 : _a.inline) === true ? true : utils.toArray((_b = serverOptions.deps) == null ? void 0 : _b.inline);
  return {
    ...serverOptions,
    deps: {
      ...serverOptions.deps,
      inline: inlineOptions !== true ? inlineOptions.map((dep) => {
        return dep.startsWith("/") && dep.endsWith("/") ? new RegExp(dep) : dep;
      }) : true,
      external: utils.toArray((_c = serverOptions.deps) == null ? void 0 : _c.external).map((dep) => {
        return dep.startsWith("/") && dep.endsWith("/") ? new RegExp(dep) : dep;
      }),
      moduleDirectories: ((_d = serverOptions.deps) == null ? void 0 : _d.moduleDirectories) ? utils.toArray((_e = serverOptions.deps) == null ? void 0 : _e.moduleDirectories) : void 0
    },
    transformMode: {
      ...serverOptions.transformMode,
      ssr: utils.toArray((_f = serverOptions.transformMode) == null ? void 0 : _f.ssr).map(
        (dep) => new RegExp(dep)
      ),
      web: utils.toArray((_g = serverOptions.transformMode) == null ? void 0 : _g.web).map(
        (dep) => new RegExp(dep)
      )
    }
  };
}

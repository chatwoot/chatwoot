import { resolve } from 'node:path';
import cac from 'cac';
import c from 'picocolors';
import { createServer, loadEnv } from 'vite';
import { ViteNodeServer } from './server.mjs';
import { ViteNodeRunner } from './client.mjs';
import { toArray } from './utils.mjs';
import { installSourcemapsSupport } from './source-map.mjs';
import { v as viteNodeHmrPlugin, a as createHotContext, h as handleMessage } from './chunk-hmr.mjs';
import 'node:perf_hooks';
import 'node:fs';
import 'node:assert';
import 'pathe';
import 'debug';
import './constants.mjs';
import 'node:module';
import 'node:url';
import 'node:vm';
import 'node:events';

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
      resolve(files[0]),
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
  const server = await createServer({
    logLevel: "error",
    configFile: options.config,
    root: options.root,
    mode: options.mode,
    server: {
      hmr: !!options.watch
    },
    plugins: [options.watch && viteNodeHmrPlugin()]
  });
  await server.pluginContainer.buildStart({});
  const env = loadEnv(server.config.mode, server.config.envDir, "");
  for (const key in env) {
    (_a = process.env)[key] ?? (_a[key] = env[key]);
  }
  const node = new ViteNodeServer(server, serverOptions);
  installSourcemapsSupport({
    getSourceMap: (source) => node.getSourceMap(source)
  });
  const runner = new ViteNodeRunner({
    root: server.config.root,
    base: server.config.base,
    fetchModule(id) {
      return node.fetchModule(id);
    },
    resolveId(id, importer) {
      return node.resolveId(id, importer);
    },
    createHotContext(runner2, url) {
      return createHotContext(runner2, server.emitter, files, url);
    }
  });
  await runner.executeId("/@vite/env");
  for (const file of files) {
    await runner.executeFile(file);
  }
  if (!options.watch) {
    await server.close();
  }
  (_b = server.emitter) == null ? void 0 : _b.on("message", (payload) => {
    handleMessage(runner, server.emitter, files, payload);
  });
  if (options.watch) {
    process.on("uncaughtException", (err) => {
      console.error(c.red("[vite-node] Failed to execute file: \n"), err);
    });
  }
}
function parseServerOptions(serverOptions) {
  var _a, _b, _c, _d, _e, _f, _g;
  const inlineOptions = ((_a = serverOptions.deps) == null ? void 0 : _a.inline) === true ? true : toArray((_b = serverOptions.deps) == null ? void 0 : _b.inline);
  return {
    ...serverOptions,
    deps: {
      ...serverOptions.deps,
      inline: inlineOptions !== true ? inlineOptions.map((dep) => {
        return dep.startsWith("/") && dep.endsWith("/") ? new RegExp(dep) : dep;
      }) : true,
      external: toArray((_c = serverOptions.deps) == null ? void 0 : _c.external).map((dep) => {
        return dep.startsWith("/") && dep.endsWith("/") ? new RegExp(dep) : dep;
      }),
      moduleDirectories: ((_d = serverOptions.deps) == null ? void 0 : _d.moduleDirectories) ? toArray((_e = serverOptions.deps) == null ? void 0 : _e.moduleDirectories) : void 0
    },
    transformMode: {
      ...serverOptions.transformMode,
      ssr: toArray((_f = serverOptions.transformMode) == null ? void 0 : _f.ssr).map(
        (dep) => new RegExp(dep)
      ),
      web: toArray((_g = serverOptions.transformMode) == null ? void 0 : _g.web).map(
        (dep) => new RegExp(dep)
      )
    }
  };
}

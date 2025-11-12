import { resolveConfig as resolveConfig$1, mergeConfig, createServer as createServer$1 } from 'vite';
export { esbuildVersion, isFileServingAllowed, parseAst, parseAstAsync, rollupVersion, version as viteVersion } from 'vite';
import { V as Vitest, a as VitestPlugin, T as TestModule } from './chunks/cli-api.az_rB_xZ.js';
export { G as GitNotFoundError, F as TestsNotFoundError, b as VitestPackageInstaller, e as createViteLogger, c as createVitest, i as isValidApiRequest, d as registerConsoleShortcuts, r as resolveFsAllow, s as startVitest } from './chunks/cli-api.az_rB_xZ.js';
export { p as parseCLI } from './chunks/cac.B_eDEFh6.js';
import { a as resolveConfig$2 } from './chunks/resolveConfig.BT-MMQUD.js';
export { B as BaseSequencer, d as createMethodsRPC, g as getFilePoolName, b as resolveApiServerConfig } from './chunks/resolveConfig.BT-MMQUD.js';
import { slash } from '@vitest/utils';
import { f as findUp } from './chunks/index.B57_6XMC.js';
import { resolve } from 'pathe';
import { c as configFiles } from './chunks/constants.fzPh7AOq.js';
export { distDir, rootDir } from './path.js';
import createDebug from 'debug';
export { generateFileHash } from '@vitest/runner/utils';
import 'node:fs';
import './chunks/coverage.BWeNbfBa.js';
import 'node:path';
import '@vitest/snapshot/manager';
import 'vite-node/client';
import 'vite-node/server';
import './chunks/index.TH3f4LSA.js';
import './chunks/index.vId0fl99.js';
import 'tinyrainbow';
import './chunks/utils.DJWL04yX.js';
import 'node:util';
import 'node:perf_hooks';
import '@vitest/utils/source-map';
import './chunks/typechecker.CdcjdhoT.js';
import 'std-env';
import 'node:fs/promises';
import 'tinyexec';
import 'node:os';
import 'node:url';
import 'node:module';
import 'fs';
import 'node:console';
import 'node:stream';
import 'stream';
import 'zlib';
import 'buffer';
import 'crypto';
import 'events';
import 'https';
import 'http';
import 'net';
import 'tls';
import 'url';
import './chunks/_commonjsHelpers.BFTU3MAI.js';
import 'node:crypto';
import 'os';
import 'path';
import 'vite-node/utils';
import '@vitest/mocker/node';
import 'magic-string';
import 'node:assert';
import '@vitest/utils/error';
import 'node:readline';
import 'node:process';
import 'node:v8';
import 'node:tty';
import 'util';
import 'node:events';
import 'tinypool';
import 'node:worker_threads';
import 'readline';

async function resolveConfig(options = {}, viteOverrides = {}) {
  const root = slash(resolve(options.root || process.cwd()));
  const configPath = options.config === false ? false : options.config ? resolve(root, options.config) : await findUp(configFiles, { cwd: root });
  options.config = configPath;
  const vitest = new Vitest("test");
  const config = await resolveConfig$1(
    mergeConfig(
      {
        configFile: configPath,
        // this will make "mode": "test" | "benchmark" inside defineConfig
        mode: options.mode || "test",
        plugins: [
          await VitestPlugin(options, vitest)
        ]
      },
      mergeConfig(viteOverrides, { root: options.root })
    ),
    "serve"
  );
  const updatedOptions = Reflect.get(config, "_vitest");
  const vitestConfig = resolveConfig$2(
    vitest,
    updatedOptions,
    config
  );
  return {
    viteConfig: config,
    vitestConfig
  };
}

function createDebugger(namespace) {
  const debug = createDebug(namespace);
  if (debug.enabled) {
    return debug;
  }
}

const version = Vitest.version;
const createServer = createServer$1;
const createViteServer = createServer$1;
const TestFile = TestModule;

export { TestFile, VitestPlugin, createDebugger, createServer, createViteServer, resolveConfig, version };

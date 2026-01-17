import { addSerializer } from '@vitest/snapshot';
import { setSafeTimers } from '@vitest/utils';
import { r as resetRunOnceCounter } from './run-once.2ogXb3JV.js';

let globalSetup = false;
async function setupCommonEnv(config) {
  resetRunOnceCounter();
  setupDefines(config.defines);
  setupEnv(config.env);
  if (globalSetup) {
    return;
  }
  globalSetup = true;
  setSafeTimers();
  if (config.globals) {
    (await import('./globals.BSNBk3vE.js')).registerApiGlobally();
  }
}
function setupDefines(defines) {
  for (const key in defines) {
    globalThis[key] = defines[key];
  }
}
function setupEnv(env) {
  if (typeof process === "undefined") {
    return;
  }
  const { PROD, DEV, ...restEnvs } = env;
  process.env.PROD = PROD ? "1" : "";
  process.env.DEV = DEV ? "1" : "";
  for (const key in restEnvs) {
    process.env[key] = env[key];
  }
}
async function loadDiffConfig(config, executor) {
  if (typeof config.diff === "object") {
    return config.diff;
  }
  if (typeof config.diff !== "string") {
    return;
  }
  const diffModule = await executor.executeId(config.diff);
  if (diffModule && typeof diffModule.default === "object" && diffModule.default != null) {
    return diffModule.default;
  } else {
    throw new Error(
      `invalid diff config file ${config.diff}. Must have a default export with config object`
    );
  }
}
async function loadSnapshotSerializers(config, executor) {
  const files = config.snapshotSerializers;
  const snapshotSerializers = await Promise.all(
    files.map(async (file) => {
      const mo = await executor.executeId(file);
      if (!mo || typeof mo.default !== "object" || mo.default === null) {
        throw new Error(
          `invalid snapshot serializer file ${file}. Must export a default object`
        );
      }
      const config2 = mo.default;
      if (typeof config2.test !== "function" || typeof config2.serialize !== "function" && typeof config2.print !== "function") {
        throw new TypeError(
          `invalid snapshot serializer in ${file}. Must have a 'test' method along with either a 'serialize' or 'print' method.`
        );
      }
      return config2;
    })
  );
  snapshotSerializers.forEach((serializer) => addSerializer(serializer));
}

export { loadSnapshotSerializers as a, loadDiffConfig as l, setupCommonEnv as s };

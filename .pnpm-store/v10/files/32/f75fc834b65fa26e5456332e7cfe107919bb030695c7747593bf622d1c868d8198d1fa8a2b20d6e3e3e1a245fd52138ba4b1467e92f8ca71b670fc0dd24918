"use strict";
import {
  isMovable,
  kRequestCountField,
  kResponseCountField,
  kTransferable,
  kValue
} from "./chunk-QYFJIXNO.js";

// src/worker.ts
import {
  parentPort,
  receiveMessageOnPort,
  workerData as tinypoolData
} from "worker_threads";
import { pathToFileURL } from "url";

// src/utils.ts
function stdout() {
  return console._stdout || process.stdout || void 0;
}
function stderr() {
  return console._stderr || process.stderr || void 0;
}

// src/worker.ts
var [tinypoolPrivateData, workerData] = tinypoolData;
process.__tinypool_state__ = {
  isWorkerThread: true,
  workerData,
  workerId: tinypoolPrivateData.workerId
};
var handlerCache = /* @__PURE__ */ new Map();
var useAtomics = process.env.PISCINA_DISABLE_ATOMICS !== "1";
var importESMCached;
function getImportESM() {
  if (importESMCached === void 0) {
    importESMCached = new Function("specifier", "return import(specifier)");
  }
  return importESMCached;
}
async function getHandler(filename, name) {
  let handler = handlerCache.get(`${filename}/${name}`);
  if (handler !== void 0) {
    return handler;
  }
  try {
    const handlerModule = await import(filename);
    handler = typeof handlerModule.default !== "function" && handlerModule.default || handlerModule;
    if (typeof handler !== "function") {
      handler = await handler[name];
    }
  } catch {
  }
  if (typeof handler !== "function") {
    handler = await getImportESM()(pathToFileURL(filename).href);
    if (typeof handler !== "function") {
      handler = await handler[name];
    }
  }
  if (typeof handler !== "function") {
    return null;
  }
  if (handlerCache.size > 1e3) {
    const [[key]] = handlerCache;
    handlerCache.delete(key);
  }
  handlerCache.set(`${filename}/${name}`, handler);
  return handler;
}
parentPort.on("message", (message) => {
  useAtomics = process.env.PISCINA_DISABLE_ATOMICS === "1" ? false : message.useAtomics;
  if (!message?.tinypoolStartupMessage)
    return;
  const { port, sharedBuffer, filename, name } = message;
  (async function() {
    if (filename !== null) {
      await getHandler(filename, name);
    }
    const readyMessage = { ready: true };
    parentPort.postMessage(readyMessage);
    port.on("message", onMessage.bind(null, port, sharedBuffer));
    atomicsWaitLoop(port, sharedBuffer);
  })().catch(throwInNextTick);
});
var currentTasks = 0;
var lastSeenRequestCount = 0;
function atomicsWaitLoop(port, sharedBuffer) {
  if (!useAtomics)
    return;
  while (currentTasks === 0) {
    Atomics.wait(sharedBuffer, kRequestCountField, lastSeenRequestCount);
    lastSeenRequestCount = Atomics.load(sharedBuffer, kRequestCountField);
    let entry;
    while ((entry = receiveMessageOnPort(port)) !== void 0) {
      onMessage(port, sharedBuffer, entry.message);
    }
  }
}
function onMessage(port, sharedBuffer, message) {
  currentTasks++;
  const { taskId, task, filename, name } = message;
  (async function() {
    let response;
    let transferList = [];
    try {
      const handler = await getHandler(filename, name);
      if (handler === null) {
        throw new Error(`No handler function exported from ${filename}`);
      }
      let result = await handler(task);
      if (isMovable(result)) {
        transferList = transferList.concat(result[kTransferable]);
        result = result[kValue];
      }
      response = {
        taskId,
        result,
        error: null
      };
      if (stdout()?.writableLength > 0) {
        await new Promise((resolve) => process.stdout.write("", resolve));
      }
      if (stderr()?.writableLength > 0) {
        await new Promise((resolve) => process.stderr.write("", resolve));
      }
    } catch (error) {
      response = {
        taskId,
        result: null,
        error
      };
    }
    currentTasks--;
    port.postMessage(response, transferList);
    Atomics.add(sharedBuffer, kResponseCountField, 1);
    atomicsWaitLoop(port, sharedBuffer);
  })().catch(throwInNextTick);
}
function throwInNextTick(error) {
  process.nextTick(() => {
    throw error;
  });
}

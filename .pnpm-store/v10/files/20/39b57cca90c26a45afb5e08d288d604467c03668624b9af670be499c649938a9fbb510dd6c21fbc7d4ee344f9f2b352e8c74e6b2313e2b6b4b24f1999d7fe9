import {
  isMovable,
  kRequestCountField,
  kResponseCountField,
  kTransferable,
  kValue
} from "../chunk-UBWFVGJX.js";
import {
  stderr,
  stdout
} from "../chunk-ACQHDOFQ.js";
import {
  getHandler,
  throwInNextTick
} from "../chunk-E2J7JLFN.js";
import "../chunk-6LX4VMOV.js";

// src/entry/worker.ts
import {
  parentPort,
  receiveMessageOnPort,
  workerData as tinypoolData
} from "worker_threads";
var [tinypoolPrivateData, workerData] = tinypoolData;
process.__tinypool_state__ = {
  isWorkerThread: true,
  isTinypoolWorker: true,
  workerData,
  workerId: tinypoolPrivateData.workerId
};
var memoryUsage = process.memoryUsage.bind(process);
var useAtomics = process.env.PISCINA_DISABLE_ATOMICS !== "1";
parentPort.on("message", (message) => {
  useAtomics = process.env.PISCINA_DISABLE_ATOMICS === "1" ? false : message.useAtomics;
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
        error: null,
        usedMemory: memoryUsage().heapUsed
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
        // It may be worth taking a look at the error cloning algorithm we
        // use in Node.js core here, it's quite a bit more flexible
        error,
        usedMemory: memoryUsage().heapUsed
      };
    }
    currentTasks--;
    port.postMessage(response, transferList);
    Atomics.add(sharedBuffer, kResponseCountField, 1);
    atomicsWaitLoop(port, sharedBuffer);
  })().catch(throwInNextTick);
}

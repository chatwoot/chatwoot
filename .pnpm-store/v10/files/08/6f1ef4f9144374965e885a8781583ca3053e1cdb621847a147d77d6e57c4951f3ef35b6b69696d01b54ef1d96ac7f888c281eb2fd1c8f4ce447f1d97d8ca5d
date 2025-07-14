"use strict";
import {
  __dirname,
  __privateAdd,
  __privateGet,
  __privateSet,
  __publicField,
  isMovable,
  isTaskQueue,
  isTransferable,
  kFieldCount,
  kQueueOptions,
  kRequestCountField,
  kResponseCountField,
  kTransferable,
  kValue,
  markMovable
} from "./chunk-QYFJIXNO.js";

// src/index.ts
import {
  Worker,
  MessageChannel,
  receiveMessageOnPort,
  parentPort
} from "worker_threads";
import { once } from "events";

// src/EventEmitterAsyncResource.ts
import { EventEmitter } from "events";
import { AsyncResource } from "async_hooks";
var kEventEmitter = Symbol("kEventEmitter");
var kAsyncResource = Symbol("kAsyncResource");
var _a;
var EventEmitterReferencingAsyncResource = class extends AsyncResource {
  constructor(ee, type, options) {
    super(type, options);
    __publicField(this, _a);
    this[kEventEmitter] = ee;
  }
  get eventEmitter() {
    return this[kEventEmitter];
  }
};
_a = kEventEmitter;
var _a2;
var _EventEmitterAsyncResource = class extends EventEmitter {
  constructor(options) {
    let name;
    if (typeof options === "string") {
      name = options;
      options = void 0;
    } else {
      name = options?.name || new.target.name;
    }
    super(options);
    __publicField(this, _a2);
    this[kAsyncResource] = new EventEmitterReferencingAsyncResource(this, name, options);
  }
  emit(event, ...args) {
    return this.asyncResource.runInAsyncScope(super.emit, this, event, ...args);
  }
  emitDestroy() {
    this.asyncResource.emitDestroy();
  }
  asyncId() {
    return this.asyncResource.asyncId();
  }
  triggerAsyncId() {
    return this.asyncResource.triggerAsyncId();
  }
  get asyncResource() {
    return this[kAsyncResource];
  }
  static get EventEmitterAsyncResource() {
    return _EventEmitterAsyncResource;
  }
};
var EventEmitterAsyncResource = _EventEmitterAsyncResource;
_a2 = kAsyncResource;
var EventEmitterAsyncResource_default = EventEmitterAsyncResource;

// src/index.ts
import { AsyncResource as AsyncResource2 } from "async_hooks";
import { fileURLToPath, URL } from "url";
import { dirname, join, resolve } from "path";
import { inspect, types } from "util";
import assert from "assert";
import { performance } from "perf_hooks";
import { readFileSync } from "fs";

// src/physicalCpuCount.ts
import os from "os";
import childProcess from "child_process";
function exec(command) {
  const output = childProcess.execSync(command, {
    encoding: "utf8",
    stdio: [null, null, null]
  });
  return output;
}
var amount;
try {
  const platform = os.platform();
  if (platform === "linux") {
    const output1 = exec('cat /proc/cpuinfo | grep "physical id" | sort |uniq | wc -l');
    const output2 = exec('cat /proc/cpuinfo | grep "core id" | sort | uniq | wc -l');
    const physicalCpuAmount = parseInt(output1.trim(), 10);
    const physicalCoreAmount = parseInt(output2.trim(), 10);
    amount = physicalCpuAmount * physicalCoreAmount;
  } else if (platform === "darwin") {
    const output = exec("sysctl -n hw.physicalcpu_max");
    amount = parseInt(output.trim(), 10);
  } else if (platform === "win32") {
    throw new Error();
  } else {
    const cores = os.cpus().filter(function(cpu, index) {
      const hasHyperthreading = cpu.model.includes("Intel");
      const isOdd = index % 2 === 1;
      return !hasHyperthreading || isOdd;
    });
    amount = cores.length;
  }
} catch {
  amount = os.cpus().length;
}

// src/index.ts
var cpuCount = amount;
function onabort(abortSignal, listener) {
  if ("addEventListener" in abortSignal) {
    abortSignal.addEventListener("abort", listener, { once: true });
  } else {
    abortSignal.once("abort", listener);
  }
}
var AbortError = class extends Error {
  constructor() {
    super("The task has been aborted");
  }
  get name() {
    return "AbortError";
  }
};
var ArrayTaskQueue = class {
  constructor() {
    __publicField(this, "tasks", []);
  }
  get size() {
    return this.tasks.length;
  }
  shift() {
    return this.tasks.shift();
  }
  push(task) {
    this.tasks.push(task);
  }
  remove(task) {
    const index = this.tasks.indexOf(task);
    assert.notStrictEqual(index, -1);
    this.tasks.splice(index, 1);
  }
};
var kDefaultOptions = {
  filename: null,
  name: "default",
  minThreads: Math.max(cpuCount / 2, 1),
  maxThreads: cpuCount,
  idleTimeout: 0,
  maxQueue: Infinity,
  concurrentTasksPerWorker: 1,
  useAtomics: true,
  taskQueue: new ArrayTaskQueue(),
  trackUnmanagedFds: true
};
var kDefaultRunOptions = {
  transferList: void 0,
  filename: null,
  signal: null,
  name: null
};
var _value;
var DirectlyTransferable = class {
  constructor(value) {
    __privateAdd(this, _value, void 0);
    __privateSet(this, _value, value);
  }
  get [kTransferable]() {
    return __privateGet(this, _value);
  }
  get [kValue]() {
    return __privateGet(this, _value);
  }
};
_value = new WeakMap();
var _view;
var ArrayBufferViewTransferable = class {
  constructor(view) {
    __privateAdd(this, _view, void 0);
    __privateSet(this, _view, view);
  }
  get [kTransferable]() {
    return __privateGet(this, _view).buffer;
  }
  get [kValue]() {
    return __privateGet(this, _view);
  }
};
_view = new WeakMap();
var taskIdCounter = 0;
function maybeFileURLToPath(filename) {
  return filename.startsWith("file:") ? fileURLToPath(new URL(filename)) : filename;
}
var TaskInfo = class extends AsyncResource2 {
  constructor(task, transferList, filename, name, callback, abortSignal, triggerAsyncId) {
    super("Tinypool.Task", { requireManualDestroy: true, triggerAsyncId });
    __publicField(this, "callback");
    __publicField(this, "task");
    __publicField(this, "transferList");
    __publicField(this, "filename");
    __publicField(this, "name");
    __publicField(this, "taskId");
    __publicField(this, "abortSignal");
    __publicField(this, "abortListener", null);
    __publicField(this, "workerInfo", null);
    __publicField(this, "created");
    __publicField(this, "started");
    this.callback = callback;
    this.task = task;
    this.transferList = transferList;
    if (isMovable(task)) {
      if (this.transferList == null) {
        this.transferList = [];
      }
      this.transferList = this.transferList.concat(task[kTransferable]);
      this.task = task[kValue];
    }
    this.filename = filename;
    this.name = name;
    this.taskId = taskIdCounter++;
    this.abortSignal = abortSignal;
    this.created = performance.now();
    this.started = 0;
  }
  releaseTask() {
    const ret = this.task;
    this.task = null;
    return ret;
  }
  done(err, result) {
    this.emitDestroy();
    this.runInAsyncScope(this.callback, null, err, result);
    if (this.abortSignal && this.abortListener) {
      if ("removeEventListener" in this.abortSignal && this.abortListener) {
        this.abortSignal.removeEventListener("abort", this.abortListener);
      } else {
        ;
        this.abortSignal.off("abort", this.abortListener);
      }
    }
  }
  get [kQueueOptions]() {
    return kQueueOptions in this.task ? this.task[kQueueOptions] : null;
  }
};
var AsynchronouslyCreatedResource = class {
  constructor() {
    __publicField(this, "onreadyListeners", []);
  }
  markAsReady() {
    const listeners = this.onreadyListeners;
    assert(listeners !== null);
    this.onreadyListeners = null;
    for (const listener of listeners) {
      listener();
    }
  }
  isReady() {
    return this.onreadyListeners === null;
  }
  onReady(fn) {
    if (this.onreadyListeners === null) {
      fn();
      return;
    }
    this.onreadyListeners.push(fn);
  }
};
var AsynchronouslyCreatedResourcePool = class {
  constructor(maximumUsage) {
    __publicField(this, "pendingItems", /* @__PURE__ */ new Set());
    __publicField(this, "readyItems", /* @__PURE__ */ new Set());
    __publicField(this, "maximumUsage");
    __publicField(this, "onAvailableListeners");
    this.maximumUsage = maximumUsage;
    this.onAvailableListeners = [];
  }
  add(item) {
    this.pendingItems.add(item);
    item.onReady(() => {
      if (this.pendingItems.has(item)) {
        this.pendingItems.delete(item);
        this.readyItems.add(item);
        this.maybeAvailable(item);
      }
    });
  }
  delete(item) {
    this.pendingItems.delete(item);
    this.readyItems.delete(item);
  }
  findAvailable() {
    let minUsage = this.maximumUsage;
    let candidate = null;
    for (const item of this.readyItems) {
      const usage = item.currentUsage();
      if (usage === 0)
        return item;
      if (usage < minUsage) {
        candidate = item;
        minUsage = usage;
      }
    }
    return candidate;
  }
  *[Symbol.iterator]() {
    yield* this.pendingItems;
    yield* this.readyItems;
  }
  get size() {
    return this.pendingItems.size + this.readyItems.size;
  }
  maybeAvailable(item) {
    if (item.currentUsage() < this.maximumUsage) {
      for (const listener of this.onAvailableListeners) {
        listener(item);
      }
    }
  }
  onAvailable(fn) {
    this.onAvailableListeners.push(fn);
  }
};
var Errors = {
  ThreadTermination: () => new Error("Terminating worker thread"),
  FilenameNotProvided: () => new Error("filename must be provided to run() or in options object"),
  TaskQueueAtLimit: () => new Error("Task queue is at limit"),
  NoTaskQueueAvailable: () => new Error("No task queue available and all Workers are busy")
};
var WorkerInfo = class extends AsynchronouslyCreatedResource {
  constructor(worker, port, workerId, freeWorkerId, onMessage) {
    super();
    __publicField(this, "worker");
    __publicField(this, "workerId");
    __publicField(this, "freeWorkerId");
    __publicField(this, "taskInfos");
    __publicField(this, "idleTimeout", null);
    __publicField(this, "port");
    __publicField(this, "sharedBuffer");
    __publicField(this, "lastSeenResponseCount", 0);
    __publicField(this, "onMessage");
    this.worker = worker;
    this.workerId = workerId;
    this.freeWorkerId = freeWorkerId;
    this.port = port;
    this.port.on("message", (message) => this._handleResponse(message));
    this.onMessage = onMessage;
    this.taskInfos = /* @__PURE__ */ new Map();
    this.sharedBuffer = new Int32Array(new SharedArrayBuffer(kFieldCount * Int32Array.BYTES_PER_ELEMENT));
  }
  async destroy() {
    await this.worker.terminate();
    this.port.close();
    this.clearIdleTimeout();
    for (const taskInfo of this.taskInfos.values()) {
      taskInfo.done(Errors.ThreadTermination());
    }
    this.taskInfos.clear();
  }
  clearIdleTimeout() {
    if (this.idleTimeout !== null) {
      clearTimeout(this.idleTimeout);
      this.idleTimeout = null;
    }
  }
  ref() {
    this.port.ref();
    return this;
  }
  unref() {
    this.port.unref();
    return this;
  }
  _handleResponse(message) {
    this.onMessage(message);
    if (this.taskInfos.size === 0) {
      this.unref();
    }
  }
  postTask(taskInfo) {
    assert(!this.taskInfos.has(taskInfo.taskId));
    const message = {
      task: taskInfo.releaseTask(),
      taskId: taskInfo.taskId,
      filename: taskInfo.filename,
      name: taskInfo.name
    };
    try {
      this.port.postMessage(message, taskInfo.transferList);
    } catch (err) {
      taskInfo.done(err);
      return;
    }
    taskInfo.workerInfo = this;
    this.taskInfos.set(taskInfo.taskId, taskInfo);
    this.ref();
    this.clearIdleTimeout();
    Atomics.add(this.sharedBuffer, kRequestCountField, 1);
    Atomics.notify(this.sharedBuffer, kRequestCountField, 1);
  }
  processPendingMessages() {
    const actualResponseCount = Atomics.load(this.sharedBuffer, kResponseCountField);
    if (actualResponseCount !== this.lastSeenResponseCount) {
      this.lastSeenResponseCount = actualResponseCount;
      let entry;
      while ((entry = receiveMessageOnPort(this.port)) !== void 0) {
        this._handleResponse(entry.message);
      }
    }
  }
  isRunningAbortableTask() {
    if (this.taskInfos.size !== 1)
      return false;
    const [[, task]] = this.taskInfos;
    return task.abortSignal !== null;
  }
  currentUsage() {
    if (this.isRunningAbortableTask())
      return Infinity;
    return this.taskInfos.size;
  }
};
var ThreadPool = class {
  constructor(publicInterface, options) {
    __publicField(this, "publicInterface");
    __publicField(this, "workers");
    __publicField(this, "workerIds");
    __publicField(this, "options");
    __publicField(this, "taskQueue");
    __publicField(this, "skipQueue", []);
    __publicField(this, "completed", 0);
    __publicField(this, "start", performance.now());
    __publicField(this, "inProcessPendingMessages", false);
    __publicField(this, "startingUp", false);
    __publicField(this, "workerFailsDuringBootstrap", false);
    this.publicInterface = publicInterface;
    this.taskQueue = options.taskQueue || new ArrayTaskQueue();
    const filename = options.filename ? maybeFileURLToPath(options.filename) : null;
    this.options = { ...kDefaultOptions, ...options, filename, maxQueue: 0 };
    if (options.maxThreads !== void 0 && this.options.minThreads >= options.maxThreads) {
      this.options.minThreads = options.maxThreads;
    }
    if (options.minThreads !== void 0 && this.options.maxThreads <= options.minThreads) {
      this.options.maxThreads = options.minThreads;
    }
    if (options.maxQueue === "auto") {
      this.options.maxQueue = this.options.maxThreads ** 2;
    } else {
      this.options.maxQueue = options.maxQueue ?? kDefaultOptions.maxQueue;
    }
    this.workerIds = new Map(new Array(this.options.maxThreads).fill(0).map((_, i) => [i + 1, true]));
    this.workers = new AsynchronouslyCreatedResourcePool(this.options.concurrentTasksPerWorker);
    this.workers.onAvailable((w) => this._onWorkerAvailable(w));
    this.startingUp = true;
    this._ensureMinimumWorkers();
    this.startingUp = false;
  }
  _ensureEnoughWorkersForTaskQueue() {
    while (this.workers.size < this.taskQueue.size && this.workers.size < this.options.maxThreads) {
      this._addNewWorker();
    }
  }
  _ensureMaximumWorkers() {
    while (this.workers.size < this.options.maxThreads) {
      this._addNewWorker();
    }
  }
  _ensureMinimumWorkers() {
    while (this.workers.size < this.options.minThreads) {
      this._addNewWorker();
    }
  }
  _addNewWorker() {
    const pool = this;
    const workerIds = this.workerIds;
    const __dirname2 = dirname(fileURLToPath(import.meta.url));
    let workerId;
    workerIds.forEach((isIdAvailable, _workerId2) => {
      if (isIdAvailable && !workerId) {
        workerId = _workerId2;
        workerIds.set(_workerId2, false);
      }
    });
    const tinypoolPrivateData = { workerId };
    const worker = new Worker(resolve(__dirname2, "./worker.js"), {
      env: this.options.env,
      argv: this.options.argv,
      execArgv: this.options.execArgv,
      resourceLimits: this.options.resourceLimits,
      workerData: [
        tinypoolPrivateData,
        this.options.workerData
      ],
      trackUnmanagedFds: this.options.trackUnmanagedFds
    });
    const onMessage = (message2) => {
      const { taskId, result } = message2;
      const taskInfo = workerInfo.taskInfos.get(taskId);
      workerInfo.taskInfos.delete(taskId);
      if (!this.options.isolateWorkers)
        pool.workers.maybeAvailable(workerInfo);
      if (taskInfo === void 0) {
        const err = new Error(`Unexpected message from Worker: ${inspect(message2)}`);
        pool.publicInterface.emit("error", err);
      } else {
        taskInfo.done(message2.error, result);
      }
      pool._processPendingMessages();
    };
    const { port1, port2 } = new MessageChannel();
    const workerInfo = new WorkerInfo(worker, port1, workerId, () => workerIds.set(workerId, true), onMessage);
    if (this.startingUp) {
      workerInfo.markAsReady();
    }
    const message = {
      tinypoolStartupMessage: true,
      filename: this.options.filename,
      name: this.options.name,
      port: port2,
      sharedBuffer: workerInfo.sharedBuffer,
      useAtomics: this.options.useAtomics
    };
    worker.postMessage(message, [port2]);
    worker.on("message", (message2) => {
      if (message2.ready === true) {
        if (workerInfo.currentUsage() === 0) {
          workerInfo.unref();
        }
        if (!workerInfo.isReady()) {
          workerInfo.markAsReady();
        }
        return;
      }
      worker.emit("error", new Error(`Unexpected message on Worker: ${inspect(message2)}`));
    });
    worker.on("error", (err) => {
      worker.ref = () => {
      };
      const taskInfos = [...workerInfo.taskInfos.values()];
      workerInfo.taskInfos.clear();
      this._removeWorker(workerInfo);
      if (workerInfo.isReady() && !this.workerFailsDuringBootstrap) {
        this._ensureMinimumWorkers();
      } else {
        this.workerFailsDuringBootstrap = true;
      }
      if (taskInfos.length > 0) {
        for (const taskInfo of taskInfos) {
          taskInfo.done(err, null);
        }
      } else {
        this.publicInterface.emit("error", err);
      }
    });
    worker.unref();
    port1.on("close", () => {
      worker.ref();
    });
    this.workers.add(workerInfo);
  }
  _processPendingMessages() {
    if (this.inProcessPendingMessages || !this.options.useAtomics) {
      return;
    }
    this.inProcessPendingMessages = true;
    try {
      for (const workerInfo of this.workers) {
        workerInfo.processPendingMessages();
      }
    } finally {
      this.inProcessPendingMessages = false;
    }
  }
  _removeWorker(workerInfo) {
    workerInfo.freeWorkerId();
    workerInfo.destroy();
    this.workers.delete(workerInfo);
  }
  _onWorkerAvailable(workerInfo) {
    while ((this.taskQueue.size > 0 || this.skipQueue.length > 0) && workerInfo.currentUsage() < this.options.concurrentTasksPerWorker) {
      const taskInfo = this.skipQueue.shift() || this.taskQueue.shift();
      if (taskInfo.abortSignal && workerInfo.taskInfos.size > 0) {
        this.skipQueue.push(taskInfo);
        break;
      }
      const now = performance.now();
      taskInfo.started = now;
      workerInfo.postTask(taskInfo);
      this._maybeDrain();
      return;
    }
    if (workerInfo.taskInfos.size === 0 && this.workers.size > this.options.minThreads) {
      workerInfo.idleTimeout = setTimeout(() => {
        assert.strictEqual(workerInfo.taskInfos.size, 0);
        if (this.workers.size > this.options.minThreads) {
          this._removeWorker(workerInfo);
        }
      }, this.options.idleTimeout).unref();
    }
  }
  runTask(task, options) {
    let { filename, name } = options;
    const { transferList = [], signal = null } = options;
    if (filename == null) {
      filename = this.options.filename;
    }
    if (name == null) {
      name = this.options.name;
    }
    if (typeof filename !== "string") {
      return Promise.reject(Errors.FilenameNotProvided());
    }
    filename = maybeFileURLToPath(filename);
    let resolve2;
    let reject;
    const ret = new Promise((res, rej) => {
      resolve2 = res;
      reject = rej;
    });
    const taskInfo = new TaskInfo(task, transferList, filename, name, (err, result) => {
      this.completed++;
      if (err !== null) {
        reject(err);
      } else {
        resolve2(result);
      }
      if (this.options.isolateWorkers && taskInfo.workerInfo) {
        this._removeWorker(taskInfo.workerInfo);
        this._ensureEnoughWorkersForTaskQueue();
      }
    }, signal, this.publicInterface.asyncResource.asyncId());
    if (signal !== null) {
      if (signal.aborted) {
        return Promise.reject(new AbortError());
      }
      taskInfo.abortListener = () => {
        reject(new AbortError());
        if (taskInfo.workerInfo !== null) {
          this._removeWorker(taskInfo.workerInfo);
          this._ensureMinimumWorkers();
        } else {
          this.taskQueue.remove(taskInfo);
        }
      };
      onabort(signal, taskInfo.abortListener);
    }
    if (this.taskQueue.size > 0) {
      const totalCapacity = this.options.maxQueue + this.pendingCapacity();
      if (this.taskQueue.size >= totalCapacity) {
        if (this.options.maxQueue === 0) {
          return Promise.reject(Errors.NoTaskQueueAvailable());
        } else {
          return Promise.reject(Errors.TaskQueueAtLimit());
        }
      } else {
        if (this.workers.size < this.options.maxThreads) {
          this._addNewWorker();
        }
        this.taskQueue.push(taskInfo);
      }
      return ret;
    }
    let workerInfo = this.workers.findAvailable();
    if (workerInfo !== null && workerInfo.currentUsage() > 0 && signal) {
      workerInfo = null;
    }
    let waitingForNewWorker = false;
    if ((workerInfo === null || workerInfo.currentUsage() > 0) && this.workers.size < this.options.maxThreads) {
      this._addNewWorker();
      waitingForNewWorker = true;
    }
    if (workerInfo === null) {
      if (this.options.maxQueue <= 0 && !waitingForNewWorker) {
        return Promise.reject(Errors.NoTaskQueueAvailable());
      } else {
        this.taskQueue.push(taskInfo);
      }
      return ret;
    }
    const now = performance.now();
    taskInfo.started = now;
    workerInfo.postTask(taskInfo);
    this._maybeDrain();
    return ret;
  }
  pendingCapacity() {
    return this.workers.pendingItems.size * this.options.concurrentTasksPerWorker;
  }
  _maybeDrain() {
    if (this.taskQueue.size === 0 && this.skipQueue.length === 0) {
      this.publicInterface.emit("drain");
    }
  }
  async destroy() {
    while (this.skipQueue.length > 0) {
      const taskInfo = this.skipQueue.shift();
      taskInfo.done(new Error("Terminating worker thread"));
    }
    while (this.taskQueue.size > 0) {
      const taskInfo = this.taskQueue.shift();
      taskInfo.done(new Error("Terminating worker thread"));
    }
    const exitEvents = [];
    while (this.workers.size > 0) {
      const [workerInfo] = this.workers;
      exitEvents.push(once(workerInfo.worker, "exit"));
      this._removeWorker(workerInfo);
    }
    await Promise.all(exitEvents);
  }
};
var _pool;
var Tinypool = class extends EventEmitterAsyncResource_default {
  constructor(options = {}) {
    if (options.minThreads !== void 0 && options.minThreads > 0 && options.minThreads < 1) {
      options.minThreads = Math.max(1, Math.floor(options.minThreads * cpuCount));
    }
    if (options.maxThreads !== void 0 && options.maxThreads > 0 && options.maxThreads < 1) {
      options.maxThreads = Math.max(1, Math.floor(options.maxThreads * cpuCount));
    }
    super({ ...options, name: "Tinypool" });
    __privateAdd(this, _pool, void 0);
    if (options.minThreads !== void 0 && options.maxThreads !== void 0 && options.minThreads > options.maxThreads) {
      throw new RangeError("options.minThreads and options.maxThreads must not conflict");
    }
    __privateSet(this, _pool, new ThreadPool(this, options));
  }
  run(task, options = kDefaultRunOptions) {
    const { transferList, filename, name, signal } = options;
    return __privateGet(this, _pool).runTask(task, { transferList, filename, name, signal });
  }
  broadcastMessage(message) {
    for (const workerInfo of __privateGet(this, _pool).workers) {
      workerInfo.worker.postMessage(message);
    }
  }
  destroy() {
    return __privateGet(this, _pool).destroy();
  }
  get options() {
    return __privateGet(this, _pool).options;
  }
  get threads() {
    const ret = [];
    for (const workerInfo of __privateGet(this, _pool).workers) {
      ret.push(workerInfo.worker);
    }
    return ret;
  }
  get queueSize() {
    const pool = __privateGet(this, _pool);
    return Math.max(pool.taskQueue.size - pool.pendingCapacity(), 0);
  }
  get completed() {
    return __privateGet(this, _pool).completed;
  }
  get duration() {
    return performance.now() - __privateGet(this, _pool).start;
  }
  static get isWorkerThread() {
    return process.__tinypool_state__?.isWorkerThread || false;
  }
  static get workerData() {
    return process.__tinypool_state__?.workerData || void 0;
  }
  static get version() {
    const { version } = JSON.parse(readFileSync(join(__dirname, "../package.json"), "utf-8"));
    return version;
  }
  static move(val) {
    if (val != null && typeof val === "object" && typeof val !== "function") {
      if (!isTransferable(val)) {
        if (types.isArrayBufferView(val)) {
          val = new ArrayBufferViewTransferable(val);
        } else {
          val = new DirectlyTransferable(val);
        }
      }
      markMovable(val);
    }
    return val;
  }
  static get transferableSymbol() {
    return kTransferable;
  }
  static get valueSymbol() {
    return kValue;
  }
  static get queueOptionsSymbol() {
    return kQueueOptions;
  }
};
_pool = new WeakMap();
function onBroadcastedMessage(handler) {
  if (parentPort) {
    parentPort.on("message", handler);
  } else {
    throw new Error("onBroadcastedMessage can only be used in worker threads");
  }
}
var _workerId = process.__tinypool_state__?.workerId;
var src_default = Tinypool;
export {
  Tinypool,
  src_default as default,
  isMovable,
  isTaskQueue,
  isTransferable,
  kFieldCount,
  kQueueOptions,
  kRequestCountField,
  kResponseCountField,
  kTransferable,
  kValue,
  markMovable,
  onBroadcastedMessage,
  _workerId as workerId
};

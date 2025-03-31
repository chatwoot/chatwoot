import { getSafeTimers, isObject, createDefer, toArray, isNegativeNaN, format, objDisplay, objectAttr, assertTypes, shuffle } from '@vitest/utils';
import { parseSingleStack } from '@vitest/utils/source-map';
import { c as createChainable, b as createFileTask, a as calculateSuiteHash, s as someTasksAreOnly, i as interpretTaskModes, l as limitConcurrency, p as partitionSuiteChildren, o as hasTests, n as hasFailed } from './chunk-tasks.js';
import { processError } from '@vitest/utils/error';
export { processError } from '@vitest/utils/error';
import 'pathe';

class PendingError extends Error {
  constructor(message, task, note) {
    super(message);
    this.message = message;
    this.note = note;
    this.taskId = task.id;
  }
  code = "VITEST_PENDING";
  taskId;
}

const now$2 = Date.now;
const collectorContext = {
  tasks: [],
  currentSuite: null
};
function collectTask(task) {
  var _a;
  (_a = collectorContext.currentSuite) == null ? undefined : _a.tasks.push(task);
}
async function runWithSuite(suite, fn) {
  const prev = collectorContext.currentSuite;
  collectorContext.currentSuite = suite;
  await fn();
  collectorContext.currentSuite = prev;
}
function withTimeout(fn, timeout, isHook = false) {
  if (timeout <= 0 || timeout === Number.POSITIVE_INFINITY) {
    return fn;
  }
  const { setTimeout, clearTimeout } = getSafeTimers();
  return function runWithTimeout(...args) {
    const startTime = now$2();
    return new Promise((resolve_, reject_) => {
      var _a;
      const timer = setTimeout(() => {
        clearTimeout(timer);
        reject(new Error(makeTimeoutMsg(isHook, timeout)));
      }, timeout);
      (_a = timer.unref) == null ? undefined : _a.call(timer);
      function resolve(result) {
        clearTimeout(timer);
        if (now$2() - startTime >= timeout) {
          reject_(new Error(makeTimeoutMsg(isHook, timeout)));
          return;
        }
        resolve_(result);
      }
      function reject(error) {
        clearTimeout(timer);
        reject_(error);
      }
      try {
        const result = fn(...args);
        if (typeof result === "object" && result != null && typeof result.then === "function") {
          result.then(resolve, reject);
        } else {
          resolve(result);
        }
      } catch (error) {
        reject(error);
      }
    });
  };
}
function createTestContext(test, runner) {
  var _a;
  const context = function() {
    throw new Error("done() callback is deprecated, use promise instead");
  };
  context.task = test;
  context.skip = (note) => {
    test.result ?? (test.result = { state: "skip" });
    test.result.pending = true;
    throw new PendingError("test is skipped; abort execution", test, note);
  };
  context.onTestFailed = (handler, timeout) => {
    test.onFailed || (test.onFailed = []);
    test.onFailed.push(
      withTimeout(handler, timeout ?? runner.config.hookTimeout, true)
    );
  };
  context.onTestFinished = (handler, timeout) => {
    test.onFinished || (test.onFinished = []);
    test.onFinished.push(
      withTimeout(handler, timeout ?? runner.config.hookTimeout, true)
    );
  };
  return ((_a = runner.extendTaskContext) == null ? undefined : _a.call(runner, context)) || context;
}
function makeTimeoutMsg(isHook, timeout) {
  return `${isHook ? "Hook" : "Test"} timed out in ${timeout}ms.
If this is a long-running ${isHook ? "hook" : "test"}, pass a timeout value as the last argument or configure it globally with "${isHook ? "hookTimeout" : "testTimeout"}".`;
}

const fnMap = /* @__PURE__ */ new WeakMap();
const fixtureMap = /* @__PURE__ */ new WeakMap();
const hooksMap = /* @__PURE__ */ new WeakMap();
function setFn(key, fn) {
  fnMap.set(key, fn);
}
function getFn(key) {
  return fnMap.get(key);
}
function setFixture(key, fixture) {
  fixtureMap.set(key, fixture);
}
function getFixture(key) {
  return fixtureMap.get(key);
}
function setHooks(key, hooks) {
  hooksMap.set(key, hooks);
}
function getHooks(key) {
  return hooksMap.get(key);
}

function mergeContextFixtures(fixtures, context, inject) {
  const fixtureOptionKeys = ["auto", "injected"];
  const fixtureArray = Object.entries(fixtures).map(
    ([prop, value]) => {
      const fixtureItem = { value };
      if (Array.isArray(value) && value.length >= 2 && isObject(value[1]) && Object.keys(value[1]).some((key) => fixtureOptionKeys.includes(key))) {
        Object.assign(fixtureItem, value[1]);
        const userValue = value[0];
        fixtureItem.value = fixtureItem.injected ? inject(prop) ?? userValue : userValue;
      }
      fixtureItem.prop = prop;
      fixtureItem.isFn = typeof fixtureItem.value === "function";
      return fixtureItem;
    }
  );
  if (Array.isArray(context.fixtures)) {
    context.fixtures = context.fixtures.concat(fixtureArray);
  } else {
    context.fixtures = fixtureArray;
  }
  fixtureArray.forEach((fixture) => {
    if (fixture.isFn) {
      const usedProps = getUsedProps(fixture.value);
      if (usedProps.length) {
        fixture.deps = context.fixtures.filter(
          ({ prop }) => prop !== fixture.prop && usedProps.includes(prop)
        );
      }
    }
  });
  return context;
}
const fixtureValueMaps = /* @__PURE__ */ new Map();
const cleanupFnArrayMap = /* @__PURE__ */ new Map();
async function callFixtureCleanup(context) {
  const cleanupFnArray = cleanupFnArrayMap.get(context) ?? [];
  for (const cleanup of cleanupFnArray.reverse()) {
    await cleanup();
  }
  cleanupFnArrayMap.delete(context);
}
function withFixtures(fn, testContext) {
  return (hookContext) => {
    const context = hookContext || testContext;
    if (!context) {
      return fn({});
    }
    const fixtures = getFixture(context);
    if (!(fixtures == null ? undefined : fixtures.length)) {
      return fn(context);
    }
    const usedProps = getUsedProps(fn);
    const hasAutoFixture = fixtures.some(({ auto }) => auto);
    if (!usedProps.length && !hasAutoFixture) {
      return fn(context);
    }
    if (!fixtureValueMaps.get(context)) {
      fixtureValueMaps.set(context, /* @__PURE__ */ new Map());
    }
    const fixtureValueMap = fixtureValueMaps.get(context);
    if (!cleanupFnArrayMap.has(context)) {
      cleanupFnArrayMap.set(context, []);
    }
    const cleanupFnArray = cleanupFnArrayMap.get(context);
    const usedFixtures = fixtures.filter(
      ({ prop, auto }) => auto || usedProps.includes(prop)
    );
    const pendingFixtures = resolveDeps(usedFixtures);
    if (!pendingFixtures.length) {
      return fn(context);
    }
    async function resolveFixtures() {
      for (const fixture of pendingFixtures) {
        if (fixtureValueMap.has(fixture)) {
          continue;
        }
        const resolvedValue = fixture.isFn ? await resolveFixtureFunction(fixture.value, context, cleanupFnArray) : fixture.value;
        context[fixture.prop] = resolvedValue;
        fixtureValueMap.set(fixture, resolvedValue);
        cleanupFnArray.unshift(() => {
          fixtureValueMap.delete(fixture);
        });
      }
    }
    return resolveFixtures().then(() => fn(context));
  };
}
async function resolveFixtureFunction(fixtureFn, context, cleanupFnArray) {
  const useFnArgPromise = createDefer();
  let isUseFnArgResolved = false;
  const fixtureReturn = fixtureFn(context, async (useFnArg) => {
    isUseFnArgResolved = true;
    useFnArgPromise.resolve(useFnArg);
    const useReturnPromise = createDefer();
    cleanupFnArray.push(async () => {
      useReturnPromise.resolve();
      await fixtureReturn;
    });
    await useReturnPromise;
  }).catch((e) => {
    if (!isUseFnArgResolved) {
      useFnArgPromise.reject(e);
      return;
    }
    throw e;
  });
  return useFnArgPromise;
}
function resolveDeps(fixtures, depSet = /* @__PURE__ */ new Set(), pendingFixtures = []) {
  fixtures.forEach((fixture) => {
    if (pendingFixtures.includes(fixture)) {
      return;
    }
    if (!fixture.isFn || !fixture.deps) {
      pendingFixtures.push(fixture);
      return;
    }
    if (depSet.has(fixture)) {
      throw new Error(
        `Circular fixture dependency detected: ${fixture.prop} <- ${[...depSet].reverse().map((d) => d.prop).join(" <- ")}`
      );
    }
    depSet.add(fixture);
    resolveDeps(fixture.deps, depSet, pendingFixtures);
    pendingFixtures.push(fixture);
    depSet.clear();
  });
  return pendingFixtures;
}
function getUsedProps(fn) {
  let fnString = fn.toString();
  if (/__async\(this, (?:null|arguments|\[[_0-9, ]*\]), function\*/.test(fnString)) {
    fnString = fnString.split("__async(this,")[1];
  }
  const match = fnString.match(/[^(]*\(([^)]*)/);
  if (!match) {
    return [];
  }
  const args = splitByComma(match[1]);
  if (!args.length) {
    return [];
  }
  let first = args[0];
  if ("__VITEST_FIXTURE_INDEX__" in fn) {
    first = args[fn.__VITEST_FIXTURE_INDEX__];
    if (!first) {
      return [];
    }
  }
  if (!(first.startsWith("{") && first.endsWith("}"))) {
    throw new Error(
      `The first argument inside a fixture must use object destructuring pattern, e.g. ({ test } => {}). Instead, received "${first}".`
    );
  }
  const _first = first.slice(1, -1).replace(/\s/g, "");
  const props = splitByComma(_first).map((prop) => {
    return prop.replace(/:.*|=.*/g, "");
  });
  const last = props.at(-1);
  if (last && last.startsWith("...")) {
    throw new Error(
      `Rest parameters are not supported in fixtures, received "${last}".`
    );
  }
  return props;
}
function splitByComma(s) {
  const result = [];
  const stack = [];
  let start = 0;
  for (let i = 0; i < s.length; i++) {
    if (s[i] === "{" || s[i] === "[") {
      stack.push(s[i] === "{" ? "}" : "]");
    } else if (s[i] === stack[stack.length - 1]) {
      stack.pop();
    } else if (!stack.length && s[i] === ",") {
      const token = s.substring(start, i).trim();
      if (token) {
        result.push(token);
      }
      start = i + 1;
    }
  }
  const lastToken = s.substring(start).trim();
  if (lastToken) {
    result.push(lastToken);
  }
  return result;
}

let _test;
function setCurrentTest(test) {
  _test = test;
}
function getCurrentTest() {
  return _test;
}

const suite = createSuite();
const test = createTest(function(name, optionsOrFn, optionsOrTest) {
  if (getCurrentTest()) {
    throw new Error(
      'Calling the test function inside another test function is not allowed. Please put it inside "describe" or "suite" so it can be properly collected.'
    );
  }
  getCurrentSuite().test.fn.call(
    this,
    formatName(name),
    optionsOrFn,
    optionsOrTest
  );
});
const describe = suite;
const it = test;
let runner;
let defaultSuite;
let currentTestFilepath;
function assert(condition, message) {
  if (!condition) {
    throw new Error(`Vitest failed to find ${message}. This is a bug in Vitest. Please, open an issue with reproduction.`);
  }
}
function getDefaultSuite() {
  assert(defaultSuite, "the default suite");
  return defaultSuite;
}
function getTestFilepath() {
  return currentTestFilepath;
}
function getRunner() {
  assert(runner, "the runner");
  return runner;
}
function createDefaultSuite(runner2) {
  const config = runner2.config.sequence;
  return suite("", { concurrent: config.concurrent }, () => {
  });
}
function clearCollectorContext(filepath, currentRunner) {
  if (!defaultSuite) {
    defaultSuite = createDefaultSuite(currentRunner);
  }
  runner = currentRunner;
  currentTestFilepath = filepath;
  collectorContext.tasks.length = 0;
  defaultSuite.clear();
  collectorContext.currentSuite = defaultSuite;
}
function getCurrentSuite() {
  const currentSuite = collectorContext.currentSuite || defaultSuite;
  assert(currentSuite, "the current suite");
  return currentSuite;
}
function createSuiteHooks() {
  return {
    beforeAll: [],
    afterAll: [],
    beforeEach: [],
    afterEach: []
  };
}
function parseArguments(optionsOrFn, optionsOrTest) {
  let options = {};
  let fn = () => {
  };
  if (typeof optionsOrTest === "object") {
    if (typeof optionsOrFn === "object") {
      throw new TypeError(
        "Cannot use two objects as arguments. Please provide options and a function callback in that order."
      );
    }
    console.warn(
      "Using an object as a third argument is deprecated. Vitest 4 will throw an error if the third argument is not a timeout number. Please use the second argument for options. See more at https://vitest.dev/guide/migration"
    );
    options = optionsOrTest;
  } else if (typeof optionsOrTest === "number") {
    options = { timeout: optionsOrTest };
  } else if (typeof optionsOrFn === "object") {
    options = optionsOrFn;
  }
  if (typeof optionsOrFn === "function") {
    if (typeof optionsOrTest === "function") {
      throw new TypeError(
        "Cannot use two functions as arguments. Please use the second argument for options."
      );
    }
    fn = optionsOrFn;
  } else if (typeof optionsOrTest === "function") {
    fn = optionsOrTest;
  }
  return {
    options,
    handler: fn
  };
}
function createSuiteCollector(name, factory = () => {
}, mode, each, suiteOptions) {
  const tasks = [];
  const factoryQueue = [];
  let suite2;
  initSuite(true);
  const task = function(name2 = "", options = {}) {
    const task2 = {
      id: "",
      name: name2,
      suite: undefined,
      each: options.each,
      fails: options.fails,
      context: undefined,
      type: "test",
      file: undefined,
      retry: options.retry ?? runner.config.retry,
      repeats: options.repeats,
      mode: options.only ? "only" : options.skip ? "skip" : options.todo ? "todo" : "run",
      meta: options.meta ?? /* @__PURE__ */ Object.create(null)
    };
    const handler = options.handler;
    if (options.concurrent || !options.sequential && runner.config.sequence.concurrent) {
      task2.concurrent = true;
    }
    task2.shuffle = suiteOptions == null ? undefined : suiteOptions.shuffle;
    const context = createTestContext(task2, runner);
    Object.defineProperty(task2, "context", {
      value: context,
      enumerable: false
    });
    setFixture(context, options.fixtures);
    if (handler) {
      setFn(
        task2,
        withTimeout(
          withAwaitAsyncAssertions(withFixtures(handler, context), task2),
          (options == null ? undefined : options.timeout) ?? runner.config.testTimeout
        )
      );
    }
    if (runner.config.includeTaskLocation) {
      const limit = Error.stackTraceLimit;
      Error.stackTraceLimit = 15;
      const error = new Error("stacktrace").stack;
      Error.stackTraceLimit = limit;
      const stack = findTestFileStackTrace(error, task2.each ?? false);
      if (stack) {
        task2.location = stack;
      }
    }
    tasks.push(task2);
    return task2;
  };
  const test2 = createTest(function(name2, optionsOrFn, optionsOrTest) {
    let { options, handler } = parseArguments(optionsOrFn, optionsOrTest);
    if (typeof suiteOptions === "object") {
      options = Object.assign({}, suiteOptions, options);
    }
    options.concurrent = this.concurrent || !this.sequential && (options == null ? undefined : options.concurrent);
    options.sequential = this.sequential || !this.concurrent && (options == null ? undefined : options.sequential);
    const test3 = task(formatName(name2), {
      ...this,
      ...options,
      handler
    });
    test3.type = "test";
  });
  const collector = {
    type: "collector",
    name,
    mode,
    options: suiteOptions,
    test: test2,
    tasks,
    collect,
    task,
    clear,
    on: addHook
  };
  function addHook(name2, ...fn) {
    getHooks(suite2)[name2].push(...fn);
  }
  function initSuite(includeLocation) {
    if (typeof suiteOptions === "number") {
      suiteOptions = { timeout: suiteOptions };
    }
    suite2 = {
      id: "",
      type: "suite",
      name,
      mode,
      each,
      file: undefined,
      shuffle: suiteOptions == null ? undefined : suiteOptions.shuffle,
      tasks: [],
      meta: /* @__PURE__ */ Object.create(null),
      concurrent: suiteOptions == null ? undefined : suiteOptions.concurrent
    };
    if (runner && includeLocation && runner.config.includeTaskLocation) {
      const limit = Error.stackTraceLimit;
      Error.stackTraceLimit = 15;
      const error = new Error("stacktrace").stack;
      Error.stackTraceLimit = limit;
      const stack = findTestFileStackTrace(error, suite2.each ?? false);
      if (stack) {
        suite2.location = stack;
      }
    }
    setHooks(suite2, createSuiteHooks());
  }
  function clear() {
    tasks.length = 0;
    factoryQueue.length = 0;
    initSuite(false);
  }
  async function collect(file) {
    if (!file) {
      throw new TypeError("File is required to collect tasks.");
    }
    factoryQueue.length = 0;
    if (factory) {
      await runWithSuite(collector, () => factory(test2));
    }
    const allChildren = [];
    for (const i of [...factoryQueue, ...tasks]) {
      allChildren.push(i.type === "collector" ? await i.collect(file) : i);
    }
    suite2.file = file;
    suite2.tasks = allChildren;
    allChildren.forEach((task2) => {
      task2.suite = suite2;
      task2.file = file;
    });
    return suite2;
  }
  collectTask(collector);
  return collector;
}
function withAwaitAsyncAssertions(fn, task) {
  return async (...args) => {
    const fnResult = await fn(...args);
    if (task.promises) {
      const result = await Promise.allSettled(task.promises);
      const errors = result.map((r) => r.status === "rejected" ? r.reason : undefined).filter(Boolean);
      if (errors.length) {
        throw errors;
      }
    }
    return fnResult;
  };
}
function createSuite() {
  function suiteFn(name, factoryOrOptions, optionsOrFactory) {
    var _a;
    const mode = this.only ? "only" : this.skip ? "skip" : this.todo ? "todo" : "run";
    const currentSuite = collectorContext.currentSuite || defaultSuite;
    let { options, handler: factory } = parseArguments(
      factoryOrOptions,
      optionsOrFactory
    );
    const isConcurrentSpecified = options.concurrent || this.concurrent || options.sequential === false;
    const isSequentialSpecified = options.sequential || this.sequential || options.concurrent === false;
    options = {
      ...currentSuite == null ? undefined : currentSuite.options,
      ...options,
      shuffle: this.shuffle ?? options.shuffle ?? ((_a = currentSuite == null ? undefined : currentSuite.options) == null ? undefined : _a.shuffle) ?? (runner == null ? undefined : runner.config.sequence.shuffle)
    };
    const isConcurrent = isConcurrentSpecified || options.concurrent && !isSequentialSpecified;
    const isSequential = isSequentialSpecified || options.sequential && !isConcurrentSpecified;
    options.concurrent = isConcurrent && !isSequential;
    options.sequential = isSequential && !isConcurrent;
    return createSuiteCollector(
      formatName(name),
      factory,
      mode,
      this.each,
      options
    );
  }
  suiteFn.each = function(cases, ...args) {
    const suite2 = this.withContext();
    this.setContext("each", true);
    if (Array.isArray(cases) && args.length) {
      cases = formatTemplateString(cases, args);
    }
    return (name, optionsOrFn, fnOrOptions) => {
      const _name = formatName(name);
      const arrayOnlyCases = cases.every(Array.isArray);
      const { options, handler } = parseArguments(optionsOrFn, fnOrOptions);
      const fnFirst = typeof optionsOrFn === "function" && typeof fnOrOptions === "object";
      cases.forEach((i, idx) => {
        const items = Array.isArray(i) ? i : [i];
        if (fnFirst) {
          if (arrayOnlyCases) {
            suite2(
              formatTitle(_name, items, idx),
              () => handler(...items),
              options
            );
          } else {
            suite2(formatTitle(_name, items, idx), () => handler(i), options);
          }
        } else {
          if (arrayOnlyCases) {
            suite2(formatTitle(_name, items, idx), options, () => handler(...items));
          } else {
            suite2(formatTitle(_name, items, idx), options, () => handler(i));
          }
        }
      });
      this.setContext("each", undefined);
    };
  };
  suiteFn.for = function(cases, ...args) {
    if (Array.isArray(cases) && args.length) {
      cases = formatTemplateString(cases, args);
    }
    return (name, optionsOrFn, fnOrOptions) => {
      const name_ = formatName(name);
      const { options, handler } = parseArguments(optionsOrFn, fnOrOptions);
      cases.forEach((item, idx) => {
        suite(formatTitle(name_, toArray(item), idx), options, () => handler(item));
      });
    };
  };
  suiteFn.skipIf = (condition) => condition ? suite.skip : suite;
  suiteFn.runIf = (condition) => condition ? suite : suite.skip;
  return createChainable(
    ["concurrent", "sequential", "shuffle", "skip", "only", "todo"],
    suiteFn
  );
}
function createTaskCollector(fn, context) {
  const taskFn = fn;
  taskFn.each = function(cases, ...args) {
    const test2 = this.withContext();
    this.setContext("each", true);
    if (Array.isArray(cases) && args.length) {
      cases = formatTemplateString(cases, args);
    }
    return (name, optionsOrFn, fnOrOptions) => {
      const _name = formatName(name);
      const arrayOnlyCases = cases.every(Array.isArray);
      const { options, handler } = parseArguments(optionsOrFn, fnOrOptions);
      const fnFirst = typeof optionsOrFn === "function" && typeof fnOrOptions === "object";
      cases.forEach((i, idx) => {
        const items = Array.isArray(i) ? i : [i];
        if (fnFirst) {
          if (arrayOnlyCases) {
            test2(
              formatTitle(_name, items, idx),
              () => handler(...items),
              options
            );
          } else {
            test2(formatTitle(_name, items, idx), () => handler(i), options);
          }
        } else {
          if (arrayOnlyCases) {
            test2(formatTitle(_name, items, idx), options, () => handler(...items));
          } else {
            test2(formatTitle(_name, items, idx), options, () => handler(i));
          }
        }
      });
      this.setContext("each", undefined);
    };
  };
  taskFn.for = function(cases, ...args) {
    const test2 = this.withContext();
    if (Array.isArray(cases) && args.length) {
      cases = formatTemplateString(cases, args);
    }
    return (name, optionsOrFn, fnOrOptions) => {
      const _name = formatName(name);
      const { options, handler } = parseArguments(optionsOrFn, fnOrOptions);
      cases.forEach((item, idx) => {
        const handlerWrapper = (ctx) => handler(item, ctx);
        handlerWrapper.__VITEST_FIXTURE_INDEX__ = 1;
        handlerWrapper.toString = () => handler.toString();
        test2(formatTitle(_name, toArray(item), idx), options, handlerWrapper);
      });
    };
  };
  taskFn.skipIf = function(condition) {
    return condition ? this.skip : this;
  };
  taskFn.runIf = function(condition) {
    return condition ? this : this.skip;
  };
  taskFn.extend = function(fixtures) {
    const _context = mergeContextFixtures(
      fixtures,
      context || {},
      (key) => {
        var _a, _b;
        return (_b = (_a = getRunner()).injectValue) == null ? undefined : _b.call(_a, key);
      }
    );
    return createTest(function fn2(name, optionsOrFn, optionsOrTest) {
      getCurrentSuite().test.fn.call(
        this,
        formatName(name),
        optionsOrFn,
        optionsOrTest
      );
    }, _context);
  };
  const _test = createChainable(
    ["concurrent", "sequential", "skip", "only", "todo", "fails"],
    taskFn
  );
  if (context) {
    _test.mergeContext(context);
  }
  return _test;
}
function createTest(fn, context) {
  return createTaskCollector(fn, context);
}
function formatName(name) {
  return typeof name === "string" ? name : name instanceof Function ? name.name || "<anonymous>" : String(name);
}
function formatTitle(template, items, idx) {
  if (template.includes("%#")) {
    template = template.replace(/%%/g, "__vitest_escaped_%__").replace(/%#/g, `${idx}`).replace(/__vitest_escaped_%__/g, "%%");
  }
  const count = template.split("%").length - 1;
  if (template.includes("%f")) {
    const placeholders = template.match(/%f/g) || [];
    placeholders.forEach((_, i) => {
      if (isNegativeNaN(items[i]) || Object.is(items[i], -0)) {
        let occurrence = 0;
        template = template.replace(/%f/g, (match) => {
          occurrence++;
          return occurrence === i + 1 ? "-%f" : match;
        });
      }
    });
  }
  let formatted = format(template, ...items.slice(0, count));
  if (isObject(items[0])) {
    formatted = formatted.replace(
      /\$([$\w.]+)/g,
      // https://github.com/chaijs/chai/pull/1490
      (_, key) => {
        var _a, _b;
        return objDisplay(objectAttr(items[0], key), {
          truncate: (_b = (_a = runner == null ? undefined : runner.config) == null ? undefined : _a.chaiConfig) == null ? undefined : _b.truncateThreshold
        });
      }
    );
  }
  return formatted;
}
function formatTemplateString(cases, args) {
  const header = cases.join("").trim().replace(/ /g, "").split("\n").map((i) => i.split("|"))[0];
  const res = [];
  for (let i = 0; i < Math.floor(args.length / header.length); i++) {
    const oneCase = {};
    for (let j = 0; j < header.length; j++) {
      oneCase[header[j]] = args[i * header.length + j];
    }
    res.push(oneCase);
  }
  return res;
}
function findTestFileStackTrace(error, each) {
  const lines = error.split("\n").slice(1);
  for (const line of lines) {
    const stack = parseSingleStack(line);
    if (stack && stack.file === getTestFilepath()) {
      return {
        line: stack.line,
        /**
         * test.each([1, 2])('name')
         *                 ^ leads here, but should
         *                  ^ lead here
         * in source maps it's the same boundary, so it just points to the start of it
         */
        column: each ? stack.column + 1 : stack.column
      };
    }
  }
}

function getDefaultHookTimeout() {
  return getRunner().config.hookTimeout;
}
function beforeAll(fn, timeout) {
  assertTypes(fn, '"beforeAll" callback', ["function"]);
  return getCurrentSuite().on(
    "beforeAll",
    withTimeout(fn, timeout ?? getDefaultHookTimeout(), true)
  );
}
function afterAll(fn, timeout) {
  assertTypes(fn, '"afterAll" callback', ["function"]);
  return getCurrentSuite().on(
    "afterAll",
    withTimeout(fn, timeout ?? getDefaultHookTimeout(), true)
  );
}
function beforeEach(fn, timeout) {
  assertTypes(fn, '"beforeEach" callback', ["function"]);
  return getCurrentSuite().on(
    "beforeEach",
    withTimeout(withFixtures(fn), timeout ?? getDefaultHookTimeout(), true)
  );
}
function afterEach(fn, timeout) {
  assertTypes(fn, '"afterEach" callback', ["function"]);
  return getCurrentSuite().on(
    "afterEach",
    withTimeout(withFixtures(fn), timeout ?? getDefaultHookTimeout(), true)
  );
}
const onTestFailed = createTestHook(
  "onTestFailed",
  (test, handler, timeout) => {
    test.onFailed || (test.onFailed = []);
    test.onFailed.push(
      withTimeout(handler, timeout ?? getDefaultHookTimeout(), true)
    );
  }
);
const onTestFinished = createTestHook(
  "onTestFinished",
  (test, handler, timeout) => {
    test.onFinished || (test.onFinished = []);
    test.onFinished.push(
      withTimeout(handler, timeout ?? getDefaultHookTimeout(), true)
    );
  }
);
function createTestHook(name, handler) {
  return (fn, timeout) => {
    assertTypes(fn, `"${name}" callback`, ["function"]);
    const current = getCurrentTest();
    if (!current) {
      throw new Error(`Hook ${name}() can only be called inside a test`);
    }
    return handler(current, fn, timeout);
  };
}

async function runSetupFiles(config, files, runner) {
  if (config.sequence.setupFiles === "parallel") {
    await Promise.all(
      files.map(async (fsPath) => {
        await runner.importFile(fsPath, "setup");
      })
    );
  } else {
    for (const fsPath of files) {
      await runner.importFile(fsPath, "setup");
    }
  }
}

const now$1 = globalThis.performance ? globalThis.performance.now.bind(globalThis.performance) : Date.now;
async function collectTests(specs, runner) {
  var _a;
  const files = [];
  const config = runner.config;
  for (const spec of specs) {
    const filepath = typeof spec === "string" ? spec : spec.filepath;
    const testLocations = typeof spec === "string" ? undefined : spec.testLocations;
    const file = createFileTask(filepath, config.root, config.name, runner.pool);
    file.shuffle = config.sequence.shuffle;
    (_a = runner.onCollectStart) == null ? undefined : _a.call(runner, file);
    clearCollectorContext(filepath, runner);
    try {
      const setupFiles = toArray(config.setupFiles);
      if (setupFiles.length) {
        const setupStart = now$1();
        await runSetupFiles(config, setupFiles, runner);
        const setupEnd = now$1();
        file.setupDuration = setupEnd - setupStart;
      } else {
        file.setupDuration = 0;
      }
      const collectStart = now$1();
      await runner.importFile(filepath, "collect");
      const defaultTasks = await getDefaultSuite().collect(file);
      const fileHooks = createSuiteHooks();
      mergeHooks(fileHooks, getHooks(defaultTasks));
      for (const c of [...defaultTasks.tasks, ...collectorContext.tasks]) {
        if (c.type === "test" || c.type === "suite") {
          file.tasks.push(c);
        } else if (c.type === "collector") {
          const suite = await c.collect(file);
          if (suite.name || suite.tasks.length) {
            mergeHooks(fileHooks, getHooks(suite));
            file.tasks.push(suite);
          }
        } else {
          c;
        }
      }
      setHooks(file, fileHooks);
      file.collectDuration = now$1() - collectStart;
    } catch (e) {
      const error = processError(e);
      file.result = {
        state: "fail",
        errors: [error]
      };
    }
    calculateSuiteHash(file);
    file.tasks.forEach((task) => {
      var _a2;
      if (((_a2 = task.suite) == null ? undefined : _a2.id) === "") {
        delete task.suite;
      }
    });
    const hasOnlyTasks = someTasksAreOnly(file);
    interpretTaskModes(
      file,
      config.testNamePattern,
      testLocations,
      hasOnlyTasks,
      false,
      config.allowOnly
    );
    if (file.mode === "queued") {
      file.mode = "run";
    }
    files.push(file);
  }
  return files;
}
function mergeHooks(baseHooks, hooks) {
  for (const _key in hooks) {
    const key = _key;
    baseHooks[key].push(...hooks[key]);
  }
  return baseHooks;
}

const now = globalThis.performance ? globalThis.performance.now.bind(globalThis.performance) : Date.now;
const unixNow = Date.now;
function updateSuiteHookState(task, name, state, runner) {
  if (!task.result) {
    task.result = { state: "run" };
  }
  if (!task.result.hooks) {
    task.result.hooks = {};
  }
  const suiteHooks = task.result.hooks;
  if (suiteHooks) {
    suiteHooks[name] = state;
    let event = state === "run" ? "before-hook-start" : "before-hook-end";
    if (name === "afterAll" || name === "afterEach") {
      event = state === "run" ? "after-hook-start" : "after-hook-end";
    }
    updateTask(
      event,
      task,
      runner
    );
  }
}
function getSuiteHooks(suite, name, sequence) {
  const hooks = getHooks(suite)[name];
  if (sequence === "stack" && (name === "afterAll" || name === "afterEach")) {
    return hooks.slice().reverse();
  }
  return hooks;
}
async function callTestHooks(runner, test, hooks, sequence) {
  if (sequence === "stack") {
    hooks = hooks.slice().reverse();
  }
  if (!hooks.length) {
    return;
  }
  const onTestFailed = test.context.onTestFailed;
  const onTestFinished = test.context.onTestFinished;
  test.context.onTestFailed = () => {
    throw new Error(`Cannot call "onTestFailed" inside a test hook.`);
  };
  test.context.onTestFinished = () => {
    throw new Error(`Cannot call "onTestFinished" inside a test hook.`);
  };
  if (sequence === "parallel") {
    try {
      await Promise.all(hooks.map((fn) => fn(test.context)));
    } catch (e) {
      failTask(test.result, e, runner.config.diffOptions);
    }
  } else {
    for (const fn of hooks) {
      try {
        await fn(test.context);
      } catch (e) {
        failTask(test.result, e, runner.config.diffOptions);
      }
    }
  }
  test.context.onTestFailed = onTestFailed;
  test.context.onTestFinished = onTestFinished;
}
async function callSuiteHook(suite, currentTask, name, runner, args) {
  const sequence = runner.config.sequence.hooks;
  const callbacks = [];
  const parentSuite = "filepath" in suite ? null : suite.suite || suite.file;
  if (name === "beforeEach" && parentSuite) {
    callbacks.push(
      ...await callSuiteHook(parentSuite, currentTask, name, runner, args)
    );
  }
  const hooks = getSuiteHooks(suite, name, sequence);
  if (hooks.length > 0) {
    updateSuiteHookState(currentTask, name, "run", runner);
  }
  if (sequence === "parallel") {
    callbacks.push(
      ...await Promise.all(hooks.map((hook) => hook(...args)))
    );
  } else {
    for (const hook of hooks) {
      callbacks.push(await hook(...args));
    }
  }
  if (hooks.length > 0) {
    updateSuiteHookState(currentTask, name, "pass", runner);
  }
  if (name === "afterEach" && parentSuite) {
    callbacks.push(
      ...await callSuiteHook(parentSuite, currentTask, name, runner, args)
    );
  }
  return callbacks;
}
const packs = /* @__PURE__ */ new Map();
const eventsPacks = [];
let updateTimer;
let previousUpdate;
function updateTask(event, task, runner) {
  eventsPacks.push([task.id, event]);
  packs.set(task.id, [task.result, task.meta]);
  const { clearTimeout, setTimeout } = getSafeTimers();
  clearTimeout(updateTimer);
  updateTimer = setTimeout(() => {
    previousUpdate = sendTasksUpdate(runner);
  }, 10);
}
async function sendTasksUpdate(runner) {
  var _a;
  const { clearTimeout } = getSafeTimers();
  clearTimeout(updateTimer);
  await previousUpdate;
  if (packs.size) {
    const taskPacks = Array.from(packs).map(([id, task]) => {
      return [id, task[0], task[1]];
    });
    const p = (_a = runner.onTaskUpdate) == null ? undefined : _a.call(runner, taskPacks, eventsPacks);
    eventsPacks.length = 0;
    packs.clear();
    return p;
  }
}
async function callCleanupHooks(cleanups) {
  await Promise.all(
    cleanups.map(async (fn) => {
      if (typeof fn !== "function") {
        return;
      }
      await fn();
    })
  );
}
async function runTest(test, runner) {
  var _a, _b, _c, _d, _e, _f, _g, _h, _i;
  await ((_a = runner.onBeforeRunTask) == null ? undefined : _a.call(runner, test));
  if (test.mode !== "run" && test.mode !== "queued") {
    return;
  }
  if (((_b = test.result) == null ? undefined : _b.state) === "fail") {
    updateTask("test-failed-early", test, runner);
    return;
  }
  const start = now();
  test.result = {
    state: "run",
    startTime: unixNow(),
    retryCount: 0
  };
  updateTask("test-prepare", test, runner);
  setCurrentTest(test);
  const suite = test.suite || test.file;
  const repeats = test.repeats ?? 0;
  for (let repeatCount = 0; repeatCount <= repeats; repeatCount++) {
    const retry = test.retry ?? 0;
    for (let retryCount = 0; retryCount <= retry; retryCount++) {
      let beforeEachCleanups = [];
      try {
        await ((_c = runner.onBeforeTryTask) == null ? void 0 : _c.call(runner, test, {
          retry: retryCount,
          repeats: repeatCount
        }));
        test.result.repeatCount = repeatCount;
        beforeEachCleanups = await callSuiteHook(
          suite,
          test,
          "beforeEach",
          runner,
          [test.context, suite]
        );
        if (runner.runTask) {
          await runner.runTask(test);
        } else {
          const fn = getFn(test);
          if (!fn) {
            throw new Error(
              "Test function is not found. Did you add it using `setFn`?"
            );
          }
          await fn();
        }
        await ((_d = runner.onAfterTryTask) == null ? void 0 : _d.call(runner, test, {
          retry: retryCount,
          repeats: repeatCount
        }));
        if (test.result.state !== "fail") {
          if (!test.repeats) {
            test.result.state = "pass";
          } else if (test.repeats && retry === retryCount) {
            test.result.state = "pass";
          }
        }
      } catch (e) {
        failTask(test.result, e, runner.config.diffOptions);
      }
      if (((_e = test.result) == null ? undefined : _e.pending) || ((_f = test.result) == null ? undefined : _f.state) === "skip") {
        test.mode = "skip";
        test.result = { state: "skip", note: (_g = test.result) == null ? undefined : _g.note, pending: true };
        updateTask("test-finished", test, runner);
        setCurrentTest(undefined);
        return;
      }
      try {
        await ((_h = runner.onTaskFinished) == null ? void 0 : _h.call(runner, test));
      } catch (e) {
        failTask(test.result, e, runner.config.diffOptions);
      }
      try {
        await callSuiteHook(suite, test, "afterEach", runner, [
          test.context,
          suite
        ]);
        await callCleanupHooks(beforeEachCleanups);
        await callFixtureCleanup(test.context);
      } catch (e) {
        failTask(test.result, e, runner.config.diffOptions);
      }
      await callTestHooks(runner, test, test.onFinished || [], "stack");
      if (test.result.state === "fail") {
        await callTestHooks(
          runner,
          test,
          test.onFailed || [],
          runner.config.sequence.hooks
        );
      }
      test.onFailed = undefined;
      test.onFinished = undefined;
      if (test.result.state === "pass") {
        break;
      }
      if (retryCount < retry) {
        test.result.state = "run";
        test.result.retryCount = (test.result.retryCount ?? 0) + 1;
      }
      updateTask("test-retried", test, runner);
    }
  }
  if (test.fails) {
    if (test.result.state === "pass") {
      const error = processError(new Error("Expect test to fail"));
      test.result.state = "fail";
      test.result.errors = [error];
    } else {
      test.result.state = "pass";
      test.result.errors = undefined;
    }
  }
  setCurrentTest(undefined);
  test.result.duration = now() - start;
  await ((_i = runner.onAfterRunTask) == null ? undefined : _i.call(runner, test));
  updateTask("test-finished", test, runner);
}
function failTask(result, err, diffOptions) {
  if (err instanceof PendingError) {
    result.state = "skip";
    result.note = err.note;
    result.pending = true;
    return;
  }
  result.state = "fail";
  const errors = Array.isArray(err) ? err : [err];
  for (const e of errors) {
    const error = processError(e, diffOptions);
    result.errors ?? (result.errors = []);
    result.errors.push(error);
  }
}
function markTasksAsSkipped(suite, runner) {
  suite.tasks.forEach((t) => {
    t.mode = "skip";
    t.result = { ...t.result, state: "skip" };
    updateTask("test-finished", t, runner);
    if (t.type === "suite") {
      markTasksAsSkipped(t, runner);
    }
  });
}
async function runSuite(suite, runner) {
  var _a, _b, _c, _d;
  await ((_a = runner.onBeforeRunSuite) == null ? undefined : _a.call(runner, suite));
  if (((_b = suite.result) == null ? undefined : _b.state) === "fail") {
    markTasksAsSkipped(suite, runner);
    updateTask("suite-failed-early", suite, runner);
    return;
  }
  const start = now();
  const mode = suite.mode;
  suite.result = {
    state: mode === "skip" || mode === "todo" ? mode : "run",
    startTime: unixNow()
  };
  updateTask("suite-prepare", suite, runner);
  let beforeAllCleanups = [];
  if (suite.mode === "skip") {
    suite.result.state = "skip";
    updateTask("suite-finished", suite, runner);
  } else if (suite.mode === "todo") {
    suite.result.state = "todo";
    updateTask("suite-finished", suite, runner);
  } else {
    try {
      try {
        beforeAllCleanups = await callSuiteHook(
          suite,
          suite,
          "beforeAll",
          runner,
          [suite]
        );
      } catch (e) {
        markTasksAsSkipped(suite, runner);
        throw e;
      }
      if (runner.runSuite) {
        await runner.runSuite(suite);
      } else {
        for (let tasksGroup of partitionSuiteChildren(suite)) {
          if (tasksGroup[0].concurrent === true) {
            await Promise.all(tasksGroup.map((c) => runSuiteChild(c, runner)));
          } else {
            const { sequence } = runner.config;
            if (suite.shuffle) {
              const suites = tasksGroup.filter(
                (group) => group.type === "suite"
              );
              const tests = tasksGroup.filter((group) => group.type === "test");
              const groups = shuffle([suites, tests], sequence.seed);
              tasksGroup = groups.flatMap(
                (group) => shuffle(group, sequence.seed)
              );
            }
            for (const c of tasksGroup) {
              await runSuiteChild(c, runner);
            }
          }
        }
      }
    } catch (e) {
      failTask(suite.result, e, runner.config.diffOptions);
    }
    try {
      await callSuiteHook(suite, suite, "afterAll", runner, [suite]);
      await callCleanupHooks(beforeAllCleanups);
    } catch (e) {
      failTask(suite.result, e, runner.config.diffOptions);
    }
    if (suite.mode === "run" || suite.mode === "queued") {
      if (!runner.config.passWithNoTests && !hasTests(suite)) {
        suite.result.state = "fail";
        if (!((_c = suite.result.errors) == null ? undefined : _c.length)) {
          const error = processError(
            new Error(`No test found in suite ${suite.name}`)
          );
          suite.result.errors = [error];
        }
      } else if (hasFailed(suite)) {
        suite.result.state = "fail";
      } else {
        suite.result.state = "pass";
      }
    }
    suite.result.duration = now() - start;
    updateTask("suite-finished", suite, runner);
    await ((_d = runner.onAfterRunSuite) == null ? undefined : _d.call(runner, suite));
  }
}
let limitMaxConcurrency;
async function runSuiteChild(c, runner) {
  if (c.type === "test") {
    return limitMaxConcurrency(() => runTest(c, runner));
  } else if (c.type === "suite") {
    return runSuite(c, runner);
  }
}
async function runFiles(files, runner) {
  var _a, _b;
  limitMaxConcurrency ?? (limitMaxConcurrency = limitConcurrency(runner.config.maxConcurrency));
  for (const file of files) {
    if (!file.tasks.length && !runner.config.passWithNoTests) {
      if (!((_b = (_a = file.result) == null ? undefined : _a.errors) == null ? undefined : _b.length)) {
        const error = processError(
          new Error(`No test suite found in file ${file.filepath}`)
        );
        file.result = {
          state: "fail",
          errors: [error]
        };
      }
    }
    await runSuite(file, runner);
  }
}
async function startTests(specs, runner) {
  var _a, _b, _c, _d;
  const paths = specs.map((f) => typeof f === "string" ? f : f.filepath);
  await ((_a = runner.onBeforeCollect) == null ? undefined : _a.call(runner, paths));
  const files = await collectTests(specs, runner);
  await ((_b = runner.onCollected) == null ? undefined : _b.call(runner, files));
  await ((_c = runner.onBeforeRunFiles) == null ? undefined : _c.call(runner, files));
  await runFiles(files, runner);
  await ((_d = runner.onAfterRunFiles) == null ? undefined : _d.call(runner, files));
  await sendTasksUpdate(runner);
  return files;
}
async function publicCollect(specs, runner) {
  var _a, _b;
  const paths = specs.map((f) => typeof f === "string" ? f : f.filepath);
  await ((_a = runner.onBeforeCollect) == null ? undefined : _a.call(runner, paths));
  const files = await collectTests(specs, runner);
  await ((_b = runner.onCollected) == null ? undefined : _b.call(runner, files));
  return files;
}

export { afterAll, afterEach, beforeAll, beforeEach, publicCollect as collectTests, createTaskCollector, describe, getCurrentSuite, getCurrentTest, getFn, getHooks, it, onTestFailed, onTestFinished, setFn, setHooks, startTests, suite, test, updateTask };

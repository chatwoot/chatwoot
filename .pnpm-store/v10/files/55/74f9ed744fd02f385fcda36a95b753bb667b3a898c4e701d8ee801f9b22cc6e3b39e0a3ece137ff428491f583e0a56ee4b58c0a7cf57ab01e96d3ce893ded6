import { processError } from '@vitest/utils/error';
import { relative } from 'pathe';
import { toArray } from '@vitest/utils';

function createChainable(keys, fn) {
  function create(context) {
    const chain2 = function(...args) {
      return fn.apply(context, args);
    };
    Object.assign(chain2, fn);
    chain2.withContext = () => chain2.bind(context);
    chain2.setContext = (key, value) => {
      context[key] = value;
    };
    chain2.mergeContext = (ctx) => {
      Object.assign(context, ctx);
    };
    for (const key of keys) {
      Object.defineProperty(chain2, key, {
        get() {
          return create({ ...context, [key]: true });
        }
      });
    }
    return chain2;
  }
  const chain = create({});
  chain.fn = fn;
  return chain;
}

function interpretTaskModes(file, namePattern, testLocations, onlyMode, parentIsOnly, allowOnly) {
  const matchedLocations = [];
  const traverseSuite = (suite, parentIsOnly2, parentMatchedWithLocation) => {
    const suiteIsOnly = parentIsOnly2 || suite.mode === "only";
    suite.tasks.forEach((t) => {
      const includeTask = suiteIsOnly || t.mode === "only";
      if (onlyMode) {
        if (t.type === "suite" && (includeTask || someTasksAreOnly(t))) {
          if (t.mode === "only") {
            checkAllowOnly(t, allowOnly);
            t.mode = "run";
          }
        } else if (t.mode === "run" && !includeTask) {
          t.mode = "skip";
        } else if (t.mode === "only") {
          checkAllowOnly(t, allowOnly);
          t.mode = "run";
        }
      }
      let hasLocationMatch = parentMatchedWithLocation;
      if (testLocations !== undefined && testLocations.length !== 0) {
        if (t.location && (testLocations == null ? undefined : testLocations.includes(t.location.line))) {
          t.mode = "run";
          matchedLocations.push(t.location.line);
          hasLocationMatch = true;
        } else if (parentMatchedWithLocation) {
          t.mode = "run";
        } else if (t.type === "test") {
          t.mode = "skip";
        }
      }
      if (t.type === "test") {
        if (namePattern && !getTaskFullName(t).match(namePattern)) {
          t.mode = "skip";
        }
      } else if (t.type === "suite") {
        if (t.mode === "skip") {
          skipAllTasks(t);
        } else if (t.mode === "todo") {
          todoAllTasks(t);
        } else {
          traverseSuite(t, includeTask, hasLocationMatch);
        }
      }
    });
    if (suite.mode === "run" || suite.mode === "queued") {
      if (suite.tasks.length && suite.tasks.every((i) => i.mode !== "run" && i.mode !== "queued")) {
        suite.mode = "skip";
      }
    }
  };
  traverseSuite(file, parentIsOnly, false);
  const nonMatching = testLocations == null ? undefined : testLocations.filter((loc) => !matchedLocations.includes(loc));
  if (nonMatching && nonMatching.length !== 0) {
    const message = nonMatching.length === 1 ? `line ${nonMatching[0]}` : `lines ${nonMatching.join(", ")}`;
    if (file.result === undefined) {
      file.result = {
        state: "fail",
        errors: []
      };
    }
    if (file.result.errors === undefined) {
      file.result.errors = [];
    }
    file.result.errors.push(
      processError(new Error(`No test found in ${file.name} in ${message}`))
    );
  }
}
function getTaskFullName(task) {
  return `${task.suite ? `${getTaskFullName(task.suite)} ` : ""}${task.name}`;
}
function someTasksAreOnly(suite) {
  return suite.tasks.some(
    (t) => t.mode === "only" || t.type === "suite" && someTasksAreOnly(t)
  );
}
function skipAllTasks(suite) {
  suite.tasks.forEach((t) => {
    if (t.mode === "run" || t.mode === "queued") {
      t.mode = "skip";
      if (t.type === "suite") {
        skipAllTasks(t);
      }
    }
  });
}
function todoAllTasks(suite) {
  suite.tasks.forEach((t) => {
    if (t.mode === "run" || t.mode === "queued") {
      t.mode = "todo";
      if (t.type === "suite") {
        todoAllTasks(t);
      }
    }
  });
}
function checkAllowOnly(task, allowOnly) {
  if (allowOnly) {
    return;
  }
  const error = processError(
    new Error(
      "[Vitest] Unexpected .only modifier. Remove it or pass --allowOnly argument to bypass this error"
    )
  );
  task.result = {
    state: "fail",
    errors: [error]
  };
}
function generateHash(str) {
  let hash = 0;
  if (str.length === 0) {
    return `${hash}`;
  }
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = (hash << 5) - hash + char;
    hash = hash & hash;
  }
  return `${hash}`;
}
function calculateSuiteHash(parent) {
  parent.tasks.forEach((t, idx) => {
    t.id = `${parent.id}_${idx}`;
    if (t.type === "suite") {
      calculateSuiteHash(t);
    }
  });
}
function createFileTask(filepath, root, projectName, pool) {
  const path = relative(root, filepath);
  const file = {
    id: generateFileHash(path, projectName),
    name: path,
    type: "suite",
    mode: "queued",
    filepath,
    tasks: [],
    meta: /* @__PURE__ */ Object.create(null),
    projectName,
    file: undefined,
    pool
  };
  file.file = file;
  return file;
}
function generateFileHash(file, projectName) {
  return generateHash(`${file}${projectName || ""}`);
}

function limitConcurrency(concurrency = Infinity) {
  let count = 0;
  let head;
  let tail;
  const finish = () => {
    count--;
    if (head) {
      head[0]();
      head = head[1];
      tail = head && tail;
    }
  };
  return (func, ...args) => {
    return new Promise((resolve) => {
      if (count++ < concurrency) {
        resolve();
      } else if (tail) {
        tail = tail[1] = [resolve];
      } else {
        head = tail = [resolve];
      }
    }).then(() => {
      return func(...args);
    }).finally(finish);
  };
}

function partitionSuiteChildren(suite) {
  let tasksGroup = [];
  const tasksGroups = [];
  for (const c of suite.tasks) {
    if (tasksGroup.length === 0 || c.concurrent === tasksGroup[0].concurrent) {
      tasksGroup.push(c);
    } else {
      tasksGroups.push(tasksGroup);
      tasksGroup = [c];
    }
  }
  if (tasksGroup.length > 0) {
    tasksGroups.push(tasksGroup);
  }
  return tasksGroups;
}

function isAtomTest(s) {
  return isTestCase(s);
}
function isTestCase(s) {
  return s.type === "test";
}
function getTests(suite) {
  const tests = [];
  const arraySuites = toArray(suite);
  for (const s of arraySuites) {
    if (isTestCase(s)) {
      tests.push(s);
    } else {
      for (const task of s.tasks) {
        if (isTestCase(task)) {
          tests.push(task);
        } else {
          const taskTests = getTests(task);
          for (const test of taskTests) {
            tests.push(test);
          }
        }
      }
    }
  }
  return tests;
}
function getTasks(tasks = []) {
  return toArray(tasks).flatMap(
    (s) => isTestCase(s) ? [s] : [s, ...getTasks(s.tasks)]
  );
}
function getSuites(suite) {
  return toArray(suite).flatMap(
    (s) => s.type === "suite" ? [s, ...getSuites(s.tasks)] : []
  );
}
function hasTests(suite) {
  return toArray(suite).some(
    (s) => s.tasks.some((c) => isTestCase(c) || hasTests(c))
  );
}
function hasFailed(suite) {
  return toArray(suite).some(
    (s) => {
      var _a;
      return ((_a = s.result) == null ? undefined : _a.state) === "fail" || s.type === "suite" && hasFailed(s.tasks);
    }
  );
}
function getNames(task) {
  const names = [task.name];
  let current = task;
  while (current == null ? undefined : current.suite) {
    current = current.suite;
    if (current == null ? undefined : current.name) {
      names.unshift(current.name);
    }
  }
  if (current !== task.file) {
    names.unshift(task.file.name);
  }
  return names;
}
function getFullName(task, separator = " > ") {
  return getNames(task).join(separator);
}
function getTestName(task, separator = " > ") {
  return getNames(task).slice(1).join(separator);
}

export { calculateSuiteHash as a, createFileTask as b, createChainable as c, generateHash as d, getFullName as e, getNames as f, generateFileHash as g, getSuites as h, interpretTaskModes as i, getTasks as j, getTestName as k, limitConcurrency as l, getTests as m, hasFailed as n, hasTests as o, partitionSuiteChildren as p, isAtomTest as q, isTestCase as r, someTasksAreOnly as s };

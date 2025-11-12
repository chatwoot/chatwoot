import { g as getWorkerState } from './utils.C8RiOc4B.js';

const filesCount = /* @__PURE__ */ new Map();
const cache = /* @__PURE__ */ new Map();
function runOnce(fn, key) {
  const filepath = getWorkerState().filepath || "__unknown_files__";
  if (!key) {
    filesCount.set(filepath, (filesCount.get(filepath) || 0) + 1);
    key = String(filesCount.get(filepath));
  }
  const id = `${filepath}:${key}`;
  if (!cache.has(id)) {
    cache.set(id, fn());
  }
  return cache.get(id);
}
function isFirstRun() {
  let firstRun = false;
  runOnce(() => {
    firstRun = true;
  }, "__vitest_first_run__");
  return firstRun;
}
function resetRunOnceCounter() {
  filesCount.clear();
}

export { runOnce as a, isFirstRun as i, resetRunOnceCounter as r };

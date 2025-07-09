'use strict';

const fs = require('node:fs');
const fsPromises = require('node:fs/promises');
const path = require('node:path');
const process = require('node:process');
const constants = require('./constants.cjs');

function _interopDefaultCompat (e) { return e && typeof e === 'object' && 'default' in e ? e.default : e; }

const fs__default = /*#__PURE__*/_interopDefaultCompat(fs);
const fsPromises__default = /*#__PURE__*/_interopDefaultCompat(fsPromises);
const path__default = /*#__PURE__*/_interopDefaultCompat(path);
const process__default = /*#__PURE__*/_interopDefaultCompat(process);

async function detect({ cwd, onUnknown } = {}) {
  for (const directory of lookup(cwd)) {
    for (const lock of Object.keys(constants.LOCKS)) {
      if (await fileExists(path__default.join(directory, lock))) {
        const name = constants.LOCKS[lock];
        const result2 = await parsePackageJson(path__default.join(directory, "package.json"), onUnknown);
        if (result2)
          return result2;
        else
          return { name, agent: name };
      }
    }
    const result = await parsePackageJson(path__default.join(directory, "package.json"), onUnknown);
    if (result)
      return result;
  }
  return null;
}
function* lookup(cwd = process__default.cwd()) {
  let directory = path__default.resolve(cwd);
  const { root } = path__default.parse(directory);
  while (directory && directory !== root) {
    yield directory;
    directory = path__default.dirname(directory);
  }
}
async function parsePackageJson(filepath, onUnknown) {
  if (!filepath || !await fileExists(filepath))
    return null;
  try {
    const pkg = JSON.parse(fs__default.readFileSync(filepath, "utf8"));
    let agent;
    if (typeof pkg.packageManager === "string") {
      const [name, ver] = pkg.packageManager.replace(/^\^/, "").split("@");
      let version = ver;
      if (name === "yarn" && Number.parseInt(ver) > 1) {
        agent = "yarn@berry";
        version = "berry";
        return { name, agent, version };
      } else if (name === "pnpm" && Number.parseInt(ver) < 7) {
        agent = "pnpm@6";
        return { name, agent, version };
      } else if (constants.AGENTS.includes(name)) {
        agent = name;
        return { name, agent, version };
      } else {
        return onUnknown?.(pkg.packageManager) ?? null;
      }
    }
  } catch {
  }
  return null;
}
async function fileExists(filePath) {
  try {
    const stats = await fsPromises__default.stat(filePath);
    if (stats.isFile()) {
      return true;
    }
  } catch {
  }
  return false;
}

exports.detect = detect;

// src/index.ts
import { promises as fs } from "fs";
import { resolve } from "path";
import execa from "execa";
async function pathExists(p) {
  try {
    await fs.access(p);
    return true;
  } catch {
    return false;
  }
}
var cache = new Map();
function hasGlobalInstallation(pm) {
  const key = `has_global_${pm}`;
  if (cache.has(key)) {
    return Promise.resolve(cache.get(key));
  }
  return execa(pm, ["--version"]).then((res) => {
    return /^\d+.\d+.\d+$/.test(res.stdout);
  }).then((value) => {
    cache.set(key, value);
    return value;
  });
}
function getTypeofLockFile(cwd = ".") {
  const key = `lockfile_${cwd}`;
  if (cache.has(key)) {
    return Promise.resolve(cache.get(key));
  }
  return Promise.all([
    pathExists(resolve(cwd, "yarn.lock")),
    pathExists(resolve(cwd, "package-lock.json")),
    pathExists(resolve(cwd, "pnpm-lock.yaml"))
  ]).then(([isYarn, isNpm, isPnpm]) => {
    let value = null;
    if (isYarn) {
      value = "yarn";
    } else if (isPnpm) {
      value = "pnpm";
    } else if (isNpm) {
      value = "npm";
    }
    cache.set(key, value);
    return value;
  });
}
var detect = async ({ cwd } = {}) => {
  const type = await getTypeofLockFile(cwd);
  if (type) {
    return type;
  }
  const [hasYarn, hasPnpm] = await Promise.all([
    hasGlobalInstallation("yarn"),
    hasGlobalInstallation("pnpm")
  ]);
  if (hasYarn) {
    return "yarn";
  }
  if (hasPnpm) {
    return "pnpm";
  }
  return "npm";
};
function getNpmVersion(pm) {
  return execa(pm || "npm", ["--version"]).then((res) => res.stdout);
}
function clearCache() {
  return cache.clear();
}
export {
  clearCache,
  detect,
  getNpmVersion
};

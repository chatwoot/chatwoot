var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __markAsModule = (target) => __defProp(target, "__esModule", { value: true });
var __export = (target, all) => {
  __markAsModule(target);
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __reExport = (target, module2, desc) => {
  if (module2 && typeof module2 === "object" || typeof module2 === "function") {
    for (let key of __getOwnPropNames(module2))
      if (!__hasOwnProp.call(target, key) && key !== "default")
        __defProp(target, key, { get: () => module2[key], enumerable: !(desc = __getOwnPropDesc(module2, key)) || desc.enumerable });
  }
  return target;
};
var __toModule = (module2) => {
  return __reExport(__markAsModule(__defProp(module2 != null ? __create(__getProtoOf(module2)) : {}, "default", module2 && module2.__esModule && "default" in module2 ? { get: () => module2.default, enumerable: true } : { value: module2, enumerable: true })), module2);
};

// src/index.ts
__export(exports, {
  clearCache: () => clearCache,
  detect: () => detect,
  getNpmVersion: () => getNpmVersion
});
var import_fs = __toModule(require("fs"));
var import_path = __toModule(require("path"));
var import_execa = __toModule(require("execa"));
async function pathExists(p) {
  try {
    await import_fs.promises.access(p);
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
  return (0, import_execa.default)(pm, ["--version"]).then((res) => {
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
    pathExists((0, import_path.resolve)(cwd, "yarn.lock")),
    pathExists((0, import_path.resolve)(cwd, "package-lock.json")),
    pathExists((0, import_path.resolve)(cwd, "pnpm-lock.yaml"))
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
  return (0, import_execa.default)(pm || "npm", ["--version"]).then((res) => res.stdout);
}
function clearCache() {
  return cache.clear();
}
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {
  clearCache,
  detect,
  getNpmVersion
});

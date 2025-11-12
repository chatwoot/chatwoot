import fs from 'node:fs';
import fsPromises from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { LOCKS, AGENTS } from './constants.mjs';

async function detect({ cwd, onUnknown } = {}) {
  for (const directory of lookup(cwd)) {
    for (const lock of Object.keys(LOCKS)) {
      if (await fileExists(path.join(directory, lock))) {
        const name = LOCKS[lock];
        const result2 = await parsePackageJson(path.join(directory, "package.json"), onUnknown);
        if (result2)
          return result2;
        else
          return { name, agent: name };
      }
    }
    const result = await parsePackageJson(path.join(directory, "package.json"), onUnknown);
    if (result)
      return result;
  }
  return null;
}
function* lookup(cwd = process.cwd()) {
  let directory = path.resolve(cwd);
  const { root } = path.parse(directory);
  while (directory && directory !== root) {
    yield directory;
    directory = path.dirname(directory);
  }
}
async function parsePackageJson(filepath, onUnknown) {
  if (!filepath || !await fileExists(filepath))
    return null;
  try {
    const pkg = JSON.parse(fs.readFileSync(filepath, "utf8"));
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
      } else if (AGENTS.includes(name)) {
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
    const stats = await fsPromises.stat(filePath);
    if (stats.isFile()) {
      return true;
    }
  } catch {
  }
  return false;
}

export { detect };

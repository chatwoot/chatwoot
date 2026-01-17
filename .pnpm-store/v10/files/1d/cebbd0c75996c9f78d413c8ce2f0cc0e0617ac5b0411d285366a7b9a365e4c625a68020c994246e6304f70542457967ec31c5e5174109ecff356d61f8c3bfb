import fs from 'node:fs';
import { builtinModules } from 'node:module';
import { d as dirname, j as join, b as basename, r as resolve, e as extname } from './chunk-pathe.UZ-hd4nF.js';

const { existsSync, readdirSync, statSync } = fs;
function findMockRedirect(root, mockPath, external) {
  const path = external || mockPath;
  if (external || isNodeBuiltin(mockPath) || !existsSync(mockPath)) {
    let findFile2 = function(mockFolder2, baseOriginal2) {
      const files = readdirSync(mockFolder2);
      for (const file of files) {
        const baseFile = basename(file, extname(file));
        if (baseFile === baseOriginal2) {
          const path2 = resolve(mockFolder2, file);
          if (statSync(path2).isFile()) {
            return path2;
          } else {
            const indexFile = findFile2(path2, "index");
            if (indexFile) {
              return indexFile;
            }
          }
        }
      }
      return null;
    };
    const mockDirname = dirname(path);
    const mockFolder = join(root, "__mocks__", mockDirname);
    if (!existsSync(mockFolder)) {
      return null;
    }
    const baseOriginal = basename(path);
    return findFile2(mockFolder, baseOriginal);
  }
  const dir = dirname(path);
  const baseId = basename(path);
  const fullPath = resolve(dir, "__mocks__", baseId);
  return existsSync(fullPath) ? fullPath : null;
}
const builtins = /* @__PURE__ */ new Set([
  ...builtinModules,
  "assert/strict",
  "diagnostics_channel",
  "dns/promises",
  "fs/promises",
  "path/posix",
  "path/win32",
  "readline/promises",
  "stream/consumers",
  "stream/promises",
  "stream/web",
  "timers/promises",
  "util/types",
  "wasi"
]);
const prefixedBuiltins = /* @__PURE__ */ new Set(["node:test", "node:sqlite"]);
const NODE_BUILTIN_NAMESPACE = "node:";
function isNodeBuiltin(id) {
  if (prefixedBuiltins.has(id)) {
    return true;
  }
  return builtins.has(
    id.startsWith(NODE_BUILTIN_NAMESPACE) ? id.slice(NODE_BUILTIN_NAMESPACE.length) : id
  );
}

export { findMockRedirect };
